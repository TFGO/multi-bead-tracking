clear all;
warning('off','all'); %turn off all warnings
analysis_time=datestr(now,'yymmddHHMMSS');

%% select file
[file,path] = uigetfile('*.tif');
if isequal(file,0)
   disp('User selected Cancel');
else
   disp(['User selected ', fullfile(path,file)]);
end

%% input the start and end frame of the selected file
prompt = {'Enter start frame number:','Enter end frame number:'};
title = 'ROI';
dims = [1 35];
definput = {'1','end'};
input = inputdlg(prompt,title,dims,definput);

frame_start=str2num(input{1});
frame_end=str2num(input{2});
frame_num=frame_end-frame_start+1;

%% select the start point (click the center of tracked bead and press 'Enter')
file_marker=strcat(file(1:end-4),'_',analysis_time,'_marker.tif');
image=imread(strcat(path,file),str2num(input{1}));
figure
imshow(image);
[xi,yi] = getpts;
bead_num=length(xi);
close all;

%% calculate and record frame by frame, bead by bead
excelName=strcat(path,file(1:end-4),'_',analysis_time,'.xlsx');

%show progress
h = waitbar(0,sprintf('Initializing...'),'Name','Multi-bead Tracking Status'); 

for num=1:bead_num
    xlswrite(excelName,{path},num,'A1');
    xlswrite(excelName,{strcat(file(1:end-4),'_crop_',analysis_time,'_',num2str(num),'.tif')},num,'A2');
    xlswrite(excelName,{'frame Index'},num,'B1');
    xlswrite(excelName,{'x_center'},num,'C1');
    xlswrite(excelName,{'y_center'},num,'D1');
    xlswrite(excelName,{'sigma'},num,'E1');
    xlswrite(excelName,{'radius (pixels)'},num,'F1');
    xlswrite(excelName,{'z (pixels)'},num,'G1');
    xlswrite(excelName,{'disp_x (pixels)'},num,'H1');
    xlswrite(excelName,{'disp_y (pixels)'},num,'I1');
    xlswrite(excelName,{'disp_z (pixels)'},num,'J1');
    xlswrite(excelName,{'disp_xy (pixels)'},num,'K1');
    xlswrite(excelName,{'disp_xyz (pixels)'},num,'L1');
end

%% initialize all parameters
xc=zeros(frame_num,bead_num);
yc=zeros(frame_num,bead_num);
sigma=zeros(frame_num,bead_num);
radius=zeros(frame_num,bead_num);
z=zeros(frame_num,bead_num);

%% calculate and record bead by bead, frame by frame
for f=1:frame_num
    %show progress
    perc = ceil(100*f/frame_num);
    waitbar(perc/100,h,sprintf('Analyzing: frame #%d...%d%%',f,perc));
    
    image_f=imread(strcat(path,file),f+frame_start-1);
    for num=1:bead_num
        img_crop=imcrop(image_f,[xi(num)-30,yi(num)-30,60,60]);
        img_crop_norm=img_crop-min(img_crop(:));
        img_crop_norm=double(img_crop_norm)/double(max(img_crop_norm(:)));
        [xcenter, ycenter, sigma_i] = radialcenter(img_crop_norm);
        [radius_i,intensity]=radius_finder(img_crop,xcenter,ycenter);%,insertBefore(file,".tif",strcat('_',num2str(frame))));
        xi(num)=xcenter+xi(num)-30;
        yi(num)=ycenter+yi(num)-30;
        xc(f,num)=xi(num);
        yc(f,num)=yi(num);
        sigma(f,num)=sigma_i;
        radius(f,num)=radius_i;
        z(f,num)=radius_i*13.77327;
    end
    %label the frame and save it
    image_f = insertMarker(image_f,[xc(f,:)' yc(f,:)'],'plus','color','red','size',30);
    image_f = insertShape(image_f,'circle',[xc(f,:)' yc(f,:)' radius(f,:)'],'LineWidth',2,'Color','red');
    image_f = insertText(image_f,[xc(f,:)' yc(f,:)'-60],1:1:num,'AnchorPoint','CenterTop','FontSize',18);
    imwrite(image_f,strcat(path,file_marker),'WriteMode','append');
end
close(h);%close the waitbar

%% write results into excel
%show progress
h = waitbar(0,sprintf('Writing results into excel...'),'Name','Multi-bead Tracking Status'); 
for num=1:bead_num
    %show progress
    perc = ceil(100*num/bead_num);
    waitbar(perc/100,h,sprintf('Writing results into excel: bead #%d...%d%%',num,perc));
    xlswrite(excelName,[frame_start:1:frame_end]',num,'B2');
    xlswrite(excelName,xc(:,num),num,'C2');
    xlswrite(excelName,yc(:,num),num,'D2');
    xlswrite(excelName,sigma(:,num),num,'E2');
    xlswrite(excelName,radius(:,num),num,'F2');
    xlswrite(excelName,z(:,num),num,'G2');
    xlswrite(excelName,xc(:,num)-xc(1,num),num,'H2');
    xlswrite(excelName,yc(:,num)-yc(1,num),num,'I2');
    xlswrite(excelName,z(:,num)-z(1,num),num,'J2');
    xlswrite(excelName,sqrt((xc(:,num)-xc(1,num)).^2+(yc(:,num)-yc(1,num)).^2),num,'K2');
    xlswrite(excelName,sqrt((xc(:,num)-xc(1,num)).^2+(yc(:,num)-yc(1,num)).^2+(z(:,num)-z(1,num)).^2),num,'L2');
    
end

close(h);%close the waitbar
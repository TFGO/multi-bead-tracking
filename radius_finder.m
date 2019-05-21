% image=imread('sample_crop_190510161951_3.tif');
function [radius,intensity]=radius_finder(image,xc,yc)
%swap xc and yc
[yc,xc]=deal(xc,yc);

[r, c] = ndgrid(1:size(image, 1), 1:size(image, 2));

distance=sqrt((r-xc).^2+(c-yc).^2);

dist_max=ceil(max(distance(:)));

intensity=zeros(1,dist_max);

for dist_i=1:dist_max
    intensity(dist_i)=mean(mean(image(distance>dist_i-1&distance<dist_i)));
end

%find the radius of the first order of diffraction ring
%use 7th order polynomial fitting
distance=1:1:dist_max;
fitpoly7=fit(distance',intensity','poly7');
distance_cent=1:0.01:dist_max;
intensity_cent=fitpoly7(distance_cent);
delta=5;
[maxtab, mintab]=peakdet(intensity_cent, delta,distance_cent);

if (isempty(maxtab))||(isempty(mintab))||(size(find(maxtab(:,1)>mintab(1,1),1,'first'),1)==0)%if maxtab is empty,min is empty and can't find the first_order ring
    radius=0; %the location of the first peak is right after the first local minimum
else
    radius=maxtab(find(maxtab(:,1)>mintab(1,1),1,'first'),1);
end
end
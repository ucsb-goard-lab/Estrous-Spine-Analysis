function [] = C_cropRegisteredDendrites(png_path,newdir_name)
%% Crop registered dendrites
%-------------------------------------------------------------------------%
%   This function finds the maximum crop on any dendrite and applies it to
%   all dendrites.
%
%   Written by NSW 06/21/2023 Last updated by NSW 02/05/2025
%-------------------------------------------------------------------------%
if nargin < 1 || isempty (png_path)
    png_path = pwd; % folder that PNGs to register are in, defaults to current working directory
end
if nargin < 2 || isempty(newdir_name)
    newdir_name = 'cropped';
end

%% Add path to natural sorting file system
addpath(genpath('E:\Code\Spine-Analysis-Pipeline-main_Mounami'))

%% Get maximum crop on all sides
ims = dir(fullfile(png_path,'*.png'));
ims = natsortfiles(ims);
right = zeros(1,length(ims));
left = zeros(1,length(ims));
top = zeros(1,length(ims));
bottom = zeros(1,length(ims));
for ii = 1:length(ims)
    im = imread(ims(ii).name);
    top_col = im(1:length(im)/2, length(im)/2);
    bottom_col = im(length(im)/2:length(im), length(im)/2);
    left_row = im(length(im)/2, 1:length(im)/2);
    right_row = im(length(im)/2, length(im)/2:length(im));
    
    top(ii) = length(find(~top_col));
    bottom(ii) = length(find(~bottom_col));
    right(ii) = length(find(~left_row));
    left(ii) = length(find(~right_row));
end
max_top = max(top);
max_bottom = max(bottom);
max_right = max(right);
max_left = max(left);

%% Apply to all images then save to new directory
mkdir(newdir_name)
for i = 1:length(ims)
    imname = ims(i).name;
    im = imread(imname);
    im(1:max_top,:) = 0;
    im(end-max_bottom:end,:) = 0;
    im(:,1:max_left) = 0;
    im(:,end-max_right:end) = 0;
    newname = strcat(png_path,'\',newdir_name,'\',imname(1:end-4),'_',newdir_name,'.png');
    imwrite(im,newname)
end
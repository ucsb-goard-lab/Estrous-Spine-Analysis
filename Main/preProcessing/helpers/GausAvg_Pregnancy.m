function [gaus_im] = GausAvg_Pregnancy(plot_flag,save_flag,register_flag,...
    brighten_factor,newname,imsize,raw_ims)
%% Pre-processing pipeline for cross sectional spine analysis
%-------------------------------------------------------------------------%
%   This function concatenates the planes of a z-stack image and averages
%   them on a low pass filtered gaussian, then crops, scales, and brightens
%   the image for ideal input into the crossSectionalSpineAnalysis
%   pipeline.
%
%   Starting directory should have 3-4 different 'plane' folders.
%
%   Written by NSW 03/24/24, Last updated by NSW 09/30/24
%-------------------------------------------------------------------------%
if nargin < 1 || isempty(plot_flag)
    plot_flag = 1; % defaults to true
end
if nargin < 2 || isempty(save_flag)
    save_flag = 1; % true = save image
end
if nargin < 3 || isempty(register_flag)
    register_flag = 1;
end
if nargin < 3 || isempty(brighten_factor)
    brighten_factor = 1.2; % how much to brighten the image by
end
if nargin < 4 || isempty(newname)
    newname = "gaus_mean_projection.png";
end
if nargin < 5 || isempty(imsize)
    imsize = 760; % size of the image in pixels
end
if nargin < 6 || isempty(raw_ims)
    pnames = dir('plane*');
    raw_ims = zeros(imsize,imsize,length(pnames)); % 3D array of images
    for p = 1:length(pnames)
        cd(pnames(p).name) % move to current plane
        fname = dir('*registered_data.mat'); % find registered data file
        data = importdata(fname.name);
        raw_ims(:,:,p) = data.avg_projection;
        cd ..
    end
end

%% Weight images along a normal distribution
num_planes = size(raw_ims, 3);

x = -3:0.1:3;
y = normpdf(x,0,1);
intervals = length(y)/(num_planes+1);
weighted_ims = zeros(size(raw_ims)); % preallocate weighted image array
for pp = 1:num_planes
    curr_im = raw_ims(:,:,pp);
    weight = y(1,round(intervals*pp)); % increase for higher threshold
    weighted_ims(:,:,pp) = weight*curr_im;
end

%% Register between planes
% Register with regular-step gradient descent
if register_flag
    fixed_idx = 2;
    moving_idx = [1,3,4];
    fixed = weighted_ims(:,:,fixed_idx);
    optimizer = registration.optimizer.RegularStepGradientDescent;
    metric = registration.metric.MeanSquares;

    registered_ims = zeros(size(weighted_ims));
    registered_ims(:,:,fixed_idx) = fixed; % add fixed plane
    for i = 1:length(moving_idx)
        moving = weighted_ims(:,:,moving_idx(i));
        movingRegistered = imregister(moving,fixed,"rigid",optimizer,metric);
        registered_ims(:,:,moving_idx(i)) = movingRegistered;
    end
else
    registered_ims = weighted_ims;
end

%% Plot gaussian averaged image
if plot_flag
    figure
    registered_uint8 = uint8(registered_ims);
    montage(registered_uint8)

    prompt = 'Which planes would you like to omit? Enter 0 if none:';
    dlgtitle = 'Input';
    fieldsize = [1 45];
    definput = {'0'};
    answer = str2num(cell2mat(inputdlg(prompt,dlgtitle,fieldsize,definput)));

    if answer
        registered_ims(:,:,answer) = [];
    end
end

%% Average and brighten
gaus_mean_projection = mean(registered_ims,3); % average planes
brightened_gaus = 255*brighten_factor*(gaus_mean_projection - min(gaus_mean_projection(:))) ./ (max(gaus_mean_projection(:)) - min(gaus_mean_projection(:))); %scale values between 0 and 255
gaus_im = cast(brightened_gaus,'uint8'); % convert to image

if plot_flag
    imshow(gaus_im)
end

%% Save to current directory
if save_flag
    imwrite(gaus_im,newname)
end
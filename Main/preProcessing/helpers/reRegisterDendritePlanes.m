function [registered_ims] = reRegisterDendritePlanes(fixed_idx)
%% Re-register single dendrite
%-------------------------------------------------------------------------%
%   Run from directory containing dendrite planes if initial registration
%   does not perform correctly. The new image will overwrite the previous
%   image in the current directory.
%
%   Written by NSW 02/06/25
%-------------------------------------------------------------------------%
if nargin < 1 || isempty(fixed_idx)
    fixed_idx = 2; % default registers to second plane
end

%% Set parameters
imsize = 760;
optimizer = registration.optimizer.RegularStepGradientDescent;
metric = registration.metric.MeanSquares;

planefolders = dir('plane*');

%% Generate image stack
imagestack = zeros(imsize, imsize, length(planefolders)); % set up array to hold dendrite images
for pp = 1:length(planefolders)
    cd(planefolders(pp).name)
    dname = dir('*.mat');
    imdata = importdata(dname.name);
    im = imdata.avg_projection;
    imagestack(:,:,pp) = im;
    cd ..
end

%% Register with regular-step gradient descent
fixed = imagestack(:,:,fixed_idx); % defaults to registering to 1st plane
newname = strcat(dname.name(1:end-9),'.png');
disp(['Registering image',' ',newname,'...'])
registered_ims = zeros(size(imagestack));
registered_ims(:,:,fixed_idx) = fixed; % set fixed image
idx_vec = 1:length(planefolders); % get indices of non-fixed images
idx_vec(fixed_idx) = [];
for r = 1:length(idx_vec)
    curr_idx = idx_vec(r); % index without the fixed image
    moving = imagestack(:,:,curr_idx);
    movingRegistered = imregister(moving,fixed,"rigid",optimizer, metric);
    registered_ims(:,:,curr_idx) = movingRegistered;
end

%% Gaussian average registered planes and save
GausAvg_Pregnancy(0,1,0,1,newname,imsize,registered_ims); % (plot_flag,save_flag,register_flag,brighten_factor,newname,imsize,raw_ims)

function [] = D_normalizeLuminanceDendrites(pathname,imsize)
%% Normalize luminance between dendrite images
%-------------------------------------------------------------------------%
%   Run from directory containing dendrite png's. This will create a new
%   directory and save the normalized images there.
%
%   Written by NSW 02/11/25
%-------------------------------------------------------------------------%
if nargin < 1 || isempty(pathname)
    pathname = 'normalized'; % name of new directory
end
if nargin < 2 || isempty(imsize)
    imsize = 760; % default size of images
end

registered_imnames = dir('*.png');
registered_imnames = natsortfiles(registered_imnames); % alphanumerically sort filenames

%% get average luminance of every image
luminance = zeros(1,length(registered_imnames));
for ii = 1:length(registered_imnames)
    curr_im = imread(registered_imnames(ii).name);
    if size(curr_im,3) == 3 % if rgb
        grey_im = rgb2gray(curr_im);
    else
        grey_im = curr_im;
    end
    luminance(1,ii) = mean(mean(grey_im));
end

%% increase luminance of every image to max luminance across all images
normalized_ims = zeros(imsize,imsize,length(registered_imnames));
max_lum = max(luminance);
basedir = pwd;
mkdir(pathname)
for ii = 1:length(registered_imnames)
    curr_im = imread(registered_imnames(ii).name);
    curr_lum = luminance(ii);
    if size(curr_im,3) == 3 % if rgb
        grey_im = rgb2gray(curr_im);
    else
        grey_im = curr_im;
    end
    lum_diff = max_lum - curr_lum;
    bright_im = grey_im + lum_diff;
    imwrite(bright_im,[basedir,'\',pathname,'\',registered_imnames(ii).name]) % write to current directory
    normalized_ims(:,:,ii) = bright_im;
end

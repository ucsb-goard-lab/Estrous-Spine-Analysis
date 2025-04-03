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

%% Get average luminance of every image
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

%% Increase luminance of every image to max luminance across all images (Multiplicative)
normalized_ims = zeros(imsize, imsize, length(registered_imnames));
max_lum = max(luminance); % Get the maximum luminance value
basedir = pwd;
mkdir(pathname)

for ii = 1:length(registered_imnames)
    curr_im = imread(registered_imnames(ii).name);
    curr_lum = luminance(ii);
    
    if size(curr_im,3) == 3 % Convert RGB to grayscale if needed
        grey_im = rgb2gray(curr_im);
    else
        grey_im = curr_im;
    end
    
    % Compute the scaling factor
    scale_factor = max_lum / curr_lum;
    
    % Apply multiplicative scaling
    bright_im = double(grey_im) * scale_factor; 
    
    % Clip values to avoid overflow
    bright_im(bright_im > 255) = 255; 
    bright_im = uint8(bright_im); % Convert back to uint8
    
    % Save the adjusted image
    imwrite(bright_im, [basedir, '\', pathname, '\', registered_imnames(ii).name]) 
    
    % Store in array
    normalized_ims(:,:,ii) = bright_im;
end
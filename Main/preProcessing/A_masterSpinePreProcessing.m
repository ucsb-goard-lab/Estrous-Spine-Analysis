%% Master spine pre-processing script
%-------------------------------------------------------------------------%
%   Creates folders for different imaging planes, and sorts single page
%   tifs into their respective folders, then puts images from all planes
%   into the tif convert/process time series pipeline.
%
%   Once you have an average projection for each plane, register across
%   planes and get a gaussian-averaged png for 16X dendrite recordings.
%
%   Should be run from the mouse folder containing a series of recordings,
%   i.e. 'NSW110'. 
%
%   Written by NSW 09/27/2024
%-------------------------------------------------------------------------%

% Sort images with multiple planes into their respective planes
batchSortImages();

% Convert all unprocessed images
batchTifConvert_APTS_Dendrites();

% Register all planes and save gaussian-averaged image
[im] = batchRegisterDendritePlanes(); % input which plane to register to (defaults to 1)
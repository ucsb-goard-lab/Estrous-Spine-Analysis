function [registered_ims] = batchRegisterDendritePlanes(fixed_idx)
%% Batch register dendrites
%-------------------------------------------------------------------------%
%   This function batch registers a series of dendrite images at 16X
%   according to the default settings in rigid regular-step gradient
%   descent image registration using mean squares as a metric.
%
%   Fixed image is typically the first in the series, but the user has the
%   option to select a different fixed image if the first is offset.
%
%   Written by NSW 06/21/2023  Last updated by NSW 09/30/2024
%-------------------------------------------------------------------------%
if nargin < 1 || isempty(fixed_idx)
    fixed_idx = 1; % default registers to first plane
end

% set parameters
imsize = 760;
optimizer = registration.optimizer.RegularStepGradientDescent;
metric = registration.metric.MeanSquares;

% get recording folders
mainfolders = dir('*NSW*');

for f = 1:length(mainfolders)
    curr_fol = [mainfolders(f).folder, '\', mainfolders(f).name];
    cd(curr_fol)

    % get TSeries folder names
    subfolders = dir('TSeries*'); %% for spines: dir('**/*.*');

    for i = 1:length(subfolders)
        folder_name = subfolders(i).name;
        folder_path = strcat(subfolders(i).folder,'\',folder_name,'\');
        dir_check = subfolders(i).isdir;
        if dir_check
            cd(folder_path)
            planefolders = dir('plane*');
            reg_im = dir('*registered.png');
            if isempty(planefolders)
                cd ..
                continue; % if no planes, skip
            elseif ~isempty(reg_im)
                cd ..
                continue; % if already registered, skip
            end
            
            imagestack = zeros(imsize, imsize, length(planefolders)); % set up array to hold dendrite images
            for pp = 1:length(planefolders)
                cd(planefolders(pp).name)
                dname = dir('*.mat');
                imdata = importdata(dname.name);
                im = imdata.avg_projection;
                imagestack(:,:,pp) = im;
                cd ..
            end

            % figure
            % montage(imagestack)
            % prompt = "Which recording would you like to register to? ";
            % fixed_idx = input(prompt);

            %% Register with regular-step gradient descent
            fixed = imagestack(:,:,fixed_idx); % defaults to registering to 1st plane
            newname = strcat(dname.name(1:end-9),'.png');
            disp(['Registering image',' ',newname,'...'])
            registered_ims = zeros(size(imagestack));
            registered_ims(:,:,1) = fixed; % set first registered image as fixed image
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
        end
        cd ..
    end
    cd ..
end
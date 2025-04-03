function [] = getAllSpines(gui_flag)
%% Get All Spines
%-------------------------------------------------------------------------%
%   This function uses previously written software to binarize all
%   registered and cropped dendrite images, then detect all spines in the
%   sequence of images, and determine the cumulative population of spines
%   across the timecourse. Boundary boxes whose centroids are > X pixels
%   apart are considered to be separate spines. Then, two 4D matrices
%   (spine width x spine height x num days x num spines) are generated
%   containing the whole population of spines for 1. gaussian averaged
%   images, 2. superresolution images, and 3. binarized images. 
% 
%   The function then calls the spine detection GUI, which asks you to go
%   through all spines and approve their classification as "spine" or "no
%   spine" to catch outlier cases.
%
%   Written by NSW 10/18/2023 // Last updated by NSW 12/27/2023
%-------------------------------------------------------------------------%
if nargin < 1 || isempty(gui_flag)
    gui_flag = 0; % defaults to not run gui
end


filepath = mfilename('fullpath');
addpath(genpath(filepath(1:end-12))) % add all subfunctions to path (works if function is not renamed)
pixel_thresh = 25; % how close in pixels centroids have to be to be considered the same spine (25 ~= 1.7uM)
spine_im_length = 80; % size of binarized single spine images in pixels
disp('Select cycle data')
[cname,cpath] = uigetfile('*.mat');
cycle_data = importdata(strcat(cpath,cname));
ims = dir('*.png');
ims = natsortfiles({ims.name}); % alphanumerically sort by filename
% If loading in previous data, comment out this section
bname = 'binarized';
mkdir(bname)
dname = 'data';
mkdir(dname)
base = pwd;
all_spine_data = cell(length(ims),1); % make array to store all spine data
first_im = imread(ims{1});
avg_ims = zeros(size(first_im,1),size(first_im,2),length(ims)); % initiate 3d array of all averaged and binary images
binary_ims = zeros(size(first_im,1),size(first_im,2),length(ims));
superResolution_ims = zeros(size(first_im,1),size(first_im,2),length(ims));
for ii = 1:length(ims)
    % disp(['Current stage:', ' ', cycle_data{ii}])
    imname = ims{ii};
    curr_im = imread(imname);
    binary_dir = strcat(base,'\',bname);
    datadir = strcat(base,'\',dname);
    [spine_data,binary,superResolution] = analyzeDendrite_NSWEdit(imname,curr_im,1, binary_dir,[],...
        length(curr_im), 0, 0, 0, 0, datadir); % binarize image and collect spine data
    all_spine_data{ii} = spine_data;
    avg_ims(:,:,ii) = curr_im; % store images in array
    binary_ims(:,:,ii) = binary;
    superResolution_ims(:,:,ii) = superResolution;
    close all
end

%% Uncomment if you are loading in previous data
% first_im = imread(ims{1});
% avg_ims = zeros(size(first_im,1),size(first_im,2),length(ims));
% for ii = 1:length(ims)
%     curr_im = imread(ims{ii});
%     double_im = im2double(curr_im);
%     avg_ims(:,:,ii) = double_im;
% end
% cd binarized\
% bin_ims = dir('*.png');
% bin_ims = natsortfiles(bin_ims); 
% binary_ims = zeros(size(first_im,1),size(first_im,2),length(bin_ims));
% for bb = 1:length(bin_ims)
%     curr_bin_im = imread(bin_ims(bb).name);
%     double_bin_im = im2double(curr_bin_im);
%     binary_ims(:,:,bb) = double_bin_im;
% end
% cd superresolution\
% sup_ims = dir('*.png');
% sup_ims = natsortfiles(sup_ims); 
% superResolution_ims = zeros(size(first_im,1),size(first_im,2),length(sup_ims));
% for ss = 1:length(sup_ims)
%     curr_sup_im = imread(sup_ims(ss).name);
%     double_sup_im = im2double(curr_sup_im);
%     superResolution_ims(:,:,ss) = double_sup_im;
% end
% cd .., cd ..
% cd data\
% data = dir('*.mat');
% data = natsortfiles(data); 
% all_spine_data = cell(length(ims),1);
% for dd = 1:length(ims)
%     curr_data = importdata(data(dd).name);
%     all_spine_data{dd} = curr_data;
% end
% cd ..

%% Go through all spines and find centroids that are different enough to 
% qualify as distinct spines
% put all centroids in one big array
centroid_col = 15; % column containing centroids
cellsz = sum(cell2mat(cellfun(@length,all_spine_data,'uni',false)));
all_centers = zeros(cellsz,2);
count = 1;
for ss = 1:length(all_spine_data)
    curr_centroids = all_spine_data{ss}(:,centroid_col);
    sizes = cell2mat(cellfun(@length,curr_centroids,'uni',false));
    if all(sizes == sizes(1)) % if all cells are the same length (only one object)
        curr_centroids = cell2mat(curr_centroids);
    else
        too_long = find(sizes ~= sizes(1));
        for tt = 1:length(too_long)
            long_centroid = curr_centroids{too_long(tt)};
            curr_centroids{too_long(tt)} = long_centroid(1:2);
        end
        curr_centroids = cell2mat(curr_centroids);
    end
    all_centers(count:count+size(curr_centroids,1)-1,:) = curr_centroids;
    count = count + size(curr_centroids,1);
end

% find distinct coordinates, i.e. coordinates that are all greater than 25
% pixels (~1.7 microns) apart
new_centers = all_centers;
for dd = 1:length(all_centers)
    curr_center = new_centers(dd,:);
    other_centers = new_centers;
    other_centers(dd,:) = [0,0]; % remove current center from list of centers
    too_close = rangesearch(curr_center,other_centers,pixel_thresh);
    too_close_idx = find(~cellfun(@isempty,too_close));
    new_centers(too_close_idx,:) = [];
    if dd >= length(new_centers) % once loop reaches the end of the edited list
        break
    end
end

%% Cut out an x pixel x x pixel chunk using the distinct centroids out of 
% every binary and gaussian averaged image, and get the classification of
% "spine" vs "no spine" for each image
avg_spines = zeros(spine_im_length*2,spine_im_length*2,length(ims),length(new_centers)); % dims (doubled spine width x doubled spine height x num days x num spines)
binary_spines = zeros(spine_im_length*2,spine_im_length*2,length(ims),length(new_centers));
superResolution_spines = zeros(spine_im_length*2,spine_im_length*2,length(ims),length(new_centers));
classifications = cell(length(ims),length(new_centers));
select_spine_data = cell(size(classifications));
for cc = 1:length(ims)
    curr_avg_im = avg_ims(:,:,cc);
    curr_binary_im = binary_ims(:,:,cc);
    curr_superResolution_im = superResolution_ims(:,:,cc);
    curr_centroids = all_spine_data{cc}(:,centroid_col);
    sizes = cell2mat(cellfun(@length,curr_centroids,'uni',false));
    if all(sizes == sizes(1)) % if all cells are the same length (only one object)
        curr_centroids = cell2mat(curr_centroids);
    else
        too_long = find(sizes ~= sizes(1));
        for tt = 1:length(too_long)
            long_centroid = curr_centroids{too_long(tt)};
            curr_centroids{too_long(tt)} = long_centroid(1:2);
        end
        curr_centroids = cell2mat(curr_centroids);
    end
    for c = 1:length(new_centers)
        curr_center = new_centers(c,:);
        min_row = round(curr_center(2)-(spine_im_length*2)/2);
        if min_row < 1
            min_row = 1; % correct for out of bounds
        end
        max_row = round(curr_center(2)+(spine_im_length*2)/2)-1;
        if max_row > size(curr_avg_im,1)
            max_row = size(curr_avg_im,1);
        end
        min_col = round(curr_center(1)-(spine_im_length*2)/2);
        if min_col < 1
            min_col = 1;
        end
        max_col = round(curr_center(1)+(spine_im_length*2)/2)-1;
        if max_col > size(curr_avg_im,1)
            max_col = size(curr_avg_im,1);
        end
        curr_avg_spine = curr_avg_im(min_row:max_row,min_col:max_col); % cut out square spine image
        curr_binary_spine = curr_binary_im(min_row:max_row,min_col:max_col);
        curr_superResolution_spine = curr_superResolution_im(min_row:max_row,min_col:max_col);
        if any(size(curr_avg_spine) ~= [spine_im_length*2, spine_im_length*2]) % if borders were adjusted to stay in frame
            new_avg = zeros(spine_im_length*2,spine_im_length*2);
            new_binary = zeros(spine_im_length*2,spine_im_length*2);
            new_superResolution = zeros(spine_im_length*2,spine_im_length*2);
            new_avg(1:size(curr_avg_spine,1),1:size(curr_avg_spine,2)) = curr_avg_spine; % orient in a black box
            new_binary(1:size(curr_binary_spine,1),1:size(curr_binary_spine,2)) = curr_binary_spine;
            new_superResolution(1:size(curr_superResolution_spine,1),...
                1:size(curr_superResolution_spine,2)) = curr_superResolution_spine;
            curr_avg_spine = new_avg;
            curr_binary_spine = new_binary;
            curr_superResolution_spine = new_superResolution;
        end

        avg_spines(:,:,cc,c) = curr_avg_spine;
        binary_spines(:,:,cc,c) = curr_binary_spine;
        superResolution_spines(:,:,cc,c) = curr_superResolution_spine;

        close_enough = rangesearch(curr_center,curr_centroids,pixel_thresh);
        close_enough_idx = find(~cellfun(@isempty,close_enough));
        if ~isempty(close_enough_idx)
            classifications{cc,c} = 'Spine';
            curr_sd = all_spine_data{cc}(close_enough_idx,:);
            select_spine_data{cc,c} = curr_sd(:,1:13); % cut off full images for storage
        else
            classifications{cc,c} = 'No Spine';
        end
    end
end

%% Register binary and average spines
avg_registered = zeros(size(avg_spines));
binary_registered = zeros(size(binary_spines));
superResolution_registered = zeros(size(superResolution_spines));
disp('Performing local registration...')
for rr = 1:length(new_centers) % for each spine
    avg_timeseries = avg_spines(:,:,:,rr);
    binary_timeseries = binary_spines(:,:,:,rr);
    superResolution_timeseries = superResolution_spines(:,:,:,rr);
    fixed = avg_timeseries(:,:,1); % defaults fixed to first recording (change later?)

    %% Register with regular-step gradient descent
    optimizer = registration.optimizer.RegularStepGradientDescent;
    metric = registration.metric.MeanSquares;

    avg_registered_timeseries = zeros(size(avg_timeseries));
    avg_registered_timeseries(:,:,1) = fixed;
    binary_registered_timeseries = zeros(size(binary_timeseries));
    binary_registered_timeseries(:,:,1) = binary_timeseries(:,:,1);
    superResolution_registered_timeseries = zeros(size(superResolution_timeseries));
    superResolution_registered_timeseries(:,:,1) = superResolution_timeseries(:,:,1);
    for i = 1:size(avg_timeseries,3)-1
        avg_moving = avg_timeseries(:,:,i+1);
        binary_moving = binary_timeseries(:,:,i+1);
        superResolution_moving = superResolution_timeseries(:,:,i+1);
        tform = imregtform(avg_moving,fixed,"rigid",optimizer,metric); % base transformation on gauss avg images
        avg_registered_timeseries(:,:,i+1) = imwarp(avg_moving,tform,"OutputView",imref2d(size(fixed)));
        binary_registered_timeseries(:,:,i+1) = imwarp(binary_moving,tform,"OutputView",imref2d(size(fixed)));
        superResolution_registered_timeseries(:,:,i+1) = imwarp(superResolution_moving,tform,"OutputView",imref2d(size(fixed)));
    end
    avg_registered(:,:,:,rr) = avg_registered_timeseries;
    binary_registered(:,:,:,rr) = binary_registered_timeseries;
    superResolution_registered(:,:,:,rr) = superResolution_registered_timeseries;
end

% Crop larger view back down to desired spine length
avg_cropped = zeros(spine_im_length,spine_im_length,length(ims),length(new_centers)); % dims (spine width x spine height x num days x num spines)
binary_cropped = zeros(spine_im_length,spine_im_length,length(ims),length(new_centers));
superResolution_cropped = zeros(spine_im_length,spine_im_length,length(ims),length(new_centers));
for mm = 1:length(ims)
    for cn = 1:length(new_centers)
    curr_avg_reg = avg_registered(:,:,mm,cn);
    curr_binary_reg = binary_registered(:,:,mm,cn);
    curr_super_reg = superResolution_registered(:,:,mm,cn);
    
    halfway_idxs = (spine_im_length/2)+1:spine_im_length+(spine_im_length/2);
    avg_cropped(:,:,mm,cn) = curr_avg_reg(halfway_idxs,halfway_idxs); % middle X pixels
    binary_cropped(:,:,mm,cn) = curr_binary_reg(halfway_idxs,halfway_idxs);
    superResolution_cropped(:,:,mm,cn) = curr_super_reg(halfway_idxs,halfway_idxs);
    end
end

% Save input data so you can run later
test_data = struct;
test_data.avg_cropped = avg_cropped;
test_data.binary_cropped = binary_cropped;
test_data.superResolution_cropped = superResolution_cropped;
test_data.cycle_data = cycle_data;
test_data.classifications = classifications;
test_data.new_centers = new_centers;
test_data.select_spine_data = select_spine_data;
save('test_data.mat','test_data')

%% Call GUI and edit spines that did not appear in the binary projection
if gui_flag
    spineDetectionGUI_v2(test_data.avg_cropped,test_data.binary_cropped,test_data.superResolution_cropped,test_data.cycle_data,test_data.classifications,test_data.new_centers,test_data.select_spine_data);
end
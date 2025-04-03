function [spine_data,dendrite,superResolution] = analyzeDendrite_NSWEdit(file_name,...
    mean_image,save_image_flag, binarized_save_location,...
    micron, num_pixels, show_image_steps, skip_manual_binarization,...
    skip_manual_spine_collection,resize_ims,datadir)

if nargin < 1 || isempty(file_name)
    [file_name,file_path] = uigetfile('Select data file');
    addpath(genpath(file_path));
    cd(file_path)
end
if nargin < 2 || isempty(mean_image)
    % mean_image = data.gaus_mean_projection; % for data structures
    mean_image = importdata(file_name);
end
if nargin < 3 || isempty(save_image_flag)
    save_image_flag = 1; %1 = save images + data, 0 = do not save images
end
if nargin < 4 || isempty(binarized_save_location)
    binarized_save_location = 'E:\GFP Spine Imaging\Chronic imaging\E_TRIAL_1\Binarized Images'; % set manually
end
if nargin < 5 || isempty (micron)
    micron = 51.8; % for 16X on the two-photon
end
if nargin < 6 || isempty(num_pixels)
    num_pixels = 760;
end
if nargin < 7 || isempty(show_image_steps)
    show_image_steps = 0; %1 = show images as they are being processed, 0 = do not
end
if nargin < 8 || isempty(skip_manual_binarization)
    skip_manual_binarization = 0;
    % 0 = allow for manual binarization dialogue
    % 1 = do not ask to manually fix binarization -- this option is good if you
    % have already checked that each image is binarized correctly and the
    % binarized image with the same image name as the MGP is stored in the
    % binarized_branch_images path
end
if nargin < 9  || isempty(skip_manual_spine_collection)
    skip_manual_spine_collection = 1; % 0 = allow manual spine collection
end
if nargin < 10 || isempty(resize_ims)
    resize_ims = 0;
    % *function also resizes image if needed to stay consistent with data set
    % This is useful if you edited the images in another program which resized
    % them, but you want consistency so they match pixel per micron
    % measurement
end
if nargin < 11 || isempty(datadir)
    datadir = pwd; % default to base directory
end

% Set code path and convert images
[filepath,~,~] = fileparts(which('analyzeDendrite_NSWEdit.m'));
addpath(genpath(filepath)); % add path for helper functions
mean_image = mat2gray(mean_image);

%% 2 Binarizing Mean Gaus Projection
[dendrite,superResolution] = binarizeMeanGausProjection_NSWEdit(mean_image,file_name,...
    binarized_save_location,show_image_steps,num_pixels,...
    skip_manual_binarization, resize_ims, save_image_flag);

dendriteList = bwconncomp(dendrite); %counting spines

%% Get gaussian filtered image
% for average data from whole branch
spine_data = cell(100,18); %assumes max 100 spines
spines_found = bwmorph(dendrite,'remove'); %used for image that highlights spines found in yellow
count_spines_found = 0;
color_bank = ['m';'c';'g';'y'];
class_bank = {'stubby','thin','filopodium','mushroom'};

for dendriteIdx = 1:dendriteList.NumObjects
    BW = false(size(dendrite));
    BW(dendriteList.PixelIdxList{dendriteIdx}) = true;
    BW = imbinarize(imgaussfilt(double(BW),3),0.35); %imgaussfilt,medfilt2

    if sum(sum(BW)) < 2000 %skip if ROI is too small to be a dendrite
        continue;
    end
    figure, imshow(BW); % display if determined to be a real dendrite
    title('Gaussian filtered binarized image')

    %% 4 Skeletonization: Skeletonization of dendrite and trimming of "extra" spines

    %% Calculating Length of entire Dendritic Branch in microns
    denInfo = getDendriteInfoClass(BW);

    %% Initialize spine characteristics
    num_spines = 0;
    sum_head_width = 0;
    sum_spine_length = 0;

    %% 6 Spine identification & Classification 
    % identify and classify each spine based on standard criteria (morphological approach)
    % also segments out single spine images (option to save later on)
    for i = 1:(length(denInfo.x_end)) 
           spineClass = getSpineMorphologyClass(i,denInfo,BW);
           morphologicalClassification(spineClass);
           midpoint_base = spineClass.midpoint_base;
           spine_fill = spineClass.spine_fill;
           im = spineClass.im;
           class = spineClass.spine_label;
           
%         figure, imshowpair(spine_fill,BW)
%         title(['Current spine:',' ',class]) % uncomment to display each spine

        if sum(spine_fill(:)) < 30 || sum(spine_fill(:)) > 650
            %skip if not a spine
            disp(['ROI #',num2str(i),' ','is not a spine'])
%             disp(sum(spine_fill(:)))
            continue
        end
        num_spines = num_spines + 1;

        if ~contains(class,'not spine') %for all spines
            sum_head_width = sum_head_width + im.middle_length;
            sum_spine_length = sum_spine_length + im.spine_length;
            props = regionprops(spine_fill,'Centroid','BoundingBox','Perimeter','Eccentricity','Circularity');
            BB = props.BoundingBox;
            %% added to keep track of spine data
            % variable_names = {'image_name','estrous_phase','spine_number','spine_length','bottom_length','upper_length','aspect_ratio','sum(spine_fill)','centroid(1)','centroid(2)','boundingbox(1)','boundingbox(2)','boundingbox(3)','boundingbox(4)','midpoint_base_x','midpoint_base_y','spine_label'};
            count_spines_found = count_spines_found+1;
            % mouseid_recording#_dendrite#_day# ,	Estrous Stage
            spine_data{count_spines_found,1} = file_name;
            %'spine_number','spine_length','bottom_length','upper_length'
            spine_data{count_spines_found,2} = i;
            mBx = round(mean(midpoint_base(:,1)));
            mBy = round(mean(midpoint_base(:,2)));
            spine_data{count_spines_found,3} = mBx;
            spine_data{count_spines_found,4} = mBy;
            spine_data{count_spines_found,5} = [props.Perimeter];
            spine_data{count_spines_found,6} = [props.Eccentricity];
            spine_data{count_spines_found,7} = [props.Circularity];
            spine_data{count_spines_found,8} = im.spine_length;
            spine_data{count_spines_found,9} = im.spine_neck;
            spine_data{count_spines_found,10} = im.middle_length;
            spine_data{count_spines_found,11} = sum(spine_fill(:));
            spine_data{count_spines_found,12} = im.aspect_ratio;
            spine_data{count_spines_found,13} = class;
            spine_data{count_spines_found,14} = spine_fill;
            spine_data{count_spines_found,15} = [props.Centroid];
            spine_data{count_spines_found,16} = BB;

            min_r = floor(BB(2))-10; % set bounding box parameters, adjusting for when they exceed image bounds
            if min_r <1
                min_r = 1;
            end
            min_c = floor(BB(1))-20;
            if min_c <1
                min_c = 1;
            end
            max_r = ceil(BB(4))+20;
            if max_r > length(mean_image)
                max_r = length(mean_image);
            end
            max_c = ceil(BB(3))+20;
            if max_c > length(mean_image)
                max_c = length(mean_image);
            end
            min_max_r = min_r + max_r;
            if(min_max_r > 760)
                min_max_r = 760;
            end
            min_max_c = min_c + max_c;
            if(min_max_c > 760)
                min_max_c = 760;
            end

            spine_data{count_spines_found,17} = mean_image(min_r:min_max_r,min_c:min_max_c);
            spine_data{count_spines_found,18} = dendrite(min_r:min_max_r,min_c:min_max_c);

            color_idx = find(contains(class_bank,class));
            color = color_bank(color_idx); % color code by spine type
            spines_found = imoverlay(spines_found,spine_fill,color);
            spines_found = insertText(spines_found,[mBx,mBy],num2str(count_spines_found));
        end

        if show_image_steps == 1
            close all
        end
    end

    if ~skip_manual_spine_collection % manually collect spines missed by the algorithm
        [spine_data] = getManualSpines(spines_found,spine_data,count_spines_found,...
            BW,class_bank,color_bank,mean_image,dendrite);
    else
        %display image with classified spines
        figure
        imshow(spines_found)
        title('All identified spines')
        disp(['Legend: magenta = stubby, cyan = thin,' ...
            ' yellow = mushroom, green = filopodia']);
    end

    spine_tags = spine_data(:,1); 
    spine_length = length(spine_tags(~cellfun('isempty',spine_tags)));
    spine_data = spine_data(1:spine_length,:); % get rid of extra cells
    spine_table = cell2table(spine_data,"VariableNames",...
    ["Filename" "Spine number" "X coord spine base" "Y coord spine base"...
    "Perimeter" "Eccentricity" "Circularity" "Spine length" "Spine neck"...
    "Middle length" "Total spine area" "Aspect ratio" "Classification"...
    "Spine fill" "Centroid" "Bounding box" "Spine image" "Binary spine image"]); % convert to table

    if save_image_flag
       % save spine data to current directory
        save(strcat(datadir,'\',file_name(1:end-4),'_spineData.mat'),'spine_table') % save spine data for current branch
        %saves single spine image, if unwanted comment out the next part
    end
end
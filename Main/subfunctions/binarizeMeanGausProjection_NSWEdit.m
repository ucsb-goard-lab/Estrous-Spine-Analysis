function [BW,II] = binarizeMeanGausProjection_NSWEdit(mean_image,image_name,...
    binarized_branch_images,show_image_steps,numPixelsOfEachImage,...
    skip_manual_binarization, resize_imgs_if_needed, save_img_flag)
% Calls getFilteredImagesClass to binarize mean Guassian Projection
% microscopy images and allows for manual rebinarizing and spine selection

% Written by MEK
% Last running on Matlab 2022b
% Last updated April 28, 2023

% Uuses helper function natsortfiles published on mathworks by Stephen23

%%
if (nargin < 4)
    show_image_steps = 0;
    numPixelsOfEachImage = 760;
    skip_manual_binarization = 0;
    resize_imgs_if_needed = 1;
elseif (nargin < 5)
    numPixelsOfEachImage = 760;
    skip_manual_binarization = 0;
    resize_imgs_if_needed = 1;
elseif (nargin < 6)
    skip_manual_binarization = 0;
    resize_imgs_if_needed = 1;
elseif (nargin < 7)
    skip_manual_binarization = 0;
    resize_imgs_if_needed = 1;
end

% %% For testing purposes import data with this:
% [image_name,file_path] = uigetfile('Select data file');
% data = load(fullfile(file_path,image_name));
% mean_image = data.gaus_mean_projection;
% binarized_branch_images = 'C:\Users\Goard Lab\Dropbox\CodeInBeta_Marie\DendriticSpines\Data\binarizedBranches';
% show_image_steps = 1;
% numPixelsOfEachImage = 760;
% skip_manual_binarization = 0;
% resize_imgs_if_needed = 1;
%
% %set path for helper functions - gen path gets all subfolders too
% addpath(genpath('C:\Users\Goard Lab\Dropbox\CodeInBeta_Marie\DendriticSpines\Functions'));
%
% %add path for data
% addpath(file_path)


%% Resizing Image
if resize_imgs_if_needed == 1
    s4 = size(mean_image);

    % mean image is only resized to restore the image size to be consistent with
    % the rest of the dataset and to validly align with the recorded micrometer
    % dimension of each image

    if s4(1) < numPixelsOfEachImage
        mean_image = vertcat(mean_image,zeros(numPixelsOfEachImage-s4(1),s4(2)));
    end
    if s4(2) < numPixelsOfEachImage
        mean_image = horzcat(mean_image,zeros(numPixelsOfEachImage,numPixelsOfEachImage-s4(2)));
    end
    if (s4(1) > numPixelsOfEachImage || s4(2) > numPixelsOfEachImage)
        mean_image = imresize(mean_image,(numPixelsOfEachImage/(max(s4(1),s4(2)))));
        s4 = size(mean_image);
        if s4(1) < numPixelsOfEachImage
            mean_image = vertcat(mean_image,zeros(numPixelsOfEachImage-s4(1),s4(2)));
        end
        if s4(2) < numPixelsOfEachImage
            mean_image = horzcat(mean_image,zeros(numPixelsOfEachImage,numPixelsOfEachImage-s4(2)));
        end
        if s4(1) > numPixelsOfEachImage
            mean_image = mean_image(1:numPixelsOfEachImage,:);
        end
        if s4(2) > numPixelsOfEachImage
            mean_image = mean_image(:,1:numPixelsOfEachImage);
        end
        % For testing purposes uncomment these lines:
        % disp('size of dendrite after padding')
        % disp(num2str(size(dendrite)))
        % disp(num2str(numPixelsOfEachImage-s(1)))
        % disp(num2str(numPixelsOfEachImage-s(2)))

    end
end

%% checking if image has already been binarized
oldFolder = cd(binarized_branch_images);

file_list = struct2cell(dir('**/*.*'));
BW_images = natsortfiles(file_list(1,:));
cd(oldFolder)

fname = (strcat(erase(image_name,'.mat'),'.png'));
ind=find(ismember(BW_images(1,:),fname), 1);
%%
if isempty(ind) %if it hasn't then binarize it
    img_filt = getFilteredImagesClass();
    superResolution(img_filt, mean_image, show_image_steps);
    II = img_filt.II;
    binarize(img_filt, [], show_image_steps);
    BW = img_filt.BW;

    if skip_manual_binarization == 0
        % Show the image

        answer = ' ';

        meanImageEnh_2 = img_filt.meanImageEnhance;
        threshold = img_filt.thresh;

        while ~strcmp(answer,'No Change Needed')
            imshowpair(meanImageEnh_2,BW)
            % Prompt the user if they want to binarize it further
            answer = questdlg('Would you like to edit the image further?', 'Options','Re-binarize (new threshold)', 'Add or Remove Objects', 'No Change Needed','No Change Needed');

            if strcmp(answer, 'Re-binarize (new threshold)')
                % Binarize the image with different thresholds
                threshold1 = threshold * 0.75;
                threshold2 = threshold;
                threshold3 = threshold * 1.25;
                BW1 = imbinarize(II, threshold1);
                BW2 = imbinarize(II, threshold2);
                BW3 = imbinarize(II, threshold3);

                % Show the montage of binarized images at different thresholds
                montage({BW1, BW2, BW3}, 'Size', [1 3], 'BorderSize', 10, 'BackgroundColor', 'w');
                title(sprintf('threshold = %.2f, %.2f, %.2f', threshold1, threshold2, threshold3));

                % Prompt the user to select a threshold
                prompt = {'Enter the threshold value:'};
                dlgtitle = 'Threshold Selection';
                dims = [1 35];
                definput = {num2str(threshold)};
                answerT = inputdlg(prompt, dlgtitle, dims, definput);

                % Binarize the image according to the user selected threshold
                userSelectedThreshold = str2double(answerT{1});
                binarize(img_filt,userSelectedThreshold, 0);
                BW = img_filt.BW;

                continue;
            end

            if strcmp(answer, 'Add or Remove Objects')

                answer2 = ' ';
                % Prompt the user if they would like to remove or add spines
                while ~strcmp(answer2,'Neither')
                    imshowpair(meanImageEnh_2,BW)
                    answer2 = questdlg('Would you like to remove or add objects?', 'Options','Remove Objects', 'Add Objects', 'Neither', 'Neither');

                    if or(strcmp(answer2, 'Add Objects'), strcmp(answer2, 'Remove Objects'))
                        % Draw polygon and create mask
                        imshowpair(meanImageEnh_2,BW)
                        roi = drawpolygon();
                        mask = createMask(roi);

                        if strcmp(answer2, 'Add Objects')
                            % Add spines or dendrite
                            addBack = imbinarize(II, threshold*0.8);
                            addBack(~mask) = 0;
                            BW = imbinarize(imadd(BW,addBack,0.9));
                            % Object will be smoothed at the end!
                        elseif strcmp(answer2, 'Remove Objects')
                            BW(mask) = 0;
                        end
                        % Prompt the user again if they added or removed spines
                    end
                    continue;
                end
            end

        end

    end

else
    %image already binarized
    oldFolder = cd(binarized_branch_images);
    BW = load(image_name);
    BW = BW.gaus_mean_projection;
    % an error may appear and you may have to add the image to the path if it's not in the given binarized folder
    cd(oldFolder);
end


% Show final image;
BW = imbinarize(imgaussfilt(double(BW),3),0.75);
imshow(BW);
title('Binarized Image')

if save_img_flag
    oldFolder = cd(binarized_branch_images);
    imwrite(BW,strcat([image_name(1:end-4),'_binarized.png']))
    mkdir 'superresolution'
    imwrite(II,strcat(['superresolution\',image_name(1:end-4),'_superresolution.png']))
    cd(oldFolder)
end


end

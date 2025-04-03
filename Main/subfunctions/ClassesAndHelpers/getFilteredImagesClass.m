classdef getFilteredImagesClass < handle
    %GETFILTEREDIMAGES get binarized and superresolution images
    % Function binarizes mean Gaussian Projection converted from tif files of
    % microscopy images and resizes them to be consistent sizing if necessary
    
    % Function includes code lines 4-28 from SuperResolution Function by WTR
    % Function also uses part of procedure of "An open-source tool for analysis
    % and automatic identification of dendritic spines using machine learning"
    % by Smirnov and colleagues published in 2018.
    % Also uses helper function natsortfiles published on mathworks by Stephen23
    
    properties
        BW;
        II;
        meanImageEnhance;
        meanImageSub;
        thresh;
    end
    
    properties (Access = private)
        diameter;
        parameter;
    end
    
    methods
        function obj = getFilteredImagesClass()
            %GETFILTEREDIMAGES Construct an instance of this class
            %   Detailed explanation goes here
            obj.diameter   = [12 12];
            obj.parameter  = [6 -6];
        end
        
        function obj = superResolution(obj, mean_image, show_image_steps)

            %mean_image = mat2gray(mean_image); %normalizes grayscale to a range of [0, 1]
            mean_image = mat2gray(mean_image);
            
            meanImageFiltered = medfilt2(mean_image,(obj.diameter)*4+1);
        
            %%
            %remove noise with 2d median filter
            meanImageSub1        = mean_image - meanImageFiltered;
            obj.meanImageSub = meanImageSub1;
            meanImageFiltered_2 = medfilt2(abs(meanImageSub1),(obj.diameter)*4+1); %empty?
        
            meanImageDiv   = meanImageSub1 ./ (1e-10 + meanImageFiltered_2); %r
            meanImageDiv_2 = meanImageSub1 ./ (1e+10 + meanImageFiltered_2);%empty?
        
            meanImageEnh = (meanImageDiv - obj.parameter(2)) / (obj.parameter(1) - obj.parameter(2)); %r
            meanImageEnh = max(0,min(1,meanImageEnh)); %r
        
            meanImageEnh_2 = (meanImageDiv_2 - obj.parameter(2)) / (obj.parameter(1) - obj.parameter(2));
            meanImageEnh_2 = mat2gray(max(0,min(1,meanImageEnh_2)));
        
            meanImageEnh_2 = imadjust(meanImageEnh_2);
            meanImageEnh_2 = medfilt2(meanImageEnh_2,[6 6]);
        
            obj.II = meanImageEnh + meanImageEnh_2; %r

            obj.meanImageEnhance = meanImageEnh_2;

             if show_image_steps == 1
                figure
                montage({mean_image,meanImageFiltered,meanImageSub1,meanImageFiltered_2,meanImageDiv,meanImageEnh,meanImageDiv_2,meanImageEnh_2});
            end
        end

        function obj = binarize(obj, threshold, show_image_steps)
            [counts,~] = imhist(obj.II);
            if(isempty(threshold))
                threshold    = otsuthresh(counts);
            end

            obj.thresh = threshold;
        
            % UPDATED: Automatic Threshold Selection from Histogram of image
            % inspired by:
            % https://onlinelibrary.wiley.com/doi/full/10.1002/cyto.a.20431
        
            I            = imbinarize(obj.II,threshold);
            value        = 10;
            I(1:value,:) = 0; I(end-value:end,:) = 0; % top  & bottom part
            I(:,1:value) = 0; I(:,end-value:end) = 0; % left & right  part
            se1          = strel('disk',3);
            I            = imopen(I,se1);
        
            se = strel('disk',35);
            BW1 = (imbinarize(imdilate((imbinarize(double(obj.meanImageSub), 0.15)),se).*I));
            obj.BW = imbinarize(imgaussfilt(double(BW1),3),0.55);
            perimeter = sum(sum(bwperim(obj.BW)));

            if show_image_steps == 1
                figure
                montage({I, obj.BW});
            end
        end
            
    end
end


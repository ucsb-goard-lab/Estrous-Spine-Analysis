function [spine_data] = getManualSpines(spines_found,spine_data,count_spines_found,...
            BW,class_bank,color_bank,mean_image,dendrite)
%% Manual spine curator
%-------------------------------------------------------------------------%
%   This function displays all classified spines projected on the dendritic
%   segment and asks the user to add or remove any spines that the
%   algorithm misclassified as a spine/not spine.
%
%   Written by NSW 06/08/2023 // Last updated by NSW 06/08/2023
%-------------------------------------------------------------------------%

%display image with classified spines
figure
imshow(spines_found)
title('All identified spines')
disp(['Legend: magenta = stubby, cyan = thin,' ...
    ' yellow = mushroom, green = filopodia']);

spines2remove = zeros(size(spine_data,1),1); % for all spines
for ii = 1:size(spine_data,1) % for all spines
    answer = questdlg('Would you like to add/subtract spines?', ...
    	'Manual Curation', ...
    	'Add spine','Subtract spine','Neither','Neither');
    % Handle response
    switch answer
        case 'Add spine'
            roi = drawpolygon();
            mask = createMask(roi);  
            % get spine attributes
            count_spines_found = count_spines_found+1;
            spine_fill = BW;
            spine_fill(~mask) = false; % isolate spine in image

            list = {'stubby','thin','mushroom','filopodium'};
            [idx,~] = listdlg('ListString',list);
            class = list{idx};

            props = regionprops(spine_fill,'Centroid','BoundingBox','Perimeter','Eccentricity','Circularity');
            if isempty(props) % if the user accidentally selected a region that's not on the dendrite of interest
                w = warndlg('Selected region was not on dendrite of interest. Please try again.','Warning');
                uiwait(w) % pause until user presses 'OK'
                imshow(spines_found)
                title('All identified spines')
                continue; % go back to original
            end
            BB = props.BoundingBox;

            % save attributes in data structure
            spine_data{count_spines_found,1} = 'new spine';
            spine_data{count_spines_found,2} = count_spines_found+1;
            spine_data{count_spines_found,5} = [props.Perimeter];
            spine_data{count_spines_found,6} = [props.Eccentricity];
            spine_data{count_spines_found,7} = [props.Circularity];
            spine_data{count_spines_found,11} = sum(spine_fill(:));
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

            spine_data{count_spines_found,17} = mean_image(min_r:min_r+max_r,min_c:min_c+max_c);
            spine_data{count_spines_found,18} = dendrite(min_r:min_r+max_r,min_c:min_c+max_c);
            
            % display new spines in figure
            color_idx = find(contains(class_bank,class));
            color = color_bank(color_idx); % color code by spine type
            spines_found = imoverlay(spines_found,spine_fill,color);
            [y,x] = find(spine_fill);
            spines_found = insertText(spines_found,[x(1,1),y(1,1)],num2str(count_spines_found));
            imshow(spines_found)
            title('All identified spines')

        case 'Subtract spine'
            prompt = {'Enter the number of the spine you wish to remove:'};
            dlgtitle = 'Input';
            dims = [1 35];
            definput = {'1'};
            answer = inputdlg(prompt,dlgtitle,dims,definput);
            idx2remove  = str2num(cell2mat(answer));
            spine_fill = cell2mat(spine_data(idx2remove,14));
            spines_found = imoverlay(spines_found,spine_fill,'k'); % fill spine black
            imshow(spines_found)
            title('All identified spines')
            spines2remove(idx2remove,1) = 1; % mark what spines to remove

        case 'Neither'
            spine_subtract_idx = find(spines2remove);
            if ~isempty(spine_subtract_idx)
                spine_data(spine_subtract_idx,:) = []; % remove selected spines from cell array
            end
            break % exit loop
    end
end
end
function [] = batchSortImages()
%% Plane Sorting
%-------------------------------------------------------------------------%
%   Creates folders for different imaging planes, and sorts single page
%   tifs into their respective folders.
%
%   Written by NSW 09/19/2024, Edited by NSW 09/27/2024
%-------------------------------------------------------------------------%
% get recording folders
mainfolders = dir('*NSW*');

for ii = 1:length(mainfolders)
    curr_fol = mainfolders(ii).name;
    cd(curr_fol)

    % get TSeries folder names
    subfolders = dir('TSeries*'); %% for spines: dir('**/*.*');

    for ss = 1:length(subfolders)
        curr_sub = subfolders(ss).name;
        cd(curr_sub)

        ims = dir('*.tif');
        if length(ims) < 1010
            cd ..
            continue; % skip if there's only one plane
        end
    
        num_planes = round(length(ims)/1000);
        disp('Sorting images by plane...')
        % Create folders for each plane
        for i = 1:num_planes
            n = num2str(i);
            newdir = ['plane', ' ', n];
            mkdir(newdir)

            % move images to respective folder
            prefix = strcat(curr_sub, '_Cycle0000', n, '_Ch2_*.ome.tif');
            files = dir(prefix);
            num_files = length(files);

            for j = 1:num_files
                filename = files(j).name;
                if isfile(filename)
                    movefile(filename, newdir,'f')
                end
            end

            % copy env and xml files into new folder
            env_file = dir('*.env');
            xml_file = dir('*.xml');
            env_filename = env_file.name;
            xml_filename = xml_file.name;
            copyfile (env_filename, newdir)
            copyfile (xml_filename, newdir)
        end
        cd ..
    end
    cd ..
end
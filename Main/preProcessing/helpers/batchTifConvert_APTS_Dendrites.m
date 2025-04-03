function [] = batchTifConvert_APTS_Dendrites(tif_convert,preprocess)
% Convert .tif files
% Run A_ProcessTimesSeries on all files

if nargin < 1 || isempty(tif_convert)
    tif_convert = 1; % convert tifs from Prairie format to multipage
end
if nargin < 2
    preprocess = 1; % run batchProcessTimeSeries.m
end
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
            if isempty(planefolders)
                planefolders = subfolders(i); % if no planes, just set plane to current folder
            end
            % tifdir = dir('tifs\');

            % if ~isempty(tifdir)
            %     cd tifs
            % else
            %     continue
            % end

            for pp = 1:length(planefolders)
                curr_plane = [planefolders(pp).folder,'\',planefolders(pp).name];
                cd(curr_plane) % move into current plane (or if no planes, stay in the same directory)

                folder_contents = dir('*.ome.tif');
                if length(folder_contents) < 250 % determine if folder is already processed
                    cd ..
                    continue;
                end

                % convert .tif files
                if tif_convert==1
                    firstfile = folder_contents(1).name;
                    subroutine_tifConvert(firstfile)
                end

                % run preprocessing code
                if preprocess==1
                    register_flag = 'Yes';
                    nonrigid_flag = 'No';
                    movie_flag = 'No';

                    % find tif files
                    curr_dir = dir;
                    file_num = 0;
                    filelist = cell(1);
                    for ii = 1:length(curr_dir)
                        curr_idx = strfind(curr_dir(ii).name,'tif');
                        if ~isempty(curr_idx)
                            file_num = file_num+1;
                            filelist{file_num} = curr_dir(ii).name;
                        end
                    end

                    % run time series processing
                    % map_type = 'mDFF';  % type of activity map to use in preprocessing step
                    %A_ProcessTimeSeries(filelist,register_flag,nonrigid_flag,movie_flag)
                    A_ProcessTimeSeries(filelist,register_flag,nonrigid_flag,movie_flag)
                end
                cd(folder_path) % go back to directory containing all planes
            end
        end
        cd(curr_fol) % go back to directory containing all recordings
    end
    cd ..
end
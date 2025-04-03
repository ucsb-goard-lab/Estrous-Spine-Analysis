function [] = crossSectionalSpineAnalysis(cycle_flag,plot_flag)
%% Cross-Sectional Spine Analysis
%-------------------------------------------------------------------------%
%   This function uses previously written software to binarize all
%   registered and cropped gaussian avergaed dendrite images, then 
%   determine the cumulative population of spines along with their 
%   morphological properties. Data is saved as a table in subfolder "data".
%   "data". Inclusion of estrous cycle as a parameter is optional.
%
%   NOTE: spine detection and classification are dependent on the
%   parameters of 16X magnification, i.e. 51.8 x 51.8 microns. Images taken
%   at different magnifications should be normalized to these parameters
%   for correct placement in the decision tree, or the decision tree should
%   be modified to account for different pixel values. Otherwise, an ML
%   approach would be more appropriate.
%
%   Written by NSW 10/18/2023 // Last updated by NSW 12/27/2023
%-------------------------------------------------------------------------%

if nargin < 1 || isempty(cycle_flag)
    cycle_flag = 'Yes'; % defaults to true for estrous analysis
end
if nargin < 2 || isempty(plot_flag)
    plot_flag = 'Yes'; % defaults to plot data
end

microns = 51.8; % micron length of image
filepath = mfilename('fullpath');
addpath(genpath(filepath(1:end-12))) % add all subfunctions to path (works if function is not renamed)

if strcmp(cycle_flag,'Yes') % get cycle info for estrous experiments
    disp('Select cycle data')
    [cname,cpath] = uigetfile('*.mat');
    cycle_data = importdata(strcat(cpath,cname));
end

%% Set up directory structure for data saving 
ims = dir('*.png');
ims = natsortfiles({ims.name}); % alphanumerically sort by filename
bname = 'binarized';
mkdir(bname)
dname = 'data';
mkdir(dname)
base = pwd;

%% Cycle through images and get number and morphological parameters for all spines
% data is saved to created directories as well as in local structure for
% plotting
all_spine_data = cell(length(ims),1); % make array to store all spine data
spine_density = zeros(1,length(ims)); % save number of spines per 10 um
spine_types = zeros(4,length(ims)); % where rows are %'s of stubby, thin, mushroom, and filopodium spines, respectively
spine_lengths = NaN(100,length(ims)); % each column is an image; 100 to make room for all spines
spine_areas = NaN(100,length(ims));
for ii = 1:length(ims)
    if strcmp(cycle_flag,'Yes') % display current stage if relevant 
        disp(['Current stage:', ' ', cycle_data{ii}])
    end
    imname = ims{ii};
    curr_im = imread(imname);
    binary_dir = strcat(base,'\',bname);
    datadir = strcat(base,'\',dname);
    [spine_data,binary_im,~] = analyzeDendrite_NSWEdit(imname, curr_im, 1, binary_dir, [],...
        length(curr_im), 0, 0, 0, 0, datadir); % binarize image and collect spine data
    all_spine_data{ii} = spine_data; % save spine data for plotting
    close all

    % Get the density of spines per 10um
    skel1 = bwskel(binary_im,'MinBranchLength',100); % skeletonize
    se = strel('disk',15);
    dil = imdilate(skel1,se); % dilate to smooth
    skeleton = bwmorph(dil,'thin',inf); % reskeletonize

    pixel_length = length(find(skeleton)); % length of dendrite in pixels
    micron_ratio = microns/length(binary_im); % every pixel is X microns
    micron_length = pixel_length*micron_ratio; % length of dendrite in microns
    curr_spine_density = size(spine_data,1)/(micron_length/10); % spines per 10 microns
    spine_density(ii) = curr_spine_density;

    % Get simple matrices of relevant variables
    spine_length = cell2mat(spine_data(:,8));
    spine_lengths(1:length(spine_length),ii) = spine_length;

    spine_area = cell2mat(spine_data(:,11));
    spine_areas(1:length(spine_area),ii) = spine_area;
    
    spine_class = spine_data(:,13);
    stubby_idx = find(contains(spine_class,'stubby'));
    spine_types(1,ii) = (length(stubby_idx)/length(spine_class))*100; % percent stubby spines
    thin_idx = find(contains(spine_class,'thin'));
    spine_types(2,ii) = (length(thin_idx)/length(spine_class))*100; % percent thin spines
    mushroom_idx = find(contains(spine_class,'mushroom'));
    spine_types(3,ii) = (length(mushroom_idx)/length(spine_class))*100; % percent mushroom spines
    filopodia_idx = find(contains(spine_class,'filopodium'));
    spine_types(4,ii) = (length(filopodia_idx)/length(spine_class))*100; % percent filopodia spines
end


%% Plot spine density, type, length, and area across images
if strcmp(plot_flag,'Yes')    
    % make x axis labels
    xlabels = cell(1,length(ims));
    for xx = 1:length(ims)
        xlabels{1,xx} = ['Image',' ',num2str(xx)];
    end
    f = figure;
    f.Position = [200 200 1000 500];
    ax1 = axes('Parent',f,'Units','normalized','Position',[.05 .1 .4 .7]);
    plot(spine_density, '-o', 'LineWidth', 2, 'Parent', ax1) % plot spine density
    ylim([0 15])
    set(gca, 'XTick', 1:length(ims), 'XTickLabel', xlabels)
    title('Spine density','fontsize',15)
    ylabel('# spines per 10 um','fontsize',12)

    ax2 = axes('Parent',f,'Units','normalized','Position',[.55 .5 .4 .3]);
    b = bar(spine_types','Parent',ax2); 
    if size(spine_types,2) == 1 % format differently for single image
        xticklabels({'stubby','thin','mushroom','filopodium'})
        b.FaceColor = 'flat';
        b.CData(1,:) = [0.03,0.01,0.32];
        b.CData(2,:) = [0.03,0.51,0.58];
        b.CData(3,:) = [0.25,0.97,1];
        b.CData(4,:) = [0.95,0.97,0.63];
    else
        xticklabels(xlabels)
        colors = {'#071952','#088395','#40F8FF','#F2F7A1'};
        colororder(colors)
        legend({'stubby','thin','mushroom','filopodium'},'Position',[0.88 0.78 0.1 0.07])
    end
    title('Spine type proportion','fontsize',15)
    ylabel('% spine type','fontsize',12)

    ax3 = axes('Parent',f,'Units','normalized','Position',[.55 .1 .17 .3]);
    violinplot(spine_lengths,xlabels);
    ylabel('spine length (pixels)','fontsize',12)
    title('Spine length','fontsize',15)

    ax4 = axes('Parent',f,'Units','normalized','Position',[.8 .1 .17 .3]);
    violinplot(spine_areas,xlabels);
    ylabel('spine area (pixels)','fontsize',12)
    title('Spine area','fontsize',15)

    sgtitle('Cross-Sectional Spine Analysis','fontsize',20)
end
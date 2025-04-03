%% Master Spine Analysis 
% Determines whether you want to get raw numbers of spines or analyze spine
% turnover over a timecourseand and calls the relevant functions

filepath = matlab.desktop.editor.getActiveFilename;
addpath(genpath(filepath(1:end-21))) % add all functions to path

close all
crossSectional_flag = questdlg('Are you analyzing a timecourse series of images?', ...
	'Longitudinal vs CrossSectional','Yes','No','Yes');
switch crossSectional_flag
    case 'Yes'
        getAllSpines(0); % run longitudinal spine analysis without GUI
    case 'No'
        cycle_flag = questdlg('Would you like to analyze this data as a function of estrous stage?', ...
        	'Cycle flag','Yes','No','Yes');
        plot_flag = questdlg('Would you like to plot your results?', ...
        	'Plot flag','Yes','No','Yes');
        crossSectionalSpineAnalysis(cycle_flag,plot_flag); % run cross-sectional spine analysis
end
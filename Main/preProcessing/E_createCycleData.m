function [] = E_createCycleData(cycle_name)
%% Create cycle data file for spine pipeline
%-------------------------------------------------------------------------%
%   This function identifies the cycle prefix for each image in a sequence
%   and saves them as a cell array of strings. Should be run from the
%   directory containing the png sequence.
%
%   Written by NSW 02/13/2025
%-------------------------------------------------------------------------%
if nargin < 1 || isempty(cycle_name)
    cycle_name = 'cycle_data.mat'; % filename to save under
end

%% Extract and store png prefixes
ims = dir('*.png');
ims = natsortfiles(ims);
cycle_data = cell(1,length(ims));
for ii = 1:length(ims)
    curr_name = ims(ii).name;
    parts = split(curr_name, '_');
    cycle_data{ii} = parts{1};
end

%% Save to current directory
save(cycle_name,"cycle_data")


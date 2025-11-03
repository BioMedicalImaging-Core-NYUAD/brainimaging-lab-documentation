function [pa, el] = eyelink_init(VP, pa, enabled)
% EYELINK_INIT - Initialize Eyelink using reference implementation
% Returns el = [] if disabled or any failure occurs
%
% Uses the same approach as vri_restingstate experiment

% Add Eyetracking directory to path
eyetrackingDir = fullfile(fileparts(mfilename('fullpath')), 'Eyetracking');
if ~exist(eyetrackingDir, 'dir')
    warning('eyelink_init:EyetrackingDirNotFound', 'Eyetracking directory not found: %s', eyetrackingDir);
end
addpath(eyetrackingDir);

el = [];
if nargin < 3 || ~enabled
    if isfield(pa, 'eyeTrackingEnabled')
        pa.eyeTrackingEnabled = 0;
    end
    return;
end

% Ensure output directory and filenames exist on pa
if ~isfield(pa, 'eyeDataDir') || ~isfield(pa, 'eyeFileBase') || ~isfield(pa, 'eyeFileName')
    warning('eyelink_init:missingParams', 'Missing eye tracking params on pa; disabling.');
    pa.eyeTrackingEnabled = 0;
    return;
end

try
    % Use the reference implementation's initEyetracking function
    el = initEyetracking(VP, pa);
    
    if isempty(el)
        pa.eyeTrackingEnabled = 0;
        return;
    end
    
    pa.eyeTrackingEnabled = 1;
catch ME
    warning('eyelink_init:error', 'Eyelink init error: %s. Disabling.', ME.message);
    try, Eyelink('Shutdown'); catch, end
    el = [];
    pa.eyeTrackingEnabled = 0;
end

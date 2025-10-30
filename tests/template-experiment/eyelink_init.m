function [pa, el] = eyelink_init(VP, pa, enabled)
% EYELINK_INIT - Minimal, guarded initialization for Eyelink recording
% Returns el = [] if disabled or any failure occurs

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
    if Eyelink('Initialize') ~= 0
        warning('eyelink_init:initFailed', 'Eyelink Initialize failed; disabling.');
        pa.eyeTrackingEnabled = 0;
        return;
    end

    % Basic graphics defaults tied to PTB window
    el = EyelinkInitDefaults(VP.window);

    % Minimal tracker configuration
    Eyelink('Command', 'calibration_type = HV5');
    Eyelink('Command', 'calibration_area_proportion = 0.80 0.40');
    Eyelink('Command', 'validation_area_proportion = 0.80 0.40');
    Eyelink('Command', 'sample_rate = 1000');
    Eyelink('Command', 'file_sample_data = LEFT,RIGHT,GAZE,AREA');
    Eyelink('Command', 'link_sample_data = LEFT,RIGHT,GAZE,AREA');

    % Open EDF (base must be <= 8 chars, no extension)
    status = Eyelink('OpenFile', pa.eyeFileBase);
    if status ~= 0
        warning('eyelink_init:openFileFailed', 'Failed to open EDF on host; disabling.');
        Eyelink('Shutdown');
        el = [];
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


function eyelink_start(el)
% EYELINK_START - Start recording and tag experiment start
if isempty(el)
    return;
end
try
    Eyelink('StartRecording');
    WaitSecs(0.1);
    Eyelink('Message', 'EXPERIMENT_START');
catch ME
    warning('eyelink_start:error', 'StartRecording failed: %s', ME.message);
end


function eyelink_stopAndSave(el, pa)
% EYELINK_STOPANDSAVE - Stop, close, and receive EDF to local disk
if isempty(el)
    return;
end
try
    Eyelink('Message', 'EXPERIMENT_END');
    Eyelink('StopRecording');
catch ME
    warning('eyelink_stopAndSave:stopError', 'StopRecording error: %s', ME.message);
end

try
    Eyelink('CloseFile');
catch ME
    warning('eyelink_stopAndSave:closeError', 'CloseFile error: %s', ME.message);
end

% Attempt to receive file to pa.eyeDataDir/pa.eyeFileName
try
    localPath = fullfile(pa.eyeDataDir, pa.eyeFileName);
    Eyelink('ReceiveFile', pa.eyeFileBase, localPath);
catch ME
    warning('eyelink_stopAndSave:receiveError', 'ReceiveFile error: %s', ME.message);
end

try
    Eyelink('Shutdown');
catch
end



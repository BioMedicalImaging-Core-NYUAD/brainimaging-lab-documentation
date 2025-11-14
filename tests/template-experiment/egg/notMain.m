function notMain()
% NOTMAIN - Simple eye tracking experiment showing an image for 10 seconds
% Just for fun - not part of the actual experiment

% Clear workspace and close any open windows
clear all; close all; sca;

% Get script directory
scriptDir = fileparts(mfilename('fullpath'));

% Add utility folders to path
experimentDir = fullfile(scriptDir, '..');
projectRoot = fullfile(experimentDir, '..', '..');
vpixxPath = fullfile(projectRoot, 'experiments', 'general', 'vpixx-utilities');
addpath(vpixxPath);
addpath(genpath(fullfile(experimentDir, 'utils')));

% Image path (relative to script location)
imagePath = fullfile(scriptDir, 'photo.jpg');
if ~exist(imagePath, 'file')
    error('Image not found: %s', imagePath);
end

% Duration
duration = 10.0; % seconds

% Debug configuration
debugConfig = struct();
debugConfig.enabled = 1;
debugConfig.useVPixx = 1;
debugConfig.fullscreen = 1;
debugConfig.skipSyncTests = 1;
debugConfig.displayMode = 1;
debugConfig.manualTrigger = 1;
debugConfig.buttonbox = 1;
debugConfig.eyetracking = 1; % Enable eye tracking

% Setup display
[VP, debugConfig] = setup_display(debugConfig);

% Setup keyboard
kb = setup_keyboard();

% Initialize eye tracking (following reference pattern exactly)
if debugConfig.eyetracking
    % Create eye tracking file name (EDF files must be <= 8 characters)
    % Use format: eggHHMM (e.g., egg1430)
    timestamp = datestr(now, 'HHMM');
    pa.eyeFileBase = sprintf('egg%s', timestamp);
    pa.eyeDataDir = fullfile(scriptDir, 'results');
    if ~exist(pa.eyeDataDir, 'dir')
        mkdir(pa.eyeDataDir);
    end
    
    pa.EL = initEyetracking(VP, pa);
    if isempty(pa.EL)
        pa.eyeTrackingEnabled = 0;
    else
        pa.eyeTrackingEnabled = 1;
    end
else
    pa.EL = [];
    pa.eyeTrackingEnabled = 0;
end

% Initialize gaze recording parameters (same as setup_param.m)
pa.gazeSampleInterval = 0.5; % Record every 0.5 seconds
pa.maxGazeSamples = ceil(duration / pa.gazeSampleInterval) + 1000; % Extra buffer
pa.gazeSampleCounter = 0;
pa.data.continuousGazeX = nan(1, pa.maxGazeSamples);
pa.data.continuousGazeY = nan(1, pa.maxGazeSamples);
pa.data.continuousGazeTime = nan(1, pa.maxGazeSamples);
pa.pupilDataAvailable = false;
if pa.eyeTrackingEnabled
    pa.data.continuousPupilArea = nan(1, pa.maxGazeSamples);
end

% Store screen info for visualization
pa.screenCenter = VP.windowCenter;
pa.screenWidthPix = VP.windowWidthPix;
pa.screenHeightPix = VP.windowHeightPix;
pa.backGroundColor = VP.backGroundColor;

% Load image
try
    img = imread(imagePath);
    % Convert to RGB if needed (handle grayscale, indexed, etc.)
    if size(img, 3) == 1
        img = repmat(img, [1, 1, 3]); % Convert grayscale to RGB
    elseif size(img, 3) == 4
        % RGBA - extract RGB only for Psychtoolbox
        img = img(:, :, 1:3);
    end
    % Ensure uint8 format
    if ~isa(img, 'uint8')
        img = uint8(img);
    end
    imgTexture = Screen('MakeTexture', VP.window, img);
    
    % Get image size and center it (scale by 2x)
    [imgHeight, imgWidth, ~] = size(img);
    imgRect = [0, 0, imgWidth * 2, imgHeight * 2];
    imgRect = CenterRectOnPoint(imgRect, VP.windowCenter(1), VP.windowCenter(2));
catch ME
    sca;
    error('Failed to load image: %s', ME.message);
end

% Calibration (following reference pattern - called before experiment starts)
if pa.eyeTrackingEnabled
    [~, exitFlag] = initEyelinkStates('calibrate', VP.window, pa.EL);
    if exitFlag
        fprintf('\nCalibration failed or was cancelled. Disabling eye tracking.\n');
        pa.EL = [];
        pa.eyeTrackingEnabled = 0;
    end
end

% Wait for trigger
fprintf('Press ''t'' or ''5'' to start...\n');
while true
    [keyIsDown, ~, keyCode] = KbCheck(-1);
    if keyIsDown
        if keyCode(KbName('5%')) || keyCode(KbName('t'))
            break;
        elseif keyCode(kb.escKey)
            sca;
            fprintf('Experiment cancelled.\n');
            return;
        end
    end
    WaitSecs(0.01);
end

% Start recording (following reference pattern from main.m)
if pa.eyeTrackingEnabled
    err = Eyelink('CheckRecording');
    if err ~= 0
        initEyelinkStates('startrecording', VP.window, pa.EL);
        fprintf('Eyelink now recording ..\n');
    end
end

% Start experiment
experimentStartTime = GetSecs;
% Initialize gaze sample timing (subtract interval so first sample is recorded immediately)
pa.lastGazeSampleTime = experimentStartTime - pa.gazeSampleInterval;
fprintf('Starting experiment...\n');

% Main loop
while (GetSecs - experimentStartTime) < duration
    % Check for escape
    [keyIsDown, ~, keyCode] = KbCheck(-1);
    if keyIsDown && keyCode(kb.escKey)
        fprintf('Experiment aborted by user.\n');
        break;
    end
    
    % Draw gray background
    Screen('FillRect', VP.window, VP.backGroundColor);
    
    % Draw image
    Screen('DrawTexture', VP.window, imgTexture, [], imgRect);
    
    % Record gaze
    if pa.eyeTrackingEnabled
        pa = record_continuous_gaze(pa, experimentStartTime);
    end
    
    % Flip
    Screen('Flip', VP.window);
end

% Stop eye tracking (following reference pattern from cleanup_experiment.m)
if pa.eyeTrackingEnabled
    try
        if isfield(pa, 'eyeFileBase') && isfield(pa, 'eyeDataDir')
            initEyelinkStates('eyestop', VP.window, {pa.eyeFileBase, pa.eyeDataDir});
        end
    catch ME
        fprintf('  Warning: Could not stop Eyelink: %s\n', ME.message);
    end
end

% Close image texture
Screen('Close', imgTexture);

% Save data with timestamp (use full timestamp for .mat file)
timestampFull = datestr(now, 'yyyymmdd_HHMMSS');
saveFile = fullfile(scriptDir, 'results', sprintf('egg_%s.mat', timestampFull));
if ~exist(fullfile(scriptDir, 'results'), 'dir')
    mkdir(fullfile(scriptDir, 'results'));
end

% Trim arrays to actual samples
if pa.eyeTrackingEnabled && pa.gazeSampleCounter > 0
    pa.data.continuousGazeX = pa.data.continuousGazeX(1:pa.gazeSampleCounter);
    pa.data.continuousGazeY = pa.data.continuousGazeY(1:pa.gazeSampleCounter);
    pa.data.continuousGazeTime = pa.data.continuousGazeTime(1:pa.gazeSampleCounter);
    if isfield(pa.data, 'continuousPupilArea')
        pa.data.continuousPupilArea = pa.data.continuousPupilArea(1:pa.gazeSampleCounter);
    end
end

% Store image path for visualization
pa.imagePath = imagePath;
pa.imageRect = imgRect;

save(saveFile, 'pa');
fprintf('Data saved to: %s\n', saveFile);

% Cleanup
sca;
fprintf('Experiment complete!\n');

end

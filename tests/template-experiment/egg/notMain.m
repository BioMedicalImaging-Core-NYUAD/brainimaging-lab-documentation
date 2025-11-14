function notMain()
% NOTMAIN - Simple eye tracking experiment showing an image for 10 seconds
% Just for fun - not part of the actual experiment

% Clear workspace and close any open windows
clear all; close all; sca;

% Add utility folders to path
scriptDir = fileparts(mfilename('fullpath'));
experimentDir = fullfile(scriptDir, '..');
projectRoot = fullfile(experimentDir, '..', '..');
vpixxPath = fullfile(projectRoot, 'experiments', 'general', 'vpixx-utilities');
addpath(vpixxPath);
addpath(genpath(fullfile(experimentDir, 'utils')));

% Image path
imagePath = '/Users/pw1246/Desktop/haidee.jpg';
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

% Initialize eye tracking
pa = struct();
pa.eyeTrackingEnabled = 0;
pa.pupilDataAvailable = false;

if debugConfig.eyetracking
    % Create eye tracking file name with timestamp
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    pa.eyeFileBase = sprintf('egg_%s', timestamp);
    pa.eyeDataDir = fullfile(scriptDir, 'results');
    if ~exist(pa.eyeDataDir, 'dir')
        mkdir(pa.eyeDataDir);
    end
    
    pa.EL = initEyetracking(VP, pa);
    if isempty(pa.EL)
        fprintf('Warning: Eye tracking initialization failed. Continuing without eye tracking.\n');
        pa.eyeTrackingEnabled = 0;
    else
        pa.eyeTrackingEnabled = 1;
        
        % Initialize gaze recording parameters
        pa.gazeSampleInterval = 0.01; % Sample every 10ms (~100 Hz)
        pa.maxGazeSamples = ceil(duration / pa.gazeSampleInterval) + 1000; % Extra buffer
        pa.gazeSampleCounter = 0;
        pa.lastGazeSampleTime = GetSecs;
        
        % Pre-allocate gaze data arrays
        pa.data.continuousGazeX = nan(1, pa.maxGazeSamples);
        pa.data.continuousGazeY = nan(1, pa.maxGazeSamples);
        pa.data.continuousGazeTime = nan(1, pa.maxGazeSamples);
        pa.data.continuousPupilArea = nan(1, pa.maxGazeSamples);
        
        % Calibrate
        [~, exitFlag] = initEyelinkStates('calibrate', VP.window, {pa.EL});
        if exitFlag
            fprintf('Warning: Eye tracking calibration cancelled. Continuing without eye tracking.\n');
            pa.eyeTrackingEnabled = 0;
        else
            % Start recording
            initEyelinkStates('trialstart', VP.window, {pa.EL, 1, VP.windowCenter(1), VP.windowCenter(2), 50});
        end
    end
end

% Store screen info for visualization
pa.screenCenter = VP.windowCenter;
pa.screenWidthPix = VP.windowWidthPix;
pa.screenHeightPix = VP.windowHeightPix;
pa.backGroundColor = VP.backGroundColor;

% Load image
try
    [img, ~, alpha] = imread(imagePath);
    if ~isempty(alpha)
        img = cat(3, img, alpha);
    end
    imgTexture = Screen('MakeTexture', VP.window, img);
    
    % Get image size and center it
    [imgHeight, imgWidth, ~] = size(img);
    imgRect = [0, 0, imgWidth, imgHeight];
    imgRect = CenterRectOnPoint(imgRect, VP.windowCenter(1), VP.windowCenter(2));
catch ME
    sca;
    error('Failed to load image: %s', ME.message);
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

% Start experiment
experimentStartTime = GetSecs;
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

% Stop eye tracking
if pa.eyeTrackingEnabled
    initEyelinkStates('trialstop', VP.window, {});
    initEyelinkStates('eyestop', VP.window, {pa.eyeFileBase, pa.eyeDataDir});
end

% Close image texture
Screen('Close', imgTexture);

% Save data with timestamp
saveFile = fullfile(scriptDir, 'results', sprintf('egg_%s.mat', timestamp));
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


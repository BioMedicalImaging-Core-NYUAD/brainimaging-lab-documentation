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

% Image paths (relative to script location)
imagePath1 = fullfile(scriptDir, 'photo.png');
imagePath2 = fullfile(scriptDir, 'photo2.jpg');
imagePath3 = fullfile(scriptDir, 'photo3.png');
if ~exist(imagePath1, 'file')
    error('Image 1 not found: %s', imagePath1);
end
if ~exist(imagePath2, 'file')
    error('Image 2 not found: %s', imagePath2);
end
if ~exist(imagePath3, 'file')
    error('Image 3 not found: %s', imagePath3);
end

% Duration for each photo
duration1 = 10.0; % seconds for first photo
duration2 = 15.0; % seconds for second photo
duration3 = 10.0; % seconds for third photo
duration = duration1 + duration2 + duration3; % total duration

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

% Initialize gaze recording parameters
pa.gazeSampleInterval = 0.01; % Record 100 times per second (1/100 = 0.01 seconds) for lower latency
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

% Load images
try
    % Load first image
    img1 = imread(imagePath1);
    if size(img1, 3) == 1
        img1 = repmat(img1, [1, 1, 3]);
    elseif size(img1, 3) == 4
        img1 = img1(:, :, 1:3);
    end
    if ~isa(img1, 'uint8')
        img1 = uint8(img1);
    end
    imgTexture1 = Screen('MakeTexture', VP.window, img1);
    
    % Scale first image to match screen height
    [imgHeight1, imgWidth1, ~] = size(img1);
    scaleFactor1 = VP.windowHeightPix / imgHeight1;
    scaledWidth1 = imgWidth1 * scaleFactor1;
    scaledHeight1 = imgHeight1 * scaleFactor1;
    imgRect1 = [0, 0, scaledWidth1, scaledHeight1];
    imgRect1 = CenterRectOnPoint(imgRect1, VP.windowCenter(1), VP.windowCenter(2));
    
    % Load second image
    img2 = imread(imagePath2);
    if size(img2, 3) == 1
        img2 = repmat(img2, [1, 1, 3]);
    elseif size(img2, 3) == 4
        img2 = img2(:, :, 1:3);
    end
    if ~isa(img2, 'uint8')
        img2 = uint8(img2);
    end
    imgTexture2 = Screen('MakeTexture', VP.window, img2);
    
    % Scale second image to match screen height (maintain aspect ratio)
    [imgHeight2, imgWidth2, ~] = size(img2);
    scaleFactor2 = VP.windowHeightPix / imgHeight2;
    scaledWidth2 = imgWidth2 * scaleFactor2;
    scaledHeight2 = imgHeight2 * scaleFactor2;
    imgRect2 = [0, 0, scaledWidth2, scaledHeight2];
    imgRect2 = CenterRectOnPoint(imgRect2, VP.windowCenter(1), VP.windowCenter(2));
    
    % Load third image
    img3 = imread(imagePath3);
    if size(img3, 3) == 1
        img3 = repmat(img3, [1, 1, 3]);
    elseif size(img3, 3) == 4
        img3 = img3(:, :, 1:3);
    end
    if ~isa(img3, 'uint8')
        img3 = uint8(img3);
    end
    imgTexture3 = Screen('MakeTexture', VP.window, img3);
    
    % Scale third image to match screen height (maintain aspect ratio)
    [imgHeight3, imgWidth3, ~] = size(img3);
    scaleFactor3 = VP.windowHeightPix / imgHeight3;
    scaledWidth3 = imgWidth3 * scaleFactor3;
    scaledHeight3 = imgHeight3 * scaleFactor3;
    imgRect3 = [0, 0, scaledWidth3, scaledHeight3];
    imgRect3 = CenterRectOnPoint(imgRect3, VP.windowCenter(1), VP.windowCenter(2));
catch ME
    sca;
    error('Failed to load images: %s', ME.message);
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

% Clear any remaining key presses after calibration
while KbCheck(-1); end
WaitSecs(0.1); % Small delay to ensure keys are cleared

% Wait for trigger
fprintf('Press ''t'' or ''5'' to start (or ESC to cancel)...\n');
while true
    [keyIsDown, ~, keyCode] = KbCheck(-1);
    if keyIsDown
        if keyCode(KbName('5%')) || keyCode(KbName('t'))
            break;
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
elapsedTime = 0;
while elapsedTime < duration
    % Check for escape
    [keyIsDown, ~, keyCode] = KbCheck(-1);
    if keyIsDown && keyCode(kb.escKey)
        fprintf('Experiment aborted by user.\n');
        break;
    end
    
    elapsedTime = GetSecs - experimentStartTime;
    
    % Draw gray background
    Screen('FillRect', VP.window, VP.backGroundColor);
    
    % Draw appropriate image based on elapsed time
    if elapsedTime < duration1
        % First photo (0-10 seconds)
        Screen('DrawTexture', VP.window, imgTexture1, [], imgRect1);
    elseif elapsedTime < duration1 + duration2
        % Second photo (10-25 seconds)
        Screen('DrawTexture', VP.window, imgTexture2, [], imgRect2);
    else
        % Third photo (25-35 seconds)
        Screen('DrawTexture', VP.window, imgTexture3, [], imgRect3);
    end
    
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

% Close image textures
Screen('Close', imgTexture1);
Screen('Close', imgTexture2);
Screen('Close', imgTexture3);

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

% Store image paths and rects for visualization
pa.imagePath1 = imagePath1;
pa.imageRect1 = imgRect1;
pa.imagePath2 = imagePath2;
pa.imageRect2 = imgRect2;
pa.imagePath3 = imagePath3;
pa.imageRect3 = imgRect3;
pa.duration1 = duration1;
pa.duration2 = duration2;
pa.duration3 = duration3;

save(saveFile, 'pa');
fprintf('Data saved to: %s\n', saveFile);

% Cleanup
sca;
fprintf('Experiment complete!\n');

end

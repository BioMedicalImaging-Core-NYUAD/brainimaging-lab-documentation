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

% Find all images in assets folder
assetsDir = fullfile(scriptDir, 'assets');
if ~exist(assetsDir, 'dir')
    error('Assets folder not found: %s', assetsDir);
end

% Supported image extensions
imageExtensions = {'.png', '.jpg', '.jpeg', '.bmp', '.tif', '.tiff'};

% Find all image files
imageFiles = dir(assetsDir);
imagePaths = {};
for i = 1:length(imageFiles)
    [~, ~, ext] = fileparts(imageFiles(i).name);
    if any(strcmpi(ext, imageExtensions)) && ~imageFiles(i).isdir
        imagePaths{end+1} = fullfile(assetsDir, imageFiles(i).name);
    end
end

% Sort alphabetically for consistent ordering
imagePaths = sort(imagePaths);

if isempty(imagePaths)
    error('No image files found in assets folder: %s', assetsDir);
end

nImages = length(imagePaths);
fprintf('Found %d image(s) in assets folder\n', nImages);

% Duration for each photo (10 seconds each)
photoDuration = 10.0; % seconds per photo
duration = nImages * photoDuration; % total duration

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

% Load all images
imgTextures = cell(nImages, 1);
imgRects = cell(nImages, 1);

try
    for i = 1:nImages
        fprintf('Loading image %d/%d: %s\n', i, nImages, imagePaths{i});
        
        % Load image
        img = imread(imagePaths{i});
        
        % Convert grayscale to RGB
        if size(img, 3) == 1
            img = repmat(img, [1, 1, 3]);
        elseif size(img, 3) == 4
            % Remove alpha channel
            img = img(:, :, 1:3);
        end
        
        % Ensure uint8 format
        if ~isa(img, 'uint8')
            img = uint8(img);
        end
        
        % Create texture
        imgTextures{i} = Screen('MakeTexture', VP.window, img);
        
        % Scale image to match screen height (maintain aspect ratio)
        [imgHeight, imgWidth, ~] = size(img);
        scaleFactor = VP.windowHeightPix / imgHeight;
        scaledWidth = imgWidth * scaleFactor;
        scaledHeight = imgHeight * scaleFactor;
        imgRect = [0, 0, scaledWidth, scaledHeight];
        imgRects{i} = CenterRectOnPoint(imgRect, VP.windowCenter(1), VP.windowCenter(2));
    end
    fprintf('Successfully loaded %d image(s)\n', nImages);
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
    
    % Determine which image to display based on elapsed time
    currentImageIdx = min(floor(elapsedTime / photoDuration) + 1, nImages);
    
    % Draw current image
    Screen('DrawTexture', VP.window, imgTextures{currentImageIdx}, [], imgRects{currentImageIdx});
    
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

% Close all image textures
for i = 1:nImages
    Screen('Close', imgTextures{i});
end

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

% Store image paths and rects for visualization (as cell arrays)
pa.imagePaths = imagePaths;
pa.imageRects = imgRects;
pa.photoDuration = photoDuration;
pa.nImages = nImages;

save(saveFile, 'pa');
fprintf('Data saved to: %s\n', saveFile);

% Cleanup
sca;
fprintf('Experiment complete!\n');

end

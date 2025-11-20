function notMain2()
% NOTMAIN2 - Real-time eye tracking visualization on gray screen
% Shows subject's fixation as connected dots in real time
% Duration: 30 seconds

% Clear workspace and close any open windows
clear all; close all; sca;

% Get script directory
scriptDir = fileparts(mfilename('tfullpath'));

% Add utility folders to path
experimentDir = fullfile(scriptDir, '..');
projectRoot = fullfile(experimentDir, '..', '..');
vpixxPath = fullfile(projectRoot, 'experiments', 'general', 'vpixx-utilities');
addpath(vpixxPath);
addpath(genpath(fullfile(experimentDir, 'utils')));

% Experiment duration
duration = 60.0; % seconds

% Debug configuration (identical to main experiment)
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
    timestamp = datestr(now, 'HHMM');
    pa.eyeFileBase = sprintf('egg2%s', timestamp);
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

% Initialize gaze recording parameters (high frequency for smooth visualization)
pa.gazeSampleInterval = 0.01; % Record 100 times per second (1/100 = 0.01 seconds)
pa.maxGazeSamples = ceil(duration / pa.gazeSampleInterval) + 1000; % Extra buffer
pa.gazeSampleCounter = 0;
pa.data.continuousGazeX = nan(1, pa.maxGazeSamples);
pa.data.continuousGazeY = nan(1, pa.maxGazeSamples);
pa.data.continuousGazeTime = nan(1, pa.maxGazeSamples);
pa.pupilDataAvailable = false;
if pa.eyeTrackingEnabled
    pa.data.continuousPupilArea = nan(1, pa.maxGazeSamples);
end

% Store screen info
pa.screenCenter = VP.windowCenter;
pa.screenWidthPix = VP.windowWidthPix;
pa.screenHeightPix = VP.windowHeightPix;
pa.backGroundColor = VP.backGroundColor;

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
        elseif keyCode(KbName('escape'))
            fprintf('Experiment cancelled.\n');
            sca;
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
fprintf('Starting experiment (30 seconds)...\n');

% Initialize arrays for real-time plotting
gazeX_plot = [];
gazeY_plot = [];

% Main loop
elapsedTime = 0;
vbl = experimentStartTime;

while elapsedTime < duration
    % Check for escape
    [keyIsDown, ~, keyCode] = KbCheck(-1);
    if keyIsDown && keyCode(kb.escKey)
        fprintf('Experiment aborted by user.\n');
        break;
    end
    
    elapsedTime = GetSecs - experimentStartTime;
    
    % Record gaze
    if pa.eyeTrackingEnabled
        pa = record_continuous_gaze(pa, experimentStartTime);
        
        % Update plotting arrays with latest valid sample
        if pa.gazeSampleCounter > 0
            lastX = pa.data.continuousGazeX(pa.gazeSampleCounter);
            lastY = pa.data.continuousGazeY(pa.gazeSampleCounter);
            if ~isnan(lastX) && ~isnan(lastY) && lastX ~= -32768 && lastY ~= -32768
                gazeX_plot(end+1) = lastX;
                gazeY_plot(end+1) = lastY;
            end
        end
    end
    
    % Draw gray background
    Screen('FillRect', VP.window, VP.backGroundColor);
    
    % Draw connected dots (gaze path) if we have data
    if length(gazeX_plot) > 1
        % Draw lines connecting consecutive gaze points
        for i = 1:length(gazeX_plot)-1
            Screen('DrawLine', VP.window, [0 0 255], ... % Blue color
                gazeX_plot(i), gazeY_plot(i), ...
                gazeX_plot(i+1), gazeY_plot(i+1), 2);
        end
        
        % Draw dots at each gaze point
        if length(gazeX_plot) > 0
            Screen('DrawDots', VP.window, [gazeX_plot; gazeY_plot], ...
                5, [255 0 0], [], 2); % Red dots, 5 pixels radius
        end
    end
    
    % Flip
    vbl = Screen('Flip', VP.window, vbl + 0.5 * VP.ifi);
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

% Save data with timestamp
timestampFull = datestr(now, 'yyyymmdd_HHMMSS');
saveFile = fullfile(scriptDir, 'results', sprintf('egg2_%s.mat', timestampFull));
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

save(saveFile, 'pa');
fprintf('Data saved to: %s\n', saveFile);

% Cleanup
sca;
fprintf('Experiment complete!\n');

end


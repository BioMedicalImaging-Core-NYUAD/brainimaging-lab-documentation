function minimal_eyetracking_test()
% MINIMAL_EYETRACKING_TEST - Simplified 30-second resting state with eye tracking
% Uses VRI's exact eye tracking methods with template naming conventions

clear all; close all; sca;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONFIGURATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PA = struct();
PA.experimentDuration = 30;  % seconds
PA.blinkSecThresh = 5;       % seconds for blink alarm

% Eye tracking file setup
PA.eyeDataDir = fullfile(pwd, 'eyetracking_data');
if ~exist(PA.eyeDataDir, 'dir'), mkdir(PA.eyeDataDir); end
base = datestr(now,'mmddHHMM');
PA.eyeFileBase = base(1:min(end,8));
PA.eyeFileName = [PA.eyeFileBase '.edf'];

% Fixation dot parameters
PA.fixationRadius_px = 10;   % radius of fixation dot in pixels

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETUP SCREEN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Screen('Preference', 'SkipSyncTests', 1);
screens = Screen('Screens');
screenNumber = max(screens);
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
gray = white / 2;

% Open window WITHOUT imaging pipeline features that might cause issues
[window, windowRect] = Screen('OpenWindow', screenNumber, gray);
[screenXpixels, screenYpixels] = Screen('WindowSize', window);
[xCenter, yCenter] = RectCenter(windowRect);
ifi = Screen('GetFlipInterval', window);

VP = struct();
VP.window = window;
VP.ifi = ifi;
VP.white = white;
VP.gray = gray;
PA.screenCenter = [xCenter, yCenter];

fprintf('Screen opened: %d x %d pixels\n', screenXpixels, screenYpixels);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ADD EYETRACKING PATH
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
eyetrackingDir = fullfile(fileparts(mfilename('fullpath')), 'Eyetracking');
addpath(eyetrackingDir);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INITIALIZE EYELINK (VRI method exactly)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try
    % Initialize
    PA.EL = initEyetracking_minimal(VP, PA);
    if isempty(PA.EL)
        fprintf('Eye tracking initialization failed. Exiting.\n');
        sca;
        return;
    end

    % Calibrate
    fprintf('\n=== Starting Calibration ===\n');
    [~, exitFlag] = initEyelinkStates('calibrate', VP.window, PA.EL);
    if exitFlag
        fprintf('Calibration cancelled. Exiting.\n');
        sca;
        return;
    end

    fprintf('\n=== Calibration Complete ===\n');
    fprintf('Press any key to start experiment...\n');
    KbStrokeWait;

    % Start recording
    err = Eyelink('CheckRecording');
    if err ~= 0
        initEyelinkStates('startrecording', VP.window, PA.EL);
        fprintf('Eyelink now recording.\n');
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAIN EXPERIMENT - 30 seconds with continuous eye tracking
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    fprintf('\n=== Starting Experiment ===\n');
    fprintf('Duration: %d seconds\n', PA.experimentDuration);

    experimentStartTime = GetSecs;
    frameCounter = 0;
    blinkCounter = 0;
    blinkFrameThresh = (1/VP.ifi) * PA.blinkSecThresh;

    Eyelink('message', 'EXPERIMENT_START');
    vbl = Screen('Flip', VP.window);

    while (GetSecs - experimentStartTime) < PA.experimentDuration
        % Draw fixation dot
        Screen('DrawDots', VP.window, PA.screenCenter, PA.fixationRadius_px, VP.white, [], 2);

        % Flip
        vbl = Screen('Flip', VP.window, vbl + 0.5 * VP.ifi);

        % Continuous eye tracking monitoring (VRI method)
        evt = Eyelink('newestfloatsample');
        xPos = evt.gx;
        yPos = evt.gy;

        % Blink detection
        if isequal(xPos(1), xPos(2), yPos(1), yPos(2))
            blinkCounter = blinkCounter + 1;
            if blinkCounter >= blinkFrameThresh
                % Alarm threshold reached (could play beep here)
            end
        else
            blinkCounter = 0;
        end

        frameCounter = frameCounter + 1;

        % Check for ESC to abort
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown && keyCode(KbName('ESCAPE'))
            fprintf('\nExperiment aborted by user.\n');
            break;
        end
    end

    Eyelink('message', 'EXPERIMENT_END');

    fprintf('\n=== Experiment Complete ===\n');
    fprintf('Total frames: %d\n', frameCounter);
    fprintf('Total time: %.2f seconds\n', GetSecs - experimentStartTime);

    % Stop and save eye tracking
    fprintf('\nSaving eye tracking data...\n');
    if ~exist(PA.eyeDataDir, 'dir'), mkdir(PA.eyeDataDir); end
    initEyelinkStates('eyestop', VP.window, {PA.eyeFileBase, PA.eyeDataDir});
    fprintf('Eye tracking data saved.\n');

catch ME
    fprintf('\n!!! ERROR !!!\n');
    fprintf('%s\n', ME.message);
    if ~isempty(ME.stack)
        fprintf('In %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
    end
end

% Cleanup
sca;
fprintf('\nDone.\n');

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MINIMAL EYETRACKING INIT (VRI method exactly)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function EL = initEyetracking_minimal(VP, PA)
    [EL, exitFlag] = initEyelinkStates('eyestart', VP.window, {PA.eyeFileBase, PA});
    if exitFlag
        EL = [];
        return;
    end

    EL.eyeDataDir = PA.eyeDataDir;
    EL.eyeFile = PA.eyeFileBase;
end

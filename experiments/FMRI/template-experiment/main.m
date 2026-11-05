function main()
% MAIN - Button-pressing experiment with circular path and traveling dot
%
% Participants view a circular path with a continuously traveling dot. During
% stimulus presentation, the circular path changes to a target color (white,
% red, yellow, green, or blue). Participants press the corresponding button
% for the color they see.
%
% What do you see:
% - Circular path: Black during non-stimulus phases, changes to target color during stimulus
% - Traveling dot: Continuously moves along path; changes color for feedback

%
% Trial structure:
% 1. Stimulus: Circular path displays target color
% 2. Response: Participant responds while path returns to black
% 3. Feedback: Traveling dot changes color to  indicate correctness
% 4. Inter-trial interval: Brief pause before next trial
%
% All timing and visual parameters are configurable in setup_param.m

% Clear workspace and close any open windows
clear all; close all; sca;

% Add the shared VPixx utilities (getButtonColor) to the path.
% Search upwards from this file for experiments/general/vpixx-utilities so the
% experiment keeps working wherever its folder sits in the repo (a fixed
% '..' depth broke when the template moved from tests/ to experiments/FMRI/).
scriptDir = fileparts(mfilename('fullpath'));
vpixxPath = '';
searchDir = scriptDir;
for level = 1:6
    candidate = fullfile(searchDir, 'experiments', 'general', 'vpixx-utilities');
    if exist(candidate, 'dir')
        vpixxPath = candidate;
        break;
    end
    searchDir = fileparts(searchDir);
end
if isempty(vpixxPath)
    warning('main:vpixxPath', ['experiments/general/vpixx-utilities not found; ' ...
        'the button box will not work (keyboard fallback).']);
else
    addpath(vpixxPath);
end

% Add local utility folders to path
addpath(genpath(fullfile(scriptDir, 'utils')));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEBUG CONFIGURATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Centralized debug settings - modify these to control experiment behavior
debugConfig = struct();
debugConfig.enabled = 1;              % 1 = debug mode, 0 = production mode
debugConfig.useVPixx = 1;             % 1 = use VPixx hardware, 0 = use keyboard
debugConfig.fullscreen = 1;            % 1 = fullscreen, 0 = windowed mode
debugConfig.skipSyncTests = 1;       % 1 = skip sync tests, 0 = run sync tests
debugConfig.displayMode = 1;          % 1 = NYUAD lab, 2 = laptop/development
debugConfig.manualTrigger = 1;        % 1 = manual trigger (5 or t), 0 = scanner trigger
debugConfig.buttonbox = 1;        % 1 = button box, 0 = keyboard
debugConfig.eyetracking = 0;       % 1 = enable Eyelink, 0 = disable

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GET BIDS INFORMATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
experimentDir = scriptDir;
try
    debugConfig.bidsInfo = get_info(experimentDir, 'circularpath');
catch ME
    if contains(ME.message, 'cancelled') || contains(ME.message, 'not to overwrite')
        fprintf('Exiting.\n');
        return;
    end
    rethrow(ME);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETUP DISPLAY AND EXPERIMENT PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Setup display with debug configuration
[VP, debugConfig] = setup_display(debugConfig);

% Setup experiment parameters
[VP, pa] = setup_param(VP, debugConfig);

% Setup keyboard mappings
kb = setup_keyboard();

% Initialize eyetracking (following reference pattern exactly)
if debugConfig.eyetracking
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

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% START EXPERIMENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try
    % Calibration (following reference pattern - called before experiment starts)
    if pa.eyeTrackingEnabled
        [~, exitFlag] = initEyelinkStates('calibrate', VP.window, pa.EL);
        if exitFlag
            fprintf('\nCalibration failed or was cancelled. Disabling eye tracking.\n');
            pa.EL = [];
            pa.eyeTrackingEnabled = 0;
        end
    end

    % Wait for scanner trigger or manual trigger (displays message on screen).
    % The trigger time is time zero: every phase is scheduled from it
    % (see start_phase), and all logged onsets are relative to it.
    experimentStartTime = wait_trigger(VP, debugConfig.manualTrigger);
    if pa.eyeTrackingEnabled
        err = Eyelink('CheckRecording');
        if err ~= 0
            initEyelinkStates('startrecording', VP.window, pa.EL);
            fprintf('Eyelink now recording ..\n');
        end
    end

    % Initialize gaze sample timing (subtract interval so first sample is recorded immediately)
    pa.lastGazeSampleTime = experimentStartTime - pa.gazeSampleInterval;
    fprintf('\n=== %s ===\n', pa.experimentName);

    % Initialize fixation angle (starts at 0 radians)
    currentFixationAngle = 0;

    % Setup KbQueue once for efficient button detection throughout experiment
    KbQueueCreate();
    KbQueueStart();

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % START EXPERIMENT (moving dot only, before first trial)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [pa, exitFlag, currentFixationAngle] = s1_startExp(VP, pa, kb, experimentStartTime, currentFixationAngle);
    % ESC during the start period: skip the trials but still reach cleanup below
    % (a 'return' here used to skip cleanup: window left open, data not saved)
    nTrialsToRun = pa.nTrials;
    if exitFlag, nTrialsToRun = 0; end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % MAIN EXPERIMENT LOOP
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % Main trial-based loop - run exactly pa.nTrials trials
    for trialIdx = 1:nTrialsToRun
        pa.trialCounter = pa.trialCounter + 1;

        % Check for ESC key to abort experiment using KbQueue
        [pressed, firstPress] = KbQueueCheck();
        if pressed && firstPress(kb.escKey)
            fprintf('\n*** Experiment terminated by user (ESC pressed) ***\n');
            break;
        end

        % Get target color from predefined sequence
        targetColor = pa.colorSequence{trialIdx};

        % Store trial data (use direct indexing with pre-allocated arrays)
        pa.data.trialNumber(pa.trialCounter) = pa.trialCounter;
        pa.data.targetColor{pa.trialCounter} = targetColor;
        % trialStartTime / cumulativeTime are set in s2_stimulus from the actual
        % onset of the stimulus frame (seconds from the trigger)
        pa.data.fixationAngle(pa.trialCounter) = currentFixationAngle;

        fprintf('Trial %d/%d: Target = %s\n', pa.trialCounter, pa.nTrials, targetColor);

        % Phase 1: Stimulus
        targetIdx = find(strcmp(targetColor, pa.colors));
        [pa, exitFlag, currentFixationAngle] = s2_stimulus(VP, pa, kb, experimentStartTime, currentFixationAngle, targetColor, targetIdx);
        if exitFlag, break; end

        % Phase 2: Response
        [pa, exitFlag, currentFixationAngle, responseReceived, responseButton, responseTime] = s3_response(VP, pa, kb, experimentStartTime, currentFixationAngle, debugConfig);
        if exitFlag, break; end

        % Record response data
        if responseReceived
            pa.data.response{pa.trialCounter} = responseButton;
            pa.data.reactionTime(pa.trialCounter) = responseTime;
            pa.data.correct(pa.trialCounter) = strcmp(responseButton, targetColor);
        else
            pa.data.response{pa.trialCounter} = 'no_response';
            pa.data.reactionTime(pa.trialCounter) = NaN;
            pa.data.correct(pa.trialCounter) = 0;
        end

        % Phase 3: Feedback
        [pa, exitFlag, currentFixationAngle] = s4_feedback(VP, pa, kb, experimentStartTime, currentFixationAngle, responseReceived, pa.data.correct(pa.trialCounter));
        if exitFlag, break; end

        % Phase 4: ITI
        [pa, exitFlag, currentFixationAngle] = s5_iti(VP, pa, kb, experimentStartTime, currentFixationAngle);
        if exitFlag, break; end

        % Print trial result
        if responseReceived
            fprintf('  Response: %s, RT: %.3fs, Correct: %d\n', ...
                responseButton, responseTime, pa.data.correct(pa.trialCounter));
        else
            fprintf('  No response received\n');
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % END EXPERIMENT
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % End screen (skipped after ESC)
    if ~exitFlag
        [pa, ~, ~] = s6_endScreen(VP, pa, kb, experimentStartTime, currentFixationAngle);
    end

catch ME
    % Error occurred - display detailed message
    fprintf('\n!!! ERROR OCCURRED !!!\n');
    fprintf('Error message: %s\n', ME.message);
    if ~isempty(ME.stack)
        fprintf('Error in: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
        % Print full stack trace
        fprintf('\nStack trace:\n');
        for i = 1:length(ME.stack)
            fprintf('  %d. %s (line %d)\n', i, ME.stack(i).name, ME.stack(i).line);
        end
    end
end

% Cleanup and finalize experiment (always executed)
% Check if experimentStartTime was defined before calling cleanup
if exist('experimentStartTime', 'var')
    cleanup_experiment(VP, pa, kb, experimentStartTime);
else
    % If experiment never started, use current time as fallback
    cleanup_experiment(VP, pa, kb, GetSecs);
end

end
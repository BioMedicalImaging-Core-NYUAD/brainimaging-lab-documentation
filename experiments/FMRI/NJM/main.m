function main(mode, opts)
% MAIN - Navigating the Job Market (NJM) fMRI task: one functional run per call
%
%   main                 one scanner run (a dialog asks for subject, session and run 1-4)
%   main('practice')     practice trials (mock scanner / before run 1); not part of the 48 trials
%   main(mode, opts)     no dialog and/or other settings, e.g. for testing:
%                        opts.subjectID, opts.sessionID, opts.runID, opts.overwrite,
%                        opts.debug = struct with any debugConfig field
%
% The task: on every trial the participant sees two job offers from two
% employer families (Offer A left, Offer B right) in three steps:
%   Phase 1 - employer photos + family background
%   Phase 2 - full offers: salary, off days, workload
%   Phase 3 - "Which job offer do you choose?" with four buttons
%             (1 Definitely A, 2 Probably A, 3 Probably B, 4 Definitely B)
% with a fixation cross between the steps and between trials.
%
% A session is 4 runs of 12 trials. Trial order, left/right position, faces
% and jitter are randomised per participant (utils/setup/make_subject_design.m)
% and saved in the participant's data folder, so the 4 runs belong together.
%
% Every setting of the task (timing, texts, layout, response mapping) is in
% stimuli_data/njm_fmri_parameters.json. Related scripts in this folder:
%   practice.m, njm_payout.m, njm_playback.m, njm_preview_screens.m, njm_check_design.m

if nargin < 1 || isempty(mode), mode = 'task'; end
if nargin < 2 || isempty(opts), opts = struct(); end

close all; sca;

% Add the shared VPixx utilities (getButtonColor) to the path.
% Search upwards from this file for experiments/general/vpixx-utilities so the
% experiment keeps working wherever its folder sits in the repo.
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
debugConfig.fullscreen = 1;           % 1 = fullscreen, 0 = windowed mode
debugConfig.skipSyncTests = 1;        % 1 = skip sync tests, 0 = run sync tests
debugConfig.displayMode = 1;          % 1 = NYUAD lab, 2 = laptop/development
debugConfig.manualTrigger = 1;        % 1 = manual trigger (5 or t), 0 = scanner trigger
debugConfig.buttonbox = 1;            % 1 = button box (right VPixx box), 0 = keyboard keys 1-4
debugConfig.eyetracking = 0;          % 1 = enable Eyelink, 0 = disable
debugConfig.sendMarkers = 0;          % 1 = send event codes on the VPixx digital output (physiology recorder)
debugConfig.doutMapping = 'direct';   % 'direct' or 'spread' (see utils/setup/send_event.m)
debugConfig.showInstructions = 1;     % 1 = instruction screens before the trigger, 0 = none
debugConfig.autoRespond = 0;          % TEST ONLY: 1 = simulated participant, no trigger wait
debugConfig.timeScale = 1;            % TEST ONLY: < 1 runs the task faster (0.1 = ten times faster)

% For the scanner session set:  manualTrigger = 0, and eyetracking / sendMarkers as needed.
% For a laptop set:             useVPixx = 0, displayMode = 2, buttonbox = 0 (fullscreen = 0 for a window).

% Settings passed in opts.debug win over the ones above
if isfield(opts, 'debug') && isstruct(opts.debug)
    names = fieldnames(opts.debug);
    for i = 1:numel(names)
        debugConfig.(names{i}) = opts.debug.(names{i});
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GET BIDS INFORMATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
experimentDir = scriptDir;
try
    debugConfig.bidsInfo = get_info(experimentDir, mode, opts);
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

try
    % Setup experiment parameters (JSON, this participant's design, stimuli)
    [VP, pa] = setup_param(VP, debugConfig);
catch ME
    sca;
    rethrow(ME);
end

% Setup keyboard mappings
kb = setup_keyboard(pa);

% Initialize eyetracking
if debugConfig.eyetracking
    pa.EL = initEyetracking(VP, pa);
    if isempty(pa.EL)
        pa.eyeTrackingEnabled = false;
    else
        pa.eyeTrackingEnabled = true;
        try
            Eyelink('Command', 'sample_rate = %d', pa.P.eyetracking.sampling_rate_hz);
            Eyelink('Message', 'DISPLAY_COORDS %d %d %d %d', 0, 0, VP.Rect(3) - 1, VP.Rect(4) - 1);
        catch
        end
    end
else
    pa.EL = [];
    pa.eyeTrackingEnabled = false;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% START EXPERIMENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
exitFlag = false;
try
    % Calibration (before the run starts)
    if pa.eyeTrackingEnabled
        [~, calFailed] = initEyelinkStates('calibrate', VP.window, pa.EL);
        if calFailed
            fprintf('\nCalibration failed or was cancelled. Disabling eye tracking.\n');
            pa.EL = [];
            pa.eyeTrackingEnabled = false;
        end
    end

    % Instructions (the experimenter turns the pages: SPACE = next, B = back)
    if debugConfig.showInstructions && ~debugConfig.autoRespond
        I = pa.P.instructions;
        runNumber = pa.bidsInfo.runNumber;
        if strcmp(pa.mode, 'practice')
            pages = [I.task_pages(:)', {I.practice_intro}];
        elseif runNumber == 1
            pages = [I.task_pages(:)', {sprintf(I.run_reminder, runNumber, pa.nRuns)}];
        else
            pages = {sprintf(I.run_reminder, runNumber, pa.nRuns)};
        end
        exitFlag = show_text_screen(VP, pa, kb, pages, 'key');
    end

    if ~exitFlag
        % Wait for scanner trigger or manual trigger (displays message on screen).
        % The trigger time is time zero: every screen is scheduled from it
        % (see present_screen), and all logged onsets are relative to it.
        experimentStartTime = wait_trigger(VP, debugConfig.manualTrigger, debugConfig.autoRespond);
        pa.t0 = experimentStartTime;

        if pa.eyeTrackingEnabled
            err = Eyelink('CheckRecording');
            if err ~= 0
                initEyelinkStates('startrecording', VP.window, pa.EL);
                fprintf('Eyelink now recording ..\n');
            end
        end
        pa = send_event(pa, 'RUN_START', experimentStartTime, 0);

        % Setup KbQueue once for button detection throughout the run
        KbQueueCreate();
        KbQueueStart();

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % LEAD-IN FIXATION (the first trial's screens are prepared meanwhile)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        [pa, o] = present_screen(VP, pa, kb, [], NaN, pa.sched(1).phase1, ...
            struct('event', 'PRETRIAL_FIXATION', 'prepTrial', 1));
        exitFlag = o.esc;

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % MAIN EXPERIMENT LOOP
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        for k = 1:pa.nTrials
            if exitFlag, break; end
            [pa, exitFlag] = run_trial(VP, pa, kb, k);

            if pa.data.timeout(k)
                fprintf('Trial %2d/%d  %-15s  no response\n', k, pa.nTrials, pa.trials(k).kind);
            elseif pa.data.completed(k)
                fprintf('Trial %2d/%d  %-15s  %-26s RT %.2f s\n', k, pa.nTrials, pa.trials(k).kind, ...
                    pa.data.response_label{k}, pa.data.reaction_time(k));
            end
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % END OF RUN
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        if exitFlag
            fprintf('\n*** Run stopped by the experimenter (ESC) ***\n');
            pa.aborted = true;
        else
            pa.currentTrial = 0;
            pa.measuredRunDuration = (GetSecs - pa.t0) / pa.timeScale;
            pa = send_event(pa, 'RUN_END', GetSecs, pa.runEnd);
            if strcmp(pa.mode, 'task') && pa.bidsInfo.runNumber == pa.nRuns
                endText = pa.P.instructions.end_of_session;
            else
                endText = pa.P.instructions.end_of_run;
            end
            if debugConfig.autoRespond
                show_text_screen(VP, pa, kb, endText, 0.5);
            else
                show_text_screen(VP, pa, kb, endText, 5);
            end
        end
    else
        pa.aborted = true;
    end

catch ME
    % Error occurred - display detailed message
    pa.aborted = true;
    fprintf('\n!!! ERROR OCCURRED !!!\n');
    fprintf('Error message: %s\n', ME.message);
    if ~isempty(ME.stack)
        fprintf('Error in: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
        fprintf('\nStack trace:\n');
        for i = 1:length(ME.stack)
            fprintf('  %d. %s (line %d)\n', i, ME.stack(i).name, ME.stack(i).line);
        end
    end
    pa.errorMessage = ME.message;
end

% Cleanup and save (always executed)
if exist('experimentStartTime', 'var')
    cleanup_experiment(VP, pa, kb, experimentStartTime);
else
    cleanup_experiment(VP, pa, kb, GetSecs);
end

end

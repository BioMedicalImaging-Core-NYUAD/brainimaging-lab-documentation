function [VP, pa] = setup_param(VP, debugConfig)
% SETUP_PARAM - Set up the NJM run: parameters, this participant's design, stimuli
%
% Inputs:
%   VP          - Viewing Parameters structure from setup_display
%   debugConfig - Debug configuration structure (with debugConfig.bidsInfo from get_info)
%
% Outputs:
%   VP - unchanged
%   pa - Parameters structure:
%        pa.P        everything in stimuli_data/njm_fmri_parameters.json
%        pa.design   this run's trials (table) with planned onsets
%        pa.trials   the same trials as a struct array with the display texts
%        pa.sched    planned onsets in seconds from the trigger (already multiplied by timeScale)
%        pa.L, pa.sizes, pa.colors   layout in pixels, text sizes, colours
%        pa.tex      textures (faces, icons)
%        pa.data     per-trial results, filled during the run
%        pa.log      every event with planned and actual time
%
% All task settings live in the JSON file; nothing is hard-coded here.

if ~isstruct(VP) || ~all(isfield(VP, {'window', 'windowCenter', 'pixelsPerDegree', 'ifi'}))
    error('setup_param:invalidInput', 'VP must come from setup_display');
end
if ~isstruct(debugConfig) || ~isfield(debugConfig, 'bidsInfo') || isempty(debugConfig.bidsInfo)
    error('setup_param:invalidInput', 'debugConfig.bidsInfo is required (see get_info)');
end

info = debugConfig.bidsInfo;
scriptDir = fileparts(mfilename('fullpath'));
experimentDir = fullfile(scriptDir, '..', '..');           % utils/setup -> NJM

cfg = njm_load_config(experimentDir, info.mode);
P = cfg.P;

pa = struct();
pa.P = P;
pa.mode = info.mode;
pa.bidsInfo = info;
pa.experimentName = P.study.experiment_name;
pa.dataDir = info.dataDir;
pa.dataFileName = info.fullPath;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% THIS PARTICIPANT'S DESIGN (made once per session, then re-used by every run)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if exist(info.designPath, 'file')
    full = readtable(info.designPath, 'Delimiter', ',', 'TextType', 'char');
    fprintf('Design loaded: %s\n', info.designPath);
else
    full = make_subject_design(cfg, info.subjectID, info.sessionID);
    writetable(full, info.designPath);
    fprintf('Design created: %s\n', info.designPath);
end
nRuns = max(full.run);
if info.runNumber > nRuns
    error('setup_param:run', 'Run %d does not exist (this design has %d run(s))', info.runNumber, nRuns);
end
pa.nRuns = nRuns;
pa.nTrialsSession = height(full);
pa.design = full(full.run == info.runNumber, :);
pa.nTrials = height(pa.design);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TIMING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% timeScale < 1 compresses the whole run (testing only). Saved onsets are
% converted back to real task time, so test output looks like a real run.
pa.timeScale = get_field(debugConfig, 'timeScale', 1);
ts = pa.timeScale;
d = pa.design;
pa.sched = struct('fixation', num2cell(d.onset_fixation * ts), 'phase1', num2cell(d.onset_phase1 * ts), ...
    'gap1', num2cell(d.onset_gap1 * ts), 'phase2', num2cell(d.onset_phase2 * ts), ...
    'gap2', num2cell(d.onset_gap2 * ts), 'phase3', num2cell(d.onset_phase3 * ts), ...
    'iti', num2cell(d.onset_iti * ts), 'trialEnd', num2cell(d.trial_end * ts));
pa.runDuration = d.run_duration(1);                           % seconds, real task time
pa.runEnd = pa.runDuration * ts;
pa.feedbackDuration = P.timing.selection_feedback_s * ts;
pa.phase3Window = P.timing.phase3_decision_max_s;
pa.nVolumes = ceil(pa.runDuration / P.timing.tr_s) + P.timing.extra_volumes_after_design;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DISPLAY: LAYOUT, TEXTS, TEXTURES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[pa.L, pa.sizes, pa.colors] = njm_layout(VP, P);
pa.trials = njm_trial_structs(P, pa.design, pa.nTrialsSession);
pa.tex = njm_load_textures(VP, cfg, [pa.design.A_face; pa.design.B_face]);
pa.screenTex = [];                                            % pre-rendered screens of the coming trial
pa.screenTrial = 0;
Screen('TextFont', VP.window, pa.sizes.font);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RESPONSES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
R = P.response;
pa.resp.labels = R.labels(:)';
pa.resp.choice = R.choice(:)';
pa.resp.confidence = R.confidence(:)';
pa.resp.vpixxColors = R.vpixx_colors_PLACEHOLDER(:)';         % button 1-4 -> colour on the response box
pa.resp.vpixxSelection = struct(strrep(R.vpixx_box, ' ', '_'), {pa.resp.vpixxColors});
pa.useButtonBox = logical(get_field(debugConfig, 'buttonbox', 0)) && logical(get_field(debugConfig, 'useVPixx', 0));
if pa.useButtonBox && exist('getButtonColor', 'file') ~= 2
    warning('setup_param:buttonBox', 'getButtonColor.m is not on the path: button box disabled, keyboard keys 1-4 only.');
    pa.useButtonBox = false;
end

% Simulated participant (testing): choices and response times drawn in advance
pa.autoRespond = logical(get_field(debugConfig, 'autoRespond', 0));
pa.auto = njm_simulated_responses(P, pa.design, njm_seed(info.subjectID, info.sessionID, 'auto') + info.runNumber, ts);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EVENT MARKERS (physiology recorder / eye tracker)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pa.codes = cfg.codes;
pa.sendMarkers = logical(get_field(debugConfig, 'sendMarkers', 0)) && logical(get_field(debugConfig, 'useVPixx', 0));
pa.doutMapping = get_field(debugConfig, 'doutMapping', 'direct');   % 'direct' or 'spread' (see send_event)
pa.doutResetAt = 0;
if pa.sendMarkers
    try
        if ~Datapixx('IsReady'), Datapixx('Open'); end
        Datapixx('SetDoutValues', 0);
        Datapixx('RegWrRd');
    catch ME
        warning('setup_param:markers', 'VPixx digital output not available (%s): markers disabled.', ME.message);
        pa.sendMarkers = false;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EYE TRACKING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pa.eyeTrackingEnabled = logical(get_field(debugConfig, 'eyetracking', 0));
pa.eyeDataDir = info.dataDir;
pa.eyeFileBase = info.eyeFileBase;
pa.eyeFileName = [pa.eyeFileBase '.edf'];
pa.EL = [];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
n = pa.nTrials;
pa.data = struct();
pa.data.completed = false(n, 1);
pa.data.onset_phase1 = nan(n, 1);      % actual onsets, seconds from the trigger
pa.data.onset_gap1 = nan(n, 1);
pa.data.onset_phase2 = nan(n, 1);
pa.data.onset_gap2 = nan(n, 1);
pa.data.onset_phase3 = nan(n, 1);
pa.data.onset_fixation_after = nan(n, 1);
pa.data.response_button = nan(n, 1);
pa.data.reaction_time = nan(n, 1);
pa.data.timeout = false(n, 1);
pa.data.choice = repmat({'n/a'}, n, 1);
pa.data.confidence = repmat({'n/a'}, n, 1);
pa.data.response_label = repmat({'n/a'}, n, 1);
pa.data.catch_pass = nan(n, 1);
pa.trialCounter = 0;                   % trials completed
pa.currentTrial = 0;
pa.log = struct('trial', {}, 'event', {}, 'code', {}, 'planned', {}, 'actual', {}, 'delay', {});
pa.t0 = NaN;                           % GetSecs time of the trigger, set in main
pa.aborted = false;

pa.debugMode = get_field(debugConfig, 'enabled', 0);
pa.useVPixx = logical(get_field(debugConfig, 'useVPixx', 0));
pa.useScannerTrigger = ~get_field(debugConfig, 'manualTrigger', 1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SUMMARY FOR THE OPERATOR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('\n=== %s ===\n', pa.experimentName);
fprintf('sub-%s  ses-%s  %s  run %d of %d  (%d trials)\n', info.subjectID, info.sessionID, pa.mode, info.runNumber, nRuns, n);
fprintf('Run length: %.1f s (%.2f min)  ->  scanner: at least %d volumes at TR %.2f s\n', ...
    pa.runDuration, pa.runDuration / 60, pa.nVolumes, P.timing.tr_s);
fprintf('Responses: %s | markers: %d | eye tracking: %d\n', ...
    ternary(pa.useButtonBox, 'VPixx right box + keyboard 1-4', 'keyboard 1-4'), pa.sendMarkers, pa.eyeTrackingEnabled);
if pa.timeScale ~= 1
    fprintf('*** TEST MODE: time scale %.3f (run takes %.1f s) ***\n', pa.timeScale, pa.runEnd);
end
if pa.autoRespond
    fprintf('*** TEST MODE: simulated participant ***\n');
end

end

%--------------------------------------------------------------------------
function v = get_field(s, name, default)
if isfield(s, name) && ~isempty(s.(name)), v = s.(name); else, v = default; end
end

%--------------------------------------------------------------------------
function out = ternary(cond, a, b)
if cond, out = a; else, out = b; end
end

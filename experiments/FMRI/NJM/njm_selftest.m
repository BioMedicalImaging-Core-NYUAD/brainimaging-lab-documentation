function ok = njm_selftest(timeScale)
% NJM_SELFTEST - Run the whole NJM session with a simulated participant and check the output
%
% Runs, in a window on this computer and faster than real time: the practice
% run, the four scanner runs, the payout lottery and the playback, all for the
% test participant sub-9999 (ses-01). Then checks the saved files: every
% trial done, events files complete, onsets on schedule. Run it after any
% change to the task, the JSON or the stimuli.
%
%   njm_selftest          10 x faster than real time (about 3 minutes)
%   njm_selftest(1)       real time (about 25 minutes)
%
% No scanner, button box or eye tracker is used. Existing sub-9999 files are replaced.

if nargin < 1, timeScale = 0.1; end
scriptDir = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(scriptDir, 'utils')));
sub = '9999'; ses = '01';
dataDir = fullfile(scriptDir, 'data', 'exp', ['sub-' sub], ['ses-' ses]);
if exist(dataDir, 'dir')                                  % start clean: the test participant only
    old = dir(fullfile(dataDir, ['sub-' sub '_ses-' ses '_task-njm*']));
    for i = 1:numel(old), delete(fullfile(old(i).folder, old(i).name)); end
end

dbg = struct('enabled', 1, 'useVPixx', 0, 'fullscreen', 0, 'skipSyncTests', 2, 'displayMode', 2, 'manualTrigger', 1, ...
    'buttonbox', 0, 'eyetracking', 0, 'sendMarkers', 0, 'showInstructions', 0, 'autoRespond', 1, 'timeScale', timeScale);
base = struct('subjectID', sub, 'sessionID', ses, 'overwrite', true, 'debug', dbg);

o = base; o.runID = '1';
main('practice', o);
cfg = njm_load_config(scriptDir, 'task');
nRuns = cfg.P.session.n_runs;
for r = 1:nRuns
    o = base; o.runID = num2str(r);
    main('task', o);
end
% payout: scanner lottery + online lottery from a (made-up) file of online choices, then the "already drawn" path
onlineFile = fullfile(tempdir, 'njm_selftest_online.csv');
fid = fopen(onlineFile, 'w');
fprintf(fid, 'confidence,chosen_salary_aed\n');
for k = 1:24, fprintf(fid, '%s,%d\n', 'definitely', 2500); end
fclose(fid);
result = njm_payout(sub, ses, struct('redraw', true, 'onlineChoices', onlineFile));
again = njm_payout(sub, ses);
njm_playback(sub, ses, struct('runs', 1, 'autoAdvance', 0.15, 'debug', struct('fullscreen', 0, 'skipSyncTests', 2)));

%% checks
problems = {};
if ~isequal(again.total_aed, result.total_aed) || ~strcmp(again.drawn_at, result.drawn_at), problems{end + 1} = 'payout was drawn twice'; end
if ~result.online.drawn || ~ismember(result.online.bonus_aed, [0 39]), problems{end + 1} = 'online lottery'; end

% keyboard response logic (no key is really pressed: a made-up keyboard queue is passed in)
pk = struct('P', cfg.P, 'autoRespond', false, 'useButtonBox', false);
kbT = setup_keyboard(pk);
fp = zeros(1, 256); fp(kbT.responseKeys(3)) = 100.40; fp(kbT.responseKeys(1)) = 100.90; fp(kbT.responseKeys(4)) = 99.0;
[~, got, b, tp] = get_response(pk, kbT, true, fp, 100.0, []);
if ~(got && b == 3 && abs(tp - 100.40) < 1e-9), problems{end + 1} = 'keyboard response logic (earliest key after the onset must win)'; end
[~, got] = get_response(pk, kbT, true, zeros(1, 256), 100.0, []);
if got, problems{end + 1} = 'keyboard response logic (no key pressed)'; end
nTrials = 0; delays = []; nRows = 0; types = {}; nTimeouts = 0;
for r = 1:nRuns
    stem = fullfile(dataDir, sprintf('sub-%s_ses-%s_task-njm_run-%02d', sub, ses, r));
    if ~exist([stem '.mat'], 'file') || ~exist([stem '_events.tsv'], 'file') || ~exist([stem '_events.json'], 'file')
        problems{end + 1} = sprintf('run %d: output file missing', r); continue; %#ok<AGROW>
    end
    S = load([stem '.mat'], 'pa'); pa = S.pa;
    if ~all(pa.data.completed) || pa.aborted, problems{end + 1} = sprintf('run %d: not all trials completed', r); end %#ok<AGROW>
    nTimeouts = nTimeouts + sum(pa.data.timeout);
    if abs(pa.measuredRunDuration - pa.runDuration) > 2.5 * pa.VP.ifi / timeScale
        problems{end + 1} = sprintf('run %d: run lasted %.2f s instead of %.2f s', r, pa.measuredRunDuration, pa.runDuration); %#ok<AGROW>
    end
    nTrials = nTrials + sum(pa.data.completed);
    d = [pa.log.delay]; delays = [delays, d(~isnan(d))]; %#ok<AGROW>

    % measured onsets against the plan (real task time)
    plan = [pa.design.onset_phase1, pa.design.onset_phase2, pa.design.onset_phase3];
    meas = [pa.data.onset_phase1, pa.data.onset_phase2, pa.data.onset_phase3];
    tol = 2.5 * pa.VP.ifi / timeScale;
    if any(abs(meas(:) - plan(:)) > tol)
        problems{end + 1} = sprintf('run %d: an onset is more than 2.5 frames off schedule (max %.0f ms on the clock)', r, 1000 * timeScale * max(abs(meas(:) - plan(:)))); %#ok<AGROW>
    end
    answered = ~pa.data.timeout;
    if any(pa.data.reaction_time(answered) <= 0 | pa.data.reaction_time(answered) > cfg.P.timing.phase3_decision_max_s + tol)
        problems{end + 1} = sprintf('run %d: response time out of range', r); %#ok<AGROW>
    end

    E = readtable([stem '_events.tsv'], 'FileType', 'text', 'Delimiter', '\t', 'TextType', 'char', 'TreatAsMissing', 'n/a');
    nRows = nRows + height(E); types = [types; E.trial_type]; %#ok<AGROW>
    expected = 3 * pa.nTrials + sum(answered);
    if height(E) ~= expected, problems{end + 1} = sprintf('run %d: %d event rows, expected %d', r, height(E), expected); end %#ok<AGROW>
    if any(diff(E.onset) < 0), problems{end + 1} = sprintf('run %d: events not in time order', r); end %#ok<AGROW>
    if E.onset(end) > pa.runDuration, problems{end + 1} = sprintf('run %d: event after the end of the run', r); end %#ok<AGROW>
end
if nTrials ~= cfg.P.session.n_trials_total, problems{end + 1} = sprintf('%d trials completed, expected %d', nTrials, cfg.P.session.n_trials_total); end
if ~exist(fullfile(dataDir, sprintf('sub-%s_ses-%s_task-njmpractice_run-01_events.tsv', sub, ses)), 'file'), problems{end + 1} = 'practice events file missing'; end
if ~isfield(result, 'total_aed') || result.total_aed < cfg.P.payout.fmri_session_fee_aed + cfg.P.payout.travel_allowance_aed, problems{end + 1} = 'payout total'; end

fprintf('\n================ NJM SELF-TEST (time scale %.2f) ================\n', timeScale);
fprintf('Trials completed: %d | event rows: %d (%s)\n', nTrials, nRows, strjoin(cellfun(@(t) sprintf('%s %d', t, sum(strcmp(types, t))), unique(types)', 'UniformOutput', false), ', '));
if ~isempty(delays)
    fprintf('Screen onsets vs schedule on this computer: mean %.1f ms, max %.1f ms late (%d screens)\n', 1000 * mean(delays), 1000 * max(delays), numel(delays));
end
fprintf('Trials without a response (simulated lapses): %d\n', nTimeouts);
fprintf('Payout total: AED %d\n', result.total_aed);
if isempty(problems)
    fprintf('SELF-TEST PASSED\n');
else
    fprintf('SELF-TEST FOUND %d PROBLEM(S):\n', numel(problems)); fprintf('  %s\n', problems{:});
end
ok = isempty(problems);

end

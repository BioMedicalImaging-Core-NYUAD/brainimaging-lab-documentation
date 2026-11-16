function cleanup_experiment(VP, pa, kb, experimentStartTime) %#ok<INUSL>
% CLEANUP_EXPERIMENT - Close devices, print the run summary and save all outputs
%
% Inputs:
%   VP - Viewing Parameters structure
%   pa - Parameters structure
%   kb - Keyboard structure
%   experimentStartTime - GetSecs time of the trigger
%
% Saved in data/exp/sub-<id>/ses-<id>/ (also after ESC or an error):
%   sub-.._ses-.._task-njm_run-0N.mat           everything (pa: design, results, event log, settings)
%   sub-.._ses-.._task-njm_run-0N_events.tsv    BIDS events, one row per phase and per button press
%   sub-.._ses-.._task-njm_run-0N_events.json   column descriptions

% Stop and save Eyelink data
if isfield(pa, 'eyeTrackingEnabled') && pa.eyeTrackingEnabled
    try
        initEyelinkStates('eyestop', VP.window, {pa.eyeFileBase, pa.eyeDataDir});
        edfHere = fullfile(pa.eyeDataDir, [pa.eyeFileBase '.edf']);
        if exist(edfHere, 'file')
            movefile(edfHere, fullfile(pa.eyeDataDir, [pa.bidsInfo.fileName '_eyetrack.edf']));
        end
    catch ME
        fprintf('  Warning: Could not stop Eyelink: %s\n', ME.message);
    end
end

fprintf('\nCleaning up resources...\n');

try
    KbQueueStop();
    KbQueueRelease();
catch
end

% Close Psychtoolbox windows and textures
try
    Priority(0);
    ShowCursor;
    sca;
    fprintf('  Psychtoolbox windows closed\n');
catch ME
    fprintf('  Warning: Could not close Psychtoolbox windows: %s\n', ME.message);
end

% Close VPixx connection
try
    if isfield(pa, 'useVPixx') && pa.useVPixx && Datapixx('IsReady')
        Datapixx('SetDoutValues', 0);
        Datapixx('RegWrRd');
        Datapixx('Close');
        fprintf('  VPixx connection closed\n');
    end
catch ME
    fprintf('  Warning: Could not close VPixx connection: %s\n', ME.message);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RUN SUMMARY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pa.totalExperimentTime = GetSecs - experimentStartTime;
done = pa.data.completed;
nDone = sum(done);
fprintf('\n=== RUN %s ===\n', upper(ternary(pa.aborted, 'stopped early', 'complete')));
fprintf('Trials completed: %d of %d\n', nDone, pa.nTrials);
if nDone > 0
    nTimeout = sum(pa.data.timeout(done));
    rt = pa.data.reaction_time(done & ~pa.data.timeout);
    fprintf('No response: %d of %d (%.0f%%)\n', nTimeout, nDone, 100 * nTimeout / nDone);
    if ~isempty(rt), fprintf('Median response time: %.2f s\n', median(rt)); end
    for b = 1:numel(pa.resp.labels)
        fprintf('  %-26s %d\n', pa.resp.labels{b}, sum(pa.data.response_button(done) == b));
    end
    c = find(done & [pa.trials.isCatch]' == 1);
    for i = 1:numel(c)
        fprintf('Catch trial (trial %d): %s\n', c(i), ternary(pa.data.catch_pass(c(i)) == 1, 'passed', 'FAILED'));
    end
end
if ~isempty(pa.log)
    delays = [pa.log.delay]; delays = delays(~isnan(delays)) * 1000;
    if ~isempty(delays)
        fprintf('Timing: %d scheduled screens, onset delay mean %.1f ms, max %.1f ms (one frame = %.1f ms)\n', ...
            numel(delays), mean(delays), max(delays), VP.ifi * 1000);
    end
end
if isfield(pa, 'measuredRunDuration')
    fprintf('Run length: %.1f s planned, %.1f s measured\n', pa.runDuration, pa.measuredRunDuration);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SAVE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Window and texture handles are meaningless after sca
pa = rmfield_if(pa, {'tex', 'screenTex', 'EL'});
pa.VP = rmfield_if(VP, {'window'});
pa.savedAt = datestr(now, 'yyyy-mm-dd HH:MM:SS');

[saveDir, ~, ~] = fileparts(pa.dataFileName);
if ~exist(saveDir, 'dir'), mkdir(saveDir); end
try
    save(pa.dataFileName, 'pa');
    fprintf('Saved: %s\n', pa.dataFileName);
catch ME
    fprintf('ERROR: Could not save data to %s\n%s\n', pa.dataFileName, ME.message);
end

try
    create_bids_events(pa, pa.bidsInfo);
catch ME
    fprintf('WARNING: Could not create BIDS events files: %s\n', ME.message);
end

% Session so far: exclusion rules of the protocol (catch trials, timeouts)
if strcmp(pa.mode, 'task')
    try
        njm_session_summary(pa.dataDir, pa.bidsInfo.subjectID, pa.bidsInfo.sessionID);
    catch ME
        fprintf('WARNING: Could not summarise the session: %s\n', ME.message);
    end
end

end

%--------------------------------------------------------------------------
function s = rmfield_if(s, names)
for i = 1:numel(names)
    if isfield(s, names{i}), s = rmfield(s, names{i}); end
end
end

%--------------------------------------------------------------------------
function out = ternary(cond, a, b)
if cond, out = a; else, out = b; end
end

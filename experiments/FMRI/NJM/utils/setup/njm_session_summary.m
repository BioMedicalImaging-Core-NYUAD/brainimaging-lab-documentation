function summary = njm_session_summary(dataDir, subjectID, sessionID)
% NJM_SESSION_SUMMARY - Session totals so far and the protocol's exclusion rules
%
% Reads the saved scanner runs of one participant and reports trials done,
% missed responses and catch trials. Protocol: a participant is excluded if
% more than 1 catch trial is failed, or if more than 15 % of trials have no
% response.
%
% Inputs:  dataDir, subjectID, sessionID
% Output:  summary struct (runsFound, nTrials, nTimeout, nCatchFailed, flagTimeouts, flagCatch)

files = dir(fullfile(dataDir, sprintf('sub-%s_ses-%s_task-njm_run-*.mat', subjectID, sessionID)));
files = files(cellfun(@isempty, strfind({files.name}, '_old-'))); %#ok<STRCLFH>
summary = struct('runsFound', [], 'nTrials', 0, 'nTimeout', 0, 'nCatch', 0, 'nCatchFailed', 0, 'flagTimeouts', false, 'flagCatch', false);
P = [];
for i = 1:numel(files)
    S = load(fullfile(files(i).folder, files(i).name), 'pa');
    pa = S.pa; P = pa.P;
    done = pa.data.completed;
    summary.runsFound(end + 1) = pa.bidsInfo.runNumber;
    summary.nTrials = summary.nTrials + sum(done);
    summary.nTimeout = summary.nTimeout + sum(pa.data.timeout(done));
    isCatch = [pa.trials.isCatch]' == 1;
    summary.nCatch = summary.nCatch + sum(done & isCatch);
    summary.nCatchFailed = summary.nCatchFailed + sum(pa.data.catch_pass(done & isCatch) == 0);
end
if isempty(P) || summary.nTrials == 0, return; end

summary.flagTimeouts = summary.nTimeout / summary.nTrials > P.exclusion.max_timeout_fraction;
summary.flagCatch = summary.nCatchFailed > P.exclusion.max_failed_catch_trials;

fprintf('\n=== SESSION SO FAR (sub-%s ses-%s) ===\n', subjectID, sessionID);
fprintf('Runs saved: %s\n', mat2str(sort(summary.runsFound)));
fprintf('Trials: %d | no response: %d (%.0f%%) | catch trials failed: %d of %d\n', summary.nTrials, summary.nTimeout, ...
    100 * summary.nTimeout / summary.nTrials, summary.nCatchFailed, summary.nCatch);
if summary.flagTimeouts
    fprintf('*** EXCLUSION RULE: no response on more than %.0f%% of trials ***\n', 100 * P.exclusion.max_timeout_fraction);
end
if summary.flagCatch
    fprintf('*** EXCLUSION RULE: more than %d catch trial failed ***\n', P.exclusion.max_failed_catch_trials);
end

end

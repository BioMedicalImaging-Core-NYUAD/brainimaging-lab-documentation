function cleanup_experiment(VP, pa, kb, experimentStartTime)
% CLEANUP_EXPERIMENT - Close devices/windows and save task outputs.

fprintf('\nCleaning up resources...\n');

try
    KbQueueStop(-1);
    KbQueueRelease(-1);
catch
end

try
    Priority(0);
catch
end

try
    ListenChar(0);
catch
end

try
    sca;
catch ME
    fprintf('Warning: could not close Psychtoolbox windows: %s\n', ME.message);
end

try
    if isfield(pa, 'useVPixx') && pa.useVPixx && Datapixx('IsReady')
        Datapixx('Close');
    end
catch ME
    fprintf('Warning: could not close VPixx: %s\n', ME.message);
end

if isfield(pa, 'nextEpochOnset') && ~isempty(pa.nextEpochOnset)
    pa.totalDesignTime = pa.nextEpochOnset;
else
    pa.totalDesignTime = NaN;
end
if isfield(pa, 'timingBaseTime') && ~isempty(pa.timingBaseTime)
    pa.wallClockElapsedAtCleanup = GetSecs - pa.timingBaseTime;
else
    pa.wallClockElapsedAtCleanup = GetSecs - experimentStartTime;
end
% Use pre-computed time if set in main (excludes end screen and cleanup)
if ~isfield(pa, 'totalExperimentTime') || isempty(pa.totalExperimentTime)
    if isfinite(pa.totalDesignTime)
        pa.totalExperimentTime = pa.totalDesignTime;
    else
        pa.totalExperimentTime = pa.wallClockElapsedAtCleanup;
    end
end
if isfield(pa, 'textureMap')
    pa = rmfield(pa, 'textureMap');
end

if isfield(pa, 'dataFileName') && ~isempty(pa.dataFileName)
    [saveDir, ~, ~] = fileparts(pa.dataFileName);
    if ~exist(saveDir, 'dir'), mkdir(saveDir); end

    try
        save(pa.dataFileName, 'pa');
        fprintf('Saved MAT data: %s\n', pa.dataFileName);
    catch ME
        fprintf('ERROR: could not save MAT data: %s\n', ME.message);
    end
end

if isfield(pa, 'eventsFileName') && ~isempty(pa.eventsFileName) && ~isempty(pa.events)
    try
        eventsTable = struct2table(pa.events);
        writetable(eventsTable, pa.eventsFileName, 'FileType', 'text', 'Delimiter', '\t');
        fprintf('Saved events TSV: %s\n', pa.eventsFileName);
    catch ME
        fprintf('ERROR: could not save events TSV: %s\n', ME.message);
    end
end

if isfield(pa, 'designMatrixFileName') && ~isempty(pa.designMatrixFileName) && ~isempty(pa.designMatrix)
    try
        dmTable = array2table(pa.designMatrix, 'VariableNames', pa.designMatrixLabels);
        writetable(dmTable, pa.designMatrixFileName);
        fprintf('Saved design matrix CSV: %s\n', pa.designMatrixFileName);
    catch ME
        fprintf('ERROR: could not save design matrix CSV: %s\n', ME.message);
    end
end

fprintf('Cleanup complete. Planned design time: %.2f s\n', pa.totalExperimentTime);
fprintf('Elapsed including cleanup: %.2f s\n', pa.wallClockElapsedAtCleanup);

end

function cleanup_experiment(VP, pa, kb, experimentStartTime)
% CLEANUP_EXPERIMENT - Close devices/windows and save task outputs.

fprintf('\nCleaning up resources...\n');

try
    KbQueueStop();
    KbQueueRelease();
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

pa.totalExperimentTime = GetSecs - experimentStartTime;

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

fprintf('Cleanup complete. Total elapsed time: %.2f s\n', pa.totalExperimentTime);

end

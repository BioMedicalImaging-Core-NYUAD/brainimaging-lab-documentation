function cleanup_experiment(VP, pa, kb, experimentStartTime)
% CLEANUP_EXPERIMENT - Close devices/windows and save task outputs.

fprintf('\nCleaning up resources...\n');

try, KbQueueStop(-1); KbQueueRelease(-1); catch, end
try, Priority(0); catch, end
try, ListenChar(0); catch, end
try, sca; catch ME, fprintf('Warning: %s\n', ME.message); end
try
    if isfield(pa, 'useVPixx') && pa.useVPixx && Datapixx('IsReady')
        Datapixx('Close');
    end
catch, end

% Use pre-computed time if set in main (excludes cleanup overhead)
if ~isfield(pa, 'totalExperimentTime') || isempty(pa.totalExperimentTime)
    pa.totalExperimentTime = GetSecs - experimentStartTime;
end

% Save MAT
if isfield(pa, 'dataFileName') && ~isempty(pa.dataFileName)
    [saveDir, ~, ~] = fileparts(pa.dataFileName);
    if ~exist(saveDir, 'dir'), mkdir(saveDir); end
    try
        save(pa.dataFileName, 'pa');
        fprintf('Saved MAT data: %s\n', pa.dataFileName);
    catch ME
        fprintf('ERROR saving MAT: %s\n', ME.message);
    end
end

% Save events TSV
if isfield(pa, 'eventsFileName') && ~isempty(pa.eventsFileName) && ...
   isfield(pa, 'events') && ~isempty(pa.events)
    try
        eventsTable = struct2table(pa.events);
        writetable(eventsTable, pa.eventsFileName, 'FileType', 'text', 'Delimiter', '\t');
        fprintf('Saved events TSV: %s\n', pa.eventsFileName);
    catch ME
        fprintf('ERROR saving TSV: %s\n', ME.message);
    end
end

% Save events JSON
if isfield(pa, 'eventsJSONFileName') && ~isempty(pa.eventsJSONFileName)
    try
        eventsJSON = struct();
        eventsJSON.onset.Description = 'Onset in seconds from first trigger';
        eventsJSON.onset.Units = 'seconds';
        eventsJSON.duration.Description = 'Duration of the checkerboard flash';
        eventsJSON.duration.Units = 'seconds';
        eventsJSON.trial_type.Description = 'Event type (checkerboard)';
        if isfield(pa, 'designID'), eventsJSON.DesignID = pa.designID; end
        if isfield(pa, 'designSeed'), eventsJSON.DesignSeed = pa.designSeed; end
        if isfield(pa, 'targetRunDuration')
            eventsJSON.TargetRunDuration = pa.targetRunDuration;
        end
        if isfield(pa, 'totalDesignDuration')
            eventsJSON.PlannedRunDuration = pa.totalDesignDuration;
        end
        jsonStr = jsonencode(eventsJSON, 'PrettyPrint', true);
        fid = fopen(pa.eventsJSONFileName, 'w');
        if fid ~= -1
            fprintf(fid, '%s', jsonStr);
            fclose(fid);
            fprintf('Saved events JSON: %s\n', pa.eventsJSONFileName);
        end
    catch ME
        fprintf('ERROR saving JSON: %s\n', ME.message);
    end
end

% Save planned design for reproducibility
if isfield(pa, 'designMatrixFileName') && ~isempty(pa.designMatrixFileName) && ...
   isfield(pa, 'isiSequence')
    try
        eventIndex = (1:length(pa.isiSequence))';
        isiDuration = pa.isiSequence';
        dimOnsetInIsi = pa.dimSchedule';
        dimDuration = pa.dimDuration * double(dimOnsetInIsi > 0);
        if isfield(pa, 'plannedOnsets')
            plannedOnset = pa.plannedOnsets';
        else
            plannedOnset = nan(size(eventIndex));
        end
        designTable = table(eventIndex, plannedOnset, isiDuration, ...
            dimOnsetInIsi, dimDuration, ...
            'VariableNames', {'event_index', 'planned_onset', ...
            'isi_duration', 'dim_onset_in_isi', 'dim_duration'});
        writetable(designTable, pa.designMatrixFileName);
        fprintf('Saved planned design: %s\n', pa.designMatrixFileName);
    catch ME
        fprintf('ERROR saving design CSV: %s\n', ME.message);
    end
end

fprintf('Cleanup complete. Total time: %.1f s\n', pa.totalExperimentTime);

end

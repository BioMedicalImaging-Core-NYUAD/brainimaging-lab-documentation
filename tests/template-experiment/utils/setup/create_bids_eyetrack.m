function create_bids_eyetrack(pa, info)
% CREATE_BIDS_EYETRACK - Create BIDS eyetrack.tsv and eyetrack.json files
%
% Input:
%   pa - Parameters structure with continuous gaze data
%   info - BIDS info structure with file paths
%
% This function creates BIDS-compliant eye tracking data files following
% BEP 020 specification:
% - Required columns: time, gaze_x, gaze_y
% - Optional columns: pupil_size (if available)

if isempty(info) || ~isfield(info, 'dataDir')
    return;
end

% Check if eyetracking data exists
if ~pa.eyeTrackingEnabled || ~isfield(pa.data, 'continuousGazeX') || pa.gazeSampleCounter == 0
    return;
end

% Extract valid gaze samples
nSamples = pa.gazeSampleCounter;
time = pa.data.continuousGazeTime(1:nSamples);
gaze_x = pa.data.continuousGazeX(1:nSamples);
gaze_y = pa.data.continuousGazeY(1:nSamples);

% Ensure all are column vectors
time = time(:);
gaze_x = gaze_x(:);
gaze_y = gaze_y(:);

% Check if pupil data is available
hasPupilData = isfield(pa.data, 'continuousPupilArea') && ...
               any(~isnan(pa.data.continuousPupilArea(1:nSamples)));

% Build filename (same pattern as events but with _eyetrack suffix)
fileName = sprintf('sub-%s_ses-%s_run-%s', info.subjectID, info.sessionID, info.runID);
if ~isempty(info.taskName)
    fileName = sprintf('%s_task-%s', fileName, info.taskName);
end
fileName = [fileName '_eyetrack'];

fullPathTSV = fullfile(info.dataDir, [fileName '.tsv']);
fullPathJSON = fullfile(info.dataDir, [fileName '.json']);

% Create table with required columns
if hasPupilData
    pupil_size = pa.data.continuousPupilArea(1:nSamples);
    pupil_size = pupil_size(:);
    eyetrackTable = table(time, gaze_x, gaze_y, pupil_size, ...
        'VariableNames', {'time', 'gaze_x', 'gaze_y', 'pupil_size'});
else
    eyetrackTable = table(time, gaze_x, gaze_y, ...
        'VariableNames', {'time', 'gaze_x', 'gaze_y'});
end

% Write TSV file
writetable(eyetrackTable, fullPathTSV, 'FileType', 'text', 'Delimiter', '\t');

% Create JSON metadata following BIDS specification
eyetrackJSON = struct();

% Required metadata
eyetrackJSON.SamplingFrequency = 1 / pa.gazeSampleInterval;
eyetrackJSON.Manufacturer = 'SR Research';
eyetrackJSON.ManufacturersModelName = 'Eyelink';

% Column descriptions
eyetrackJSON.time.Description = 'Time in seconds from the start of the recording';
eyetrackJSON.time.Units = 'seconds';

eyetrackJSON.gaze_x.Description = 'Horizontal gaze position';
eyetrackJSON.gaze_x.Units = 'pixels';

eyetrackJSON.gaze_y.Description = 'Vertical gaze position';
eyetrackJSON.gaze_y.Units = 'pixels';

if hasPupilData
    eyetrackJSON.pupil_size.Description = 'Pupil size or area';
    eyetrackJSON.pupil_size.Units = 'arbitrary units';
end

% Additional metadata
eyetrackJSON.RecordingType = 'gaze';
eyetrackJSON.RecordingDuration = time(end);
eyetrackJSON.StartTime = 0;

% Write JSON file
jsonStr = jsonencode(eyetrackJSON, 'PrettyPrint', true);
fid = fopen(fullPathJSON, 'w');
if fid ~= -1
    fprintf(fid, '%s', jsonStr);
    fclose(fid);
    fprintf('Created BIDS eyetrack files:\n  %s\n  %s\n', fullPathTSV, fullPathJSON);
else
    warning('Could not write eyetrack JSON file: %s', fullPathJSON);
end

end


function cleanup_experiment(VP, pa, kb, experimentStartTime)
% CLEANUP_EXPERIMENT - Clean up resources and finalize experiment
%
% Input:
%   VP - Viewing Parameters structure
%   pa - Parameters structure
%   kb - Keyboard structure
%   experimentStartTime - Start time of experiment

% Stop and save Eyelink data
if isfield(pa, 'eyeTrackingEnabled') && pa.eyeTrackingEnabled
    try
        if isfield(pa, 'eyeFileBase') && isfield(pa, 'eyeDataDir')
            initEyelinkStates('eyestop', VP.window, {pa.eyeFileBase, pa.eyeDataDir});
        end
    catch ME
        fprintf('  Warning: Could not stop Eyelink: %s\n', ME.message);
    end
end

% Clean up resources
fprintf('\nCleaning up resources...\n');

% Clean up keyboard queue
try
    KbQueueStop();
    KbQueueRelease();
    fprintf('  Keyboard queue released\n');
catch ME
    fprintf('  Warning: Could not release keyboard queue: %s\n', ME.message);
end

% Close Psychtoolbox windows
try
    sca; % Screen('CloseAll')
    fprintf('  Psychtoolbox windows closed\n');
catch ME
    fprintf('  Warning: Could not close Psychtoolbox windows: %s\n', ME.message);
end

% Close VPixx connection
try
    if Datapixx('IsReady')
        Datapixx('Close');
        fprintf('  VPixx connection closed\n');
    end
catch ME
    fprintf('  Warning: Could not close VPixx connection: %s\n', ME.message);
end

fprintf('Cleanup complete.\n');

% Calculate and display results
totalExperimentTime = GetSecs - experimentStartTime;
if isfield(pa, 'trialCounter')
    nTrials = pa.trialCounter;
else
    nTrials = 0;
end
if nTrials > 0 && isfield(pa, 'data') && isfield(pa.data, 'correct')
    nCorrect = sum(pa.data.correct(1:nTrials));
    accuracy = nCorrect / nTrials * 100;
else
    nCorrect = 0;
    accuracy = 0;
end

fprintf('\n=== EXPERIMENT COMPLETE ===\n');
fprintf('Total trials completed: %d\n', nTrials);
fprintf('Total experiment time: %.2f seconds (%.2f minutes)\n', totalExperimentTime, totalExperimentTime/60);
if nTrials > 0 && isfield(pa, 'data') && isfield(pa.data, 'targetColor') && isfield(pa.data, 'response')
    fprintf('Results Summary:\n');
    fprintf('Target Color\tResponse\n');
    fprintf('------------\t--------\n');
    
    for i = 1:nTrials
        fprintf('%s\t\t%s\n', pa.data.targetColor{i}, pa.data.response{i});
    end
    
    fprintf('\nOverall Accuracy: %d out of %d (%.1f%%)\n', nCorrect, nTrials, accuracy);
else
    fprintf('No trials were completed.\n');
end

% Store total experiment time in data structure
pa.totalExperimentTime = totalExperimentTime;

% Save data
if isfield(pa, 'dataFileName') && ~isempty(pa.dataFileName)
    % Ensure directory exists
    [saveDir, ~, ~] = fileparts(pa.dataFileName);
    if ~exist(saveDir, 'dir')
        fprintf('Creating directory: %s\n', saveDir);
        mkdir(saveDir);
    end
    fprintf('Saving data to: %s\n', pa.dataFileName);
    try
        save(pa.dataFileName, 'pa');
        if exist(pa.dataFileName, 'file')
            fprintf('Data saved successfully to %s\n', pa.dataFileName);
        else
            fprintf('ERROR: File was not created at %s\n', pa.dataFileName);
        end
    catch ME
        fprintf('ERROR: Could not save data to %s\n', pa.dataFileName);
        fprintf('Error: %s\n', ME.message);
    end
else
    fprintf('WARNING: No data filename set, data not saved\n');
end

% Create BIDS events files
if isfield(pa, 'bidsInfo') && ~isempty(pa.bidsInfo)
    try
        create_bids_events(pa, pa.bidsInfo);
    catch ME
        fprintf('WARNING: Could not create BIDS events files: %s\n', ME.message);
    end
end

% Create BIDS eyetrack files
if isfield(pa, 'bidsInfo') && ~isempty(pa.bidsInfo) && ...
   isfield(pa, 'eyeTrackingEnabled') && pa.eyeTrackingEnabled
    try
        create_bids_eyetrack(pa, pa.bidsInfo);
    catch ME
        fprintf('WARNING: Could not create BIDS eyetrack files: %s\n', ME.message);
    end
end

% Plot eyetracking data if available
if isfield(pa, 'eyeTrackingEnabled') && pa.eyeTrackingEnabled && ...
   isfield(pa, 'data') && isfield(pa.data, 'continuousGazeX') && ...
   isfield(pa, 'gazeSampleCounter') && pa.gazeSampleCounter > 0
    try
        plot_continuous_gaze(pa);
    catch ME
        warning('plot_continuous_gaze:failed', 'Could not plot eyetracking data: %s', ME.message);
    end
end

end


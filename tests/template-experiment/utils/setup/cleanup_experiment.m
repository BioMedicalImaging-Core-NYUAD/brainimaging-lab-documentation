function cleanup_experiment(VP, pa, kb, experimentStartTime)
% CLEANUP_EXPERIMENT - Clean up resources and finalize experiment
%
% Input:
%   VP - Viewing Parameters structure
%   pa - Parameters structure
%   kb - Keyboard structure
%   experimentStartTime - Start time of experiment

% Stop and save Eyelink data
if pa.eyeTrackingEnabled
    try
        initEyelinkStates('eyestop', VP.window, {pa.eyeFileBase, pa.eyeDataDir});
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
nTrials = pa.trialCounter;
nCorrect = sum(pa.data.correct(1:nTrials));
accuracy = nCorrect / nTrials * 100;

fprintf('\n=== EXPERIMENT COMPLETE ===\n');
fprintf('Total trials completed: %d\n', nTrials);
fprintf('Total experiment time: %.2f seconds (%.2f minutes)\n', totalExperimentTime, totalExperimentTime/60);
fprintf('Results Summary:\n');
fprintf('Target Color\tResponse\n');
fprintf('------------\t--------\n');

for i = 1:nTrials
    fprintf('%s\t\t%s\n', pa.data.targetColor{i}, pa.data.response{i});
end

fprintf('\nOverall Accuracy: %d out of %d (%.1f%%)\n', nCorrect, nTrials, accuracy);

% Store total experiment time in data structure
pa.totalExperimentTime = totalExperimentTime;

% Save data
save(pa.dataFileName, 'pa');
fprintf('Data saved to %s\n', pa.dataFileName);

% Create BIDS events files
if isfield(pa, 'bidsInfo') && ~isempty(pa.bidsInfo)
    create_bids_events(pa, pa.bidsInfo);
end

% Plot eyetracking data if available
if pa.eyeTrackingEnabled && isfield(pa.data, 'continuousGazeX') && pa.gazeSampleCounter > 0
    try
        plot_continuous_gaze(pa);
    catch ME
        warning('plot_continuous_gaze:failed', 'Could not plot eyetracking data: %s', ME.message);
    end
end

end


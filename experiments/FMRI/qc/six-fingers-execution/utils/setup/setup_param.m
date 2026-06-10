function [VP, pa] = setup_param(VP, debugConfig)
% SETUP_PARAM - Set up six-fingers motor execution parameters.

if ~isstruct(VP)
    error('setup_param:invalidInput', 'VP must be a structure');
end
if ~isstruct(debugConfig)
    error('setup_param:invalidInput', 'debugConfig must be a structure');
end

pa = struct();
pa.experimentName = 'Six Fingers Motor Execution';
pa.taskName = 'Execution';

pa.fingerNames = {'thumb', 'index', 'middle', 'ring', 'pinky'};
pa.imageFiles = containers.Map(pa.fingerNames, ...
    {'hand-01.png', 'hand-02.png', 'hand-03.png', 'hand-04.png', 'hand-05.png'});
pa.restImageFile = 'hand.png';

pa.nBlocks = 3;
pa.trialsPerBlock = numel(pa.fingerNames);
pa.nTrials = pa.nBlocks * pa.trialsPerBlock;
pa.fixationDuration = 12;
pa.stimulusDuration = 12;
pa.endScreenDuration = 2;
pa.totalDesignDuration = pa.nTrials * (pa.fixationDuration + pa.stimulusDuration) + pa.fixationDuration;

pa.blockFingerOrder = cell(1, pa.nBlocks);
for blockIdx = 1:pa.nBlocks
    pa.blockFingerOrder{blockIdx} = pa.fingerNames(randperm(pa.trialsPerBlock));
end

scriptDir = fileparts(mfilename('fullpath'));
pa.experimentDir = fullfile(scriptDir, '..', '..');
pa.imageDir = fullfile(pa.experimentDir, 'images');

if isfield(debugConfig, 'bidsInfo') && ~isempty(debugConfig.bidsInfo)
    pa.bidsInfo = debugConfig.bidsInfo;
    pa.dataDir = debugConfig.bidsInfo.dataDir;
    pa.dataFileName = debugConfig.bidsInfo.fullPath;
    pa.eventsFileName = debugConfig.bidsInfo.fullPathTSV;
    pa.designMatrixFileName = debugConfig.bidsInfo.fullPathDM;
else
    pa.bidsInfo = [];
    pa.dataDir = fullfile(pa.experimentDir, 'data');
    if ~exist(pa.dataDir, 'dir'), mkdir(pa.dataDir); end
    pa.dataFileName = fullfile(pa.dataDir, 'six_fingers_execution.mat');
    pa.eventsFileName = fullfile(pa.dataDir, 'six_fingers_execution_events.tsv');
    pa.designMatrixFileName = fullfile(pa.dataDir, 'six_fingers_execution_dm.csv');
end

pa.trialCounter = 0;
pa.eventCounter = 0;
pa.events = struct('onset', {}, 'duration', {}, 'trial_type', {}, ...
    'finger', {}, 'block', {}, 'trial', {});

pa.designMatrix = zeros(0, numel(pa.fingerNames));
pa.designMatrixLabels = pa.fingerNames;

pa.debugMode = debugConfig.enabled;
pa.useVPixx = debugConfig.useVPixx;
pa.useScannerTrigger = ~debugConfig.manualTrigger;

fprintf('=== Motor Execution Design ===\n');
fprintf('Blocks: %d\n', pa.nBlocks);
fprintf('Trials per block: %d\n', pa.trialsPerBlock);
fprintf('Rest duration: %.1fs\n', pa.fixationDuration);
fprintf('Execution cue duration: %.1fs\n', pa.stimulusDuration);
fprintf('Planned design duration: %.1fs (%.2f min)\n', ...
    pa.totalDesignDuration, pa.totalDesignDuration / 60);
for blockIdx = 1:pa.nBlocks
    fprintf('Block %d order: %s\n', blockIdx, strjoin(pa.blockFingerOrder{blockIdx}, ', '));
end

end

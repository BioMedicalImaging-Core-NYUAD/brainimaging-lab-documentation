function [VP, pa] = setup_param(VP, debugConfig)
% SETUP_PARAM - Set up six-fingers motor execution parameters.

if ~isstruct(VP)
    error('setup_param:invalidInput', 'VP must be a structure');
end
if ~isstruct(debugConfig)
    error('setup_param:invalidInput', 'debugConfig must be a structure');
end

pa = struct();

% Determine task type (flexing or tapping)
if isfield(debugConfig, 'bidsInfo') && isfield(debugConfig.bidsInfo, 'taskType')
    pa.taskType = debugConfig.bidsInfo.taskType;
else
    pa.taskType = 'flexing';  % default
end
pa.experimentName = sprintf('Six Fingers Motor %s', ...
    [upper(pa.taskType(1)) pa.taskType(2:end)]);
pa.taskName = [upper(pa.taskType(1)) pa.taskType(2:end)];

pa.fingerNames = {'thumb', 'index', 'middle', 'ring', 'pinky'};
pa.imageFiles = containers.Map(pa.fingerNames, ...
    {'hand-01.png', 'hand-02.png', 'hand-03.png', 'hand-04.png', 'hand-05.png'});
pa.restImageFile = 'hand.png';

pa.nBlocks = 3;
pa.trialsPerBlock = numel(pa.fingerNames);
pa.nTrials = pa.nBlocks * pa.trialsPerBlock;
pa.fixationDuration = 12;
pa.stimulusDuration = 12;
pa.endScreenDuration = 0;
pa.totalDesignDuration = pa.nTrials * (pa.fixationDuration + pa.stimulusDuration) + pa.fixationDuration;

pa.blockFingerOrder = cell(1, pa.nBlocks);
for blockIdx = 1:pa.nBlocks
    pa.blockFingerOrder{blockIdx} = pa.fingerNames(randperm(pa.trialsPerBlock));
end

scriptDir = fileparts(mfilename('fullpath'));
pa.experimentDir = fullfile(scriptDir, '..', '..');
pa.imageDir = fullfile(pa.experimentDir, 'images');

pa.textureMap = containers.Map();
flipImages = strcmp(pa.taskType, 'tapping');
allImageFiles = [{pa.restImageFile}, values(pa.imageFiles)];
for iImage = 1:numel(allImageFiles)
    imagePath = fullfile(pa.imageDir, allImageFiles{iImage});
    if ~exist(imagePath, 'file')
        error('setup_param:missingImage', 'Could not find image: %s', imagePath);
    end
    imgData = imread(imagePath);
    if flipImages
        imgData = imgData(:, end:-1:1, :);  % horizontal flip
    end
    pa.textureMap(imagePath) = Screen('MakeTexture', VP.window, imgData);
end

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
pa.nextEpochOnset = 0;
pa.timingBaseTime = [];
pa.actualTiming = struct('plannedOnset', {}, 'plannedDuration', {}, ...
    'actualOnset', {}, 'waitReturn', {}, 'onsetDelay', {}, ...
    'trial_type', {}, 'finger', {}, 'block', {}, 'trial', {});
pa.events = struct('onset', {}, 'duration', {}, 'trial_type', {}, ...
    'finger', {}, 'block', {}, 'trial', {});

pa.designMatrix = zeros(0, numel(pa.fingerNames));
pa.designMatrixLabels = pa.fingerNames;

pa.debugMode = debugConfig.enabled;
pa.useVPixx = debugConfig.useVPixx;
pa.useScannerTrigger = ~debugConfig.manualTrigger;

fprintf('=== Motor %s Design ===\n', pa.taskName);
if flipImages
    fprintf('Task type: %s (images flipped)\n', pa.taskType);
else
    fprintf('Task type: %s\n', pa.taskType);
end
fprintf('Blocks: %d\n', pa.nBlocks);
fprintf('Trials per block: %d\n', pa.trialsPerBlock);
fprintf('Rest duration: %.1fs\n', pa.fixationDuration);
fprintf('%s cue duration: %.1fs\n', pa.taskName, pa.stimulusDuration);
fprintf('Planned design duration: %.1fs (%.2f min)\n', ...
    pa.totalDesignDuration, pa.totalDesignDuration / 60);
for blockIdx = 1:pa.nBlocks
    fprintf('Block %d order: %s\n', blockIdx, strjoin(pa.blockFingerOrder{blockIdx}, ', '));
end

end

function [VP, pa] = setup_param(VP, debugConfig)
% SETUP_PARAM - Set up breath-hold task parameters.

if ~isstruct(VP)
    error('setup_param:invalidInput', 'VP must be a structure');
end
if ~isstruct(debugConfig)
    error('setup_param:invalidInput', 'debugConfig must be a structure');
end

pa = struct();
pa.experimentName = 'Breath Hold CVR QC';
pa.taskName = 'BH';

pa.nCycles = 4;
pa.inhaleDuration = 4;
pa.holdDuration = 16;
pa.restDuration = 40;
pa.finalRestDuration = 20;
pa.cycleDuration = pa.inhaleDuration + pa.holdDuration + pa.restDuration;
pa.totalDesignDuration = pa.nCycles * pa.cycleDuration + pa.finalRestDuration;
pa.endScreenDuration = 0;

pa.instructions = struct();
pa.instructions.inhale = 'Breathe in';
pa.instructions.hold = 'Hold your breath';
pa.instructions.rest = 'Breathe normally';

pa.colors = struct();
pa.colors.inhale = [120 200 255];
pa.colors.hold = [255 220 120];
pa.colors.rest = [220 220 220];
pa.colors.secondary = [160 160 160];

scriptDir = fileparts(mfilename('fullpath'));
pa.experimentDir = fullfile(scriptDir, '..', '..');

if isfield(debugConfig, 'bidsInfo') && ~isempty(debugConfig.bidsInfo)
    pa.bidsInfo = debugConfig.bidsInfo;
    pa.dataDir = debugConfig.bidsInfo.dataDir;
    pa.dataFileName = debugConfig.bidsInfo.fullPath;
    pa.eventsFileName = debugConfig.bidsInfo.fullPathTSV;
    pa.eventsJSONFileName = debugConfig.bidsInfo.fullPathJSON;
    pa.designMatrixFileName = debugConfig.bidsInfo.fullPathDM;
else
    pa.bidsInfo = [];
    pa.dataDir = fullfile(pa.experimentDir, 'data');
    if ~exist(pa.dataDir, 'dir'), mkdir(pa.dataDir); end
    pa.dataFileName = fullfile(pa.dataDir, 'bh.mat');
    pa.eventsFileName = fullfile(pa.dataDir, 'bh_events.tsv');
    pa.eventsJSONFileName = fullfile(pa.dataDir, 'bh_events.json');
    pa.designMatrixFileName = fullfile(pa.dataDir, 'bh_dm.csv');
end

pa.cycleCounter = 0;
pa.eventCounter = 0;
pa.nextEpochOnset = 0;
pa.timingBaseTime = [];
pa.actualTiming = struct('plannedOnset', {}, 'plannedDuration', {}, ...
    'actualOnset', {}, 'waitReturn', {}, 'onsetDelay', {}, ...
    'trial_type', {}, 'instruction', {}, 'cycle', {});
pa.events = struct('onset', {}, 'duration', {}, 'trial_type', {}, ...
    'instruction', {}, 'cycle', {});

pa.designMatrix = zeros(0, 3);
pa.designMatrixLabels = {'inhale', 'hold', 'rest'};

pa.debugMode = debugConfig.enabled;
pa.useVPixx = debugConfig.useVPixx;
pa.useScannerTrigger = ~debugConfig.manualTrigger;

fprintf('=== Breath-Hold CVR QC Design ===\n');
fprintf('Cycles: %d\n', pa.nCycles);
fprintf('Inhale duration: %.1fs\n', pa.inhaleDuration);
fprintf('Hold duration: %.1fs\n', pa.holdDuration);
fprintf('Rest duration: %.1fs\n', pa.restDuration);
fprintf('Final rest duration: %.1fs\n', pa.finalRestDuration);
fprintf('Planned design duration: %.1fs (%.2f min)\n', ...
    pa.totalDesignDuration, pa.totalDesignDuration / 60);

end

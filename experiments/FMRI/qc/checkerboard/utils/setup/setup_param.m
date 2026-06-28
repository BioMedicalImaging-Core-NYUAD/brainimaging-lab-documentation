function [VP, pa] = setup_param(VP, debugConfig)
% SETUP_PARAM - Parameters for checkerboard HRF estimation task.
%
% Event-related: 1 s checkerboard events, jittered ISI 4-12 s,
% fixed A/B/C schedules. Total 4 min.

if ~isstruct(VP)
    error('setup_param:invalidInput', 'VP must be a structure');
end
if ~isstruct(debugConfig)
    error('setup_param:invalidInput', 'debugConfig must be a structure');
end

pa = struct();
pa.experimentName = 'Checkerboard HRF Estimation';
pa.taskName = 'checkerboard';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STIMULUS TIMING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isfield(debugConfig, 'bidsInfo') && isfield(debugConfig.bidsInfo, 'designID')
    designID = debugConfig.bidsInfo.designID;
else
    designID = 'A';
end

design = load_checkerboard_design(designID);

pa.designID = design.designID;
pa.designSeed = design.designSeed;
pa.targetRunDuration = design.targetRunDuration;
pa.stimDuration = design.stimDuration;
pa.flickerHz = design.flickerHz;
pa.framesPerFlickerPhase = max(1, round(VP.frameRate / (2 * pa.flickerHz)));
pa.actualFlickerHz = VP.frameRate / (2 * pa.framesPerFlickerPhase);
pa.isiMin = design.isiMin;
pa.isiMax = design.isiMax;
pa.nEvents = design.nEvents;
pa.isiSequence = design.isiSequence;
pa.plannedOnsets = design.plannedOnsets;
pa.initialBaselineDuration = design.initialBaselineDuration;
pa.finalBaselineDuration = design.finalBaselineDuration;
pa.endScreenDuration = 3;

pa.totalDesignDuration = design.totalDesignDuration;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHECKERBOARD PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pa.checkSizeDeg = 1.0;          % full-field Cartesian check size

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FIXATION CROSS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pa.fixCrossLenDeg = 0.20;       % arm length in degrees
pa.fixCrossLen = max(4, round(pa.fixCrossLenDeg * VP.pixelsPerDegree));
pa.fixCrossWidth = 2;           % line width in pixels
pa.fixColor = [255 0 0];        % red cross
pa.fixDimColor = pa.fixColor;   % fixation remains red throughout
pa.dimDuration = design.dimDuration;
pa.dimSchedule = design.dimSchedule;
dimTrials = design.dimTrials;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DATA / BIDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
    pa.dataFileName = fullfile(pa.dataDir, 'checkerboard.mat');
    pa.eventsFileName = fullfile(pa.dataDir, 'checkerboard_events.tsv');
    pa.eventsJSONFileName = fullfile(pa.dataDir, 'checkerboard_events.json');
    pa.designMatrixFileName = fullfile(pa.dataDir, 'checkerboard_dm.csv');
end

pa.eventCounter = 0;
pa.events = struct('onset', {}, 'duration', {}, 'trial_type', {});

% Design matrix: [checkerboard, baseline] — one row per second
pa.designMatrix = zeros(0, 2);
pa.designMatrixLabels = {'checkerboard', 'baseline'};

pa.debugMode = debugConfig.enabled;
pa.useVPixx = debugConfig.useVPixx;
pa.useScannerTrigger = ~debugConfig.manualTrigger;

fprintf('=== Checkerboard HRF Estimation ===\n');
fprintf('Design: %s (seed %d)\n', pa.designID, pa.designSeed);
fprintf('Events: %d\n', pa.nEvents);
fprintf('Stimulus duration: %.0f ms\n', pa.stimDuration * 1000);
fprintf('Requested flicker rate: %.1f Hz\n', pa.flickerHz);
fprintf('Displayed flicker rate: %.2f Hz (%d frames/phase at %.2f Hz refresh)\n', ...
    pa.actualFlickerHz, pa.framesPerFlickerPhase, VP.frameRate);
fprintf('ISI range: %.0f - %.0f s (mean %.1f s)\n', pa.isiMin, pa.isiMax, mean(pa.isiSequence));
fprintf('Planned total: %.0f s (%.1f min)\n', pa.totalDesignDuration, pa.totalDesignDuration/60);
fprintf('Fixation dimming events: %d / %d ISIs\n', length(dimTrials), pa.nEvents);

end

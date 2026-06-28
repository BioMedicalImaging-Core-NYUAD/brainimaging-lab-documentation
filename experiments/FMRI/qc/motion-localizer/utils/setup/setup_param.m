function [VP, pa] = setup_param(VP, debugConfig)
% SETUP_PARAM - Parameters for the MT+ motion localizer.
%
% Block design: 15 s motion / 15 s static, 24 blocks total.
% Motion types cycle: outward, inward, clockwise, counter-clockwise.
% Random dot field: 250 dots, 0.2 deg diameter, 10 deg aperture, 12 deg/s.

if ~isstruct(VP)
    error('setup_param:invalidInput', 'VP must be a structure');
end
if ~isstruct(debugConfig)
    error('setup_param:invalidInput', 'debugConfig must be a structure');
end

pa = struct();
pa.experimentName = 'MT+ Motion Localizer';
pa.taskName = 'motionloc';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TIMING
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pa.blockDuration = 15;          % seconds per block
pa.nBlocks = 24;                % 12 motion + 12 static (alternating)
pa.totalDesignDuration = pa.blockDuration * pa.nBlocks;  % 360 s = 6 min
pa.endScreenDuration = 5;

pa.motionLabels = {'outward', 'inward', 'clockwise', 'counterclockwise'};

% Baseline condition (selected at experiment start)
if isfield(debugConfig, 'baselineType')
    pa.baselineType = debugConfig.baselineType;
else
    pa.baselineType = 'static';
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DOT FIELD PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pa.apertureDeg = 10;            % radius of dot aperture in degrees
pa.centerPatchDeg = 0;          % no central hole
pa.rmin = pa.centerPatchDeg * VP.pixelsPerDegree;
pa.rmax = pa.apertureDeg * VP.pixelsPerDegree;

pa.nDots = 250;
pa.dotDiameterDeg = 0.2;
pa.dotDiameter = pa.dotDiameterDeg * VP.pixelsPerDegree;

% Dot colors: half white, half black (high contrast for maximum MT+ drive)
pa.dotColor = zeros(pa.nDots, 3);
pa.dotColor(randperm(pa.nDots, pa.nDots/2), :) = 255;
pa.dotColor = pa.dotColor';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MOTION PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pa.speedDeg = 12;               % degrees per second
pa.pps = pa.speedDeg * VP.pixelsPerDegree;  % pixels per second
pa.thetaspeed = pa.speedDeg / pa.apertureDeg / VP.frameRate;

% Dot lifetime (limited lifetime dots reduce local motion streaks)
pa.dotdies = 1;
pa.totalLife = 0.5;             % seconds

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FIXATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pa.fixCrossLen = 5;             % pixels
pa.fixationColor = [0 255 0; 255 0 0];  % green / red

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
    pa.dataFileName = fullfile(pa.dataDir, 'motionloc.mat');
    pa.eventsFileName = fullfile(pa.dataDir, 'motionloc_events.tsv');
    pa.eventsJSONFileName = fullfile(pa.dataDir, 'motionloc_events.json');
    pa.designMatrixFileName = fullfile(pa.dataDir, 'motionloc_dm.csv');
end

pa.eventCounter = 0;
pa.events = struct('onset', {}, 'duration', {}, 'trial_type', {});

% Design matrix: [motion, static] (one row per second)
pa.designMatrix = zeros(0, 2);
pa.designMatrixLabels = {'motion', pa.baselineType};
for b = 1:pa.nBlocks
    if mod(b, 2) ~= 0
        pa.designMatrix = [pa.designMatrix; repmat([1 0], pa.blockDuration, 1)];
    else
        pa.designMatrix = [pa.designMatrix; repmat([0 1], pa.blockDuration, 1)];
    end
end

pa.debugMode = debugConfig.enabled;
pa.useVPixx = debugConfig.useVPixx;
pa.useScannerTrigger = ~debugConfig.manualTrigger;

fprintf('=== MT+ Motion Localizer ===\n');
fprintf('Block duration: %.0f s\n', pa.blockDuration);
fprintf('Total blocks: %d (motion/static alternating)\n', pa.nBlocks);
fprintf('Total duration: %.0f s (%.1f min)\n', pa.totalDesignDuration, pa.totalDesignDuration/60);
fprintf('Dots: %d, diameter: %.1f deg, aperture: %.0f deg, speed: %.0f deg/s\n', ...
    pa.nDots, pa.dotDiameterDeg, pa.apertureDeg, pa.speedDeg);
fprintf('Baseline condition: %s\n', pa.baselineType);

end

function [VP pa] = setup_param(VP, debugConfig)
% SETUP_PARAM - Set up button-pressing experiment parameters with circular path
%
% Input:
%   VP - Viewing Parameters structure from setup_display
%   debugConfig - Debug configuration structure
%
% Output:
%   VP - Updated Viewing Parameters structure
%   pa - Parameters structure with all experiment settings
%
% This function configures timing, visual parameters, and data structures
% for the circular path + traveling dot button-pressing experiment.

% Input validation
if ~isstruct(VP)
    error('setup_param:invalidInput', 'VP must be a structure');
end

requiredVPFields = {'window', 'windowCenter', 'pixelsPerDegree'};
for i = 1:length(requiredVPFields)
    if ~isfield(VP, requiredVPFields{i})
        error('setup_param:missingField', 'VP missing required field: %s', requiredVPFields{i});
    end
end

if ~isstruct(debugConfig)
    error('setup_param:invalidInput', 'debugConfig must be a structure');
end

requiredDebugFields = {'enabled', 'useVPixx', 'manualTrigger'};
for i = 1:length(requiredDebugFields)
    if ~isfield(debugConfig, requiredDebugFields{i})
        error('setup_param:missingField', 'debugConfig missing required field: %s', requiredDebugFields{i});
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXPERIMENT TIMING PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Trial phase durations
pa.stimulusDuration = 1.0;     % seconds - dot presentation
pa.responseWindow = 2.0;       % seconds - max response time
pa.feedbackDuration = 0.5;     % seconds - feedback display (fixation turns green)
pa.itiDuration = 0.5;          % seconds - inter-trial interval
pa.trialCycleDuration = pa.stimulusDuration + pa.responseWindow + pa.feedbackDuration + pa.itiDuration; % Total cycle time

% Number of trials
pa.colors = {'white', 'red', 'yellow', 'green', 'blue'};
pa.nRepeats = 2;               % Number of times to repeat each color
pa.nTrials = numel(pa.colors) * pa.nRepeats; % 5 colors × 2 repeats = 10 trials

% Start experiment and end screen durations
pa.startExpDuration = 5.0;    % seconds - start period before first trial
pa.endScreenDuration = 5.0;    % seconds - final fixation display

% Calculate total experiment duration based on planned trials
pa.totalDuration = pa.startExpDuration + (pa.nTrials * pa.trialCycleDuration) + pa.endScreenDuration;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STIMULUS PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Color definitions
pa.colorRGB = [1 1 1; 1 0 0; 1 1 0; 0 1 0; 0 0 1]; % RGB values

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CIRCULAR PATH AND TRAVELING DOT PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Circular path parameters
pa.fixationRadiusDeg = 3.0;    % degrees - radius of circular path
pa.fixationRadiusPix = pa.fixationRadiusDeg * VP.pixelsPerDegree; % pixels

% Traveling dot rotation parameters
pa.fixationRotationPeriod = 36; % seconds - time for one full circle
pa.fixationSpeed = 2*pi / pa.fixationRotationPeriod; % radians per second (rotation speed)

% Traveling dot appearance
pa.travelingDotRadiusDeg = 0.125; % degrees - radius of traveling dot
pa.travelingDotRadiusPix = pa.travelingDotRadiusDeg * VP.pixelsPerDegree; % pixels
pa.dotColor = [0 0 0];         % White dot color (default)
pa.dotColorCorrect = [0 1 0];  % Green for correct responses
pa.dotColorIncorrect = [0 0 0]; 

% Circular path appearance
pa.circleLineWidth = 3;        % pixels - thickness of circular path outline
pa.circleColorDefault = [0 0 0]; % Black circle color (default for all non-stimulus phases)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BUTTON MAPPING PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define which buttons are on which box
pa.leftBoxColors = pa.colors(1:3);   % white, red, yellow
pa.rightBoxColors = pa.colors(4:5);  % green, blue



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TRIAL STRUCTURE PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create randomized color sequence
pa.colorSequence = repmat(pa.colors, 1, pa.nRepeats);
pa.colorSequence = pa.colorSequence(randperm(pa.nTrials)); % Randomize order

fprintf('=== Experiment Timing ===\n');
fprintf('Trials planned: %d\n', pa.nTrials);
fprintf('Trial cycle duration: %.1fs (%.1fs stim + %.1fs response + %.1fs feedback + %.1fs ITI)\n', ...
        pa.trialCycleDuration, pa.stimulusDuration, pa.responseWindow, pa.feedbackDuration, pa.itiDuration);
fprintf('End screen duration: %.1fs\n', pa.endScreenDuration);
fprintf('Total experiment duration: %.1fs\n', pa.totalDuration);
fprintf('Color sequence: %s\n', strjoin(pa.colorSequence, ', '));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DATA COLLECTION PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Pre-allocate data storage arrays
pa.data = struct();
pa.data.trialNumber = zeros(1, pa.nTrials);
pa.data.targetColor = cell(1, pa.nTrials);
pa.data.response = cell(1, pa.nTrials);
pa.data.correct = zeros(1, pa.nTrials);
pa.data.reactionTime = nan(1, pa.nTrials);
pa.data.trialStartTime = zeros(1, pa.nTrials);
pa.data.cumulativeTime = zeros(1, pa.nTrials);
pa.data.fixationAngle = zeros(1, pa.nTrials);
pa.data.gazeX = nan(1, pa.nTrials);
pa.data.gazeY = nan(1, pa.nTrials);
pa.trialCounter = 0; % Track actual number of trials completed

% Continuous gaze tracking arrays (for every 0.5 seconds)
% Estimate: max 10 minutes = 600 seconds = 1200 samples per experiment
pa.maxGazeSamples = 2000; % Pre-allocate extra space
pa.data.continuousGazeX = nan(1, pa.maxGazeSamples);
pa.data.continuousGazeY = nan(1, pa.maxGazeSamples);
pa.data.continuousGazeTime = nan(1, pa.maxGazeSamples);
pa.gazeSampleCounter = 0; % Track actual number of samples
pa.gazeSampleInterval = 0.5; % Record every 0.5 seconds
pa.lastGazeSampleTime = 0; % Track when we last recorded

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% VPIXX INITIALIZATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize VPixx for button detection if not already initialized
if debugConfig.useVPixx
    if ~Datapixx('IsReady')
        try
            Datapixx('Open');
            Datapixx('DisablePixelMode');
            Datapixx('RegWr');
            fprintf('VPixx initialized successfully for button detection\n');
        catch ME
            warning(ME.identifier, '%s', ME.message);
            fprintf('Falling back to keyboard input\n');
        end
    else
        fprintf('VPixx already initialized\n');
    end
else
    fprintf('Using keyboard input (VPixx disabled in debug config)\n');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXPERIMENT CONTROL PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pa.experimentName = 'Circular Path Button Pressing Experiment';

% Set up data directory and filename
scriptDir = fileparts(mfilename('fullpath'));
experimentDir = fullfile(scriptDir, '..', '..');

if isfield(debugConfig, 'bidsInfo') && ~isempty(debugConfig.bidsInfo)
    pa.dataDir = debugConfig.bidsInfo.dataDir;
    pa.dataFileName = debugConfig.bidsInfo.fullPath;
    pa.bidsInfo = debugConfig.bidsInfo;
else
    dataDir = fullfile(experimentDir, 'data');
    if ~exist(dataDir, 'dir')
        mkdir(dataDir);
    end
    pa.dataFileName = fullfile(dataDir, 'circular_path_data.mat');
    pa.bidsInfo = [];
end

% Store screen center for plotting functions
pa.screenCenter = VP.windowCenter;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EYE TRACKING PARAMETERS (following vri_restingstate pattern)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if isfield(debugConfig, 'eyetracking')
    pa.eyeTrackingEnabled = debugConfig.eyetracking;
else
    pa.eyeTrackingEnabled = 0;
end
% Set up eyetracking data directory
scriptDir = fileparts(mfilename('fullpath'));
experimentDir = fullfile(scriptDir, '..', '..');
pa.eyeDataDir = fullfile(experimentDir, 'data', 'eyetracking_data');
if ~exist(pa.eyeDataDir, 'dir'), mkdir(pa.eyeDataDir); end
base = datestr(now,'mmddHHMM');
pa.eyeFileBase = base(1:min(end,8));
pa.eyeFileName = [pa.eyeFileBase '.edf'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEBUG AND TRIGGER PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pa.debugMode = debugConfig.enabled;           % Use debug configuration from main
pa.useVPixx = debugConfig.useVPixx;          % Use VPixx hardware or keyboard
pa.useScannerTrigger = ~debugConfig.manualTrigger; % Scanner vs manual trigger

end
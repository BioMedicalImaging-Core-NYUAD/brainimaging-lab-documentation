function [VP pa] = setup_param(VP, debugConfig)
% SETUP_PARAM - Set up single dot button-pressing experiment parameters
%
% Input:
%   VP - Viewing Parameters structure from setup_display
%   debugConfig - Debug configuration structure
%
% Output:
%   VP - Updated Viewing Parameters structure
%   pa - Parameters structure with all experiment settings

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

% Number of trials (5 colors × 2 repeats)
pa.nTrials = 10;

% End screen duration
pa.endScreenDuration = 5.0;    % seconds - final fixation display

% Calculate total experiment duration based on planned trials
pa.totalDuration = (pa.nTrials * pa.trialCycleDuration) + pa.endScreenDuration;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% STIMULUS PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Color definitions
pa.colors = {'white', 'red', 'yellow', 'green', 'blue'};
pa.colorRGB = [1 1 1; 1 0 0; 1 1 0; 0 1 0; 0 0 1]; % RGB values

% Single dot parameters (0.5 degrees visual angle radius)
pa.dotRadiusDeg = 0.5;         % degrees
pa.dotRadiusPix = pa.dotRadiusDeg * VP.pixelsPerDegree; % pixels
pa.dotCenter = VP.windowCenter; % Center of screen

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MOVING FIXATION PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Circular path parameters
pa.fixationRadiusDeg = 1.5;    % degrees - radius of circular fixation path
pa.fixationRadiusPix = pa.fixationRadiusDeg * VP.pixelsPerDegree; % pixels

% Fixation rotation parameters
pa.fixationRotationPeriod = 36; % seconds - time for one full circle
pa.fixationSpeed = 2*pi / pa.fixationRotationPeriod; % radians per second

% Fixation cross appearance
pa.fixationSize = 20;          % pixels - size of fixation cross
pa.fixationThickness = 3;      % pixels - line thickness

% Fixation colors
pa.fixColor = [1 1 1];         % White fixation
pa.fixColorCorrect = [0 1 0];  % Green for correct responses
pa.fixColorIncorrect = [1 0 0]; % Red for incorrect responses

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% BUTTON MAPPING PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define which buttons are on which box
pa.leftBoxColors = pa.colors(1:3);   % white, red, yellow
pa.rightBoxColors = pa.colors(4:5);  % green, blue

% Create button selection structure
pa.buttonSelection = struct();
pa.buttonSelection.left_box = pa.leftBoxColors;
pa.buttonSelection.right_box = pa.rightBoxColors;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TRIAL STRUCTURE PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create randomized color sequence: 2 repeats of each color (10 trials total)
pa.colorSequence = repmat(pa.colors, 1, 2); % [white, red, yellow, green, blue, white, red, yellow, green, blue]
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
% Pre-allocate data storage arrays for performance
% Allocate 50% extra space in case trials complete faster than expected
pa.maxTrials = ceil(pa.nTrials * 1.5);

pa.data = struct();
pa.data.trialNumber = zeros(1, pa.maxTrials);
pa.data.targetColor = cell(1, pa.maxTrials);
pa.data.response = cell(1, pa.maxTrials);
pa.data.correct = zeros(1, pa.maxTrials);
pa.data.reactionTime = nan(1, pa.maxTrials);
pa.data.trialStartTime = zeros(1, pa.maxTrials);
pa.data.cumulativeTime = zeros(1, pa.maxTrials);
pa.data.fixationAngle = zeros(1, pa.maxTrials);
pa.trialCounter = 0; % Track actual number of trials completed

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
            warning('Failed to initialize VPixx: %s', ME.message);
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
pa.experimentName = 'Single Dot Button Pressing Experiment';
pa.dataFileName = 'single_dot_data.mat';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEBUG AND TRIGGER PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pa.debugMode = debugConfig.enabled;           % Use debug configuration from main
pa.useVPixx = debugConfig.useVPixx;          % Use VPixx hardware or keyboard
pa.useScannerTrigger = ~debugConfig.manualTrigger; % Scanner vs manual trigger

end
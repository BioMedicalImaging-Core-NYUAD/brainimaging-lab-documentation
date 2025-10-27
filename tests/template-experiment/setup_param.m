function [VP pa] = setup_param(VP)
% SETUP_PARAM - Set up single dot button-pressing experiment parameters
%
% Input:
%   VP - Viewing Parameters structure from setup_display
%
% Output:
%   VP - Updated Viewing Parameters structure
%   pa - Parameters structure with all experiment settings

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXPERIMENT TIMING PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pa.totalDuration = 60.0;       % Total experiment duration in seconds (1 minute)
pa.stimulusDuration = 1.0;     % seconds - dot presentation
pa.responseWindow = 2.0;       % seconds - max response time
pa.feedbackDuration = 2.0;     % seconds - feedback display
pa.itiDuration = 1.0;          % seconds - inter-trial interval
pa.trialCycleDuration = pa.stimulusDuration + pa.responseWindow + pa.feedbackDuration + pa.itiDuration; % Total cycle time

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
% Circular path parameters (1.5 degrees radius)
pa.fixationRadiusDeg = 1.5;    % degrees
pa.fixationRadiusPix = pa.fixationRadiusDeg * VP.pixelsPerDegree; % pixels
pa.fixationSpeed = 2*pi / 36;  % radians per second (36 seconds per full circle)
pa.fixationSize = 20;          % pixels
pa.fixationThickness = 3;      % pixels

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
% Calculate approximate number of trials based on total duration
pa.estimatedTrials = floor(pa.totalDuration / pa.trialCycleDuration);
fprintf('Estimated trials for %.1f seconds: %d\n', pa.totalDuration, pa.estimatedTrials);

% Create randomized color sequence: 2 repeats of each color (10 trials total)
pa.nTrials = 10; % 5 colors × 2 repeats = 10 trials
pa.colorSequence = repmat(pa.colors, 1, 2); % [white, red, yellow, green, blue, white, red, yellow, green, blue]
pa.colorSequence = pa.colorSequence(randperm(pa.nTrials)); % Randomize order

fprintf('Color sequence: %s\n', strjoin(pa.colorSequence, ', '));
fprintf('Total trials planned: %d\n', pa.nTrials);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DATA COLLECTION PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize data storage structure (dynamic sizing)
pa.data = struct();
pa.data.trialNumber = [];
pa.data.targetColor = {};
pa.data.response = {};
pa.data.correct = [];
pa.data.reactionTime = [];
pa.data.trialStartTime = [];
pa.data.cumulativeTime = [];
pa.data.fixationAngle = [];
pa.trialCounter = 0; % Track actual number of trials completed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% VPIXX INITIALIZATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Initialize VPixx for button detection
try
    Datapixx('Open');
    Datapixx('DisablePixelMode');
    Datapixx('RegWr');
    fprintf('VPixx initialized successfully\n');
catch
    error('Failed to initialize VPixx. Make sure it is connected.');
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EXPERIMENT CONTROL PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pa.experimentName = 'Single Dot Button Pressing Experiment';
pa.dataFileName = 'single_dot_data.mat';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SCANNER TRIGGER PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pa.debugMode = true;           % true = manual trigger (5 or t), false = scanner trigger
pa.useScannerTrigger = ~pa.debugMode; % Automatically set based on debug mode

end
%fingertapping- this one for haidee only stop and tap 

clear all
close all

global parameters;
global screen;
global tc;
global isTerminationKeyPressed;
global resReport;
global totalTime;
global datapixx;

Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'Verbosity', 0);

timingsReport = struct( ...
    'block', {}, ...
    'trial', {}, ...
    'phase', {}, ...
    'finger', {}, ...
    'startTime', {}, ...
    'endTime', {}, ...
    'duration', {} ...
);
  % Initialize empty struct array

addpath('supportFiles');   

%   Load parameters
%--------------------------------------------------------------------------------------------------------------------------------------%
loadParameters();

%   Initialize the subject info
%--------------------------------------------------------------------------------------------------------------------------------------%
initSubjectInfo();

%   Hide Mouse Cursor
if parameters.hideCursor
    HideCursor()
end

%   Initialize screen
%--------------------------------------------------------------------------------------------------------------------------------------%
initScreen(); %change transparency of screen from here

%   Convert values from visual degrees to pixels
%--------------------------------------------------------------------------------------------------------------------------------------%
visDegrees2Pix();

%   Initialize Datapixx
%--------------------------------------------------------------------------------------------------------------------------------------%
if ~parameters.isDemoMode
    datapixx = 0;               
    AssertOpenGL;
    isReady = Datapixx('Open');
    Datapixx('StopAllSchedules');
    Datapixx('RegWrRd'); % Sync registers
end

%  Run the experiment
%--------------------------------------------------------------------------------------------------------------------------------------%

ListenChar(2);  % Suspend keyboard echo to command line

%   Init scanner TTL screen
%--------------------------------------------------------------------------------------------------------------------------------------%
if parameters.isDemoMode
    showTTLWindow_1();
else
    showTTLWindow_2();
end

% ======================== MOTOR EXECUTION (ME) ==========================
isTerminationKeyPressed = false;

for block = 1:parameters.meNumberOfBlocks
    trialList = parameters.fingerList(randperm(length(parameters.fingerList))); % Randomized trial list
    for i = 1:parameters.meTrials
        % Fixation
        showFixationWindow();

        % Stimulus + Timing
        imgPath = fullfile('images', parameters.imageMap(trialList{i}));
        [startTime, endTime] = showImageBlockWindow(imgPath);
        duration = endTime - startTime;

        % Log trial
        fprintf('ME Trial %d: %s\n', i, trialList{i});

        % Append timing
        timingsReport(end+1) = struct( ...
            'block', block, ...
            'trial', i, ...
            'phase', 'ME', ...
            'finger', trialList{i}, ...
            'startTime', startTime, ...
            'endTime', endTime, ...
            'duration', duration ...
        );
    end
end

% ======================== MOTOR IMAGERY (MI) ==========================
showTextUntilKey('Motor Imagery\n Press any key to continue...');

for block = 1:parameters.miNumberOfBlocks
    miBlock = block + parameters.meNumberOfBlocks; 

    % Alternate NT/ST
    if rand < 0.5
        conds = repmat({'NT','ST'}, 1, parameters.miTrials / 2);
    else
        conds = repmat({'ST','NT'}, 1, parameters.miTrials / 2);
    end

    miTrialList = cell(1, parameters.miTrials);
    for i = 1:parameters.miTrials
        if strcmp(conds{i}, 'NT')
            miTrialList{i} = parameters.NT_fingers{randi(numel(parameters.NT_fingers))};
        else
            miTrialList{i} = parameters.ST_finger;
        end
    end

    for i = 1:parameters.miTrials
        showFixationWindow();
        imgPath = fullfile('images', parameters.miImageMap(miTrialList{i}));
        [startTime, endTime] = showImageBlockWindow(imgPath);
        duration = endTime - startTime;

        fprintf('MI Trial %d: %s\n', i, miTrialList{i});

        % Append timing
        timingsReport(end+1) = struct( ...
            'block', miBlock, ...
            'trial', i, ...
            'phase', 'MI', ...
            'finger', miTrialList{i}, ...
            'startTime', startTime, ...
            'endTime', endTime, ...
            'duration', duration ...
        );
    end

    showTextUntilKey('Break Time!\n Press any key to continue...');
end

% End of experiment screen
startEoeTime = showEoeWindow();

% ======================== SAVE DATA ==========================
writetable(struct2table(timingsReport), parameters.datafile);

% Re-enable keyboard input to command line
ListenChar(1);
ShowCursor('Arrow');
sca;

% Shutdown Datapixx
if ~parameters.isDemoMode
    Datapixx('RegWrRd');
    Datapixx('StopAllSchedules');
    Datapixx('Close');
end

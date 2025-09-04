function main_MI(blockNumber)
    % main_MI(blockNumber)
    %
    % Motor Imagery (MI) part of the six-fingers experiment.
    % This script runs a single block of the MI experiment.
    %
    % Input:
    %   blockNumber - (optional) the block number for the current run. Default is 1.

    if nargin < 1
        blockNumber = 1;
    end

    clear all;
    close all;

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
        'trial', {}, ...
        'phase', {}, ...
        'finger', {}, ...
        'startTime', {}, ...
        'endTime', {}, ...
        'duration', {} ...
    );


    designMatrix = struct( ...
        'c1', {}, ...
        'c2', {}, ...
        'c3', {}, ...
        'c4', {}, ...
        'c5', {} ...
        );
      % Initialize empty struct array

    addpath('supportFiles');

    %   Load parameters
    %--------------------------------------------------------------------------------------------------------------------------------------%
    loadParameters();

    %   Initialize the subject info
    %--------------------------------------------------------------------------------------------------------------------------------------%
    initSubjectInfo('MI');

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

    % ======================== MOTOR IMAGERY (MI) ==========================
    isTerminationKeyPressed = false;
    if parameters.isDemoMode
        showTTLWindow_1();
    else
        showTTLWindow_2();
    end

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
        %showFixationWindow();
        fixationPath = fullfile('images','hand.png');
        [startTime, endTime] = showImageBlockWindow(fixationPath,'rest');
        duration = endTime - startTime;

        % Append timing
        timingsReport(end+1) = struct( ...
            'trial', i, ...
            'phase', 'MI', ...
            'finger', 'Rest', ...
            'startTime', startTime, ...
            'endTime', endTime, ...
            'duration', duration ...
        );


        % Append design matrix
        designMatrix(end+1:end+parameters.fixationDuration) = struct( ...
            'c1', 0, ...
            'c2', 0, ...
            'c3', 0, ...
            'c4', 0, ...
            'c5', 0);
            
        imgPath = fullfile('images', parameters.miImageMap(miTrialList{i}));
        [startTime, endTime] = showImageBlockWindow(imgPath, miTrialList{i});
        duration = endTime - startTime;

        % Append timing
        timingsReport(end+1) = struct( ...
            'trial', i, ...
            'phase', 'MI', ...
            'finger', miTrialList{i}, ...
            'startTime', startTime, ...
            'endTime', endTime, ...
            'duration', duration ...
        );
        % Append design matrix
        designMatrix(end+1:end+parameters.stimulusDuration) = struct( ...
            'c1', 0, ...
            'c2', 0, ...
            'c3', 0, ...
            'c4', 0, ...
            'c5', 0);

        if miTrialList{i} == "thumb"
            [designMatrix(end+1-parameters.stimulusDuration:end).c1] = deal(1);
        elseif miTrialList{i} == "index"
            [designMatrix(end+1-parameters.stimulusDuration:end).c2] = deal(1);
        elseif miTrialList{i} == "middle"
            [designMatrix(end+1-parameters.stimulusDuration:end).c3] = deal(1);
        elseif miTrialList{i} == "ring"
            [designMatrix(end+1-parameters.stimulusDuration:end).c4] = deal(1);
        elseif miTrialList{i} == "pinky"
            [designMatrix(end+1-parameters.stimulusDuration:end).c5] = deal(1);
        end

    end

    % End of experiment screen
    startEoeTime = showEoeWindow();

    % ======================== SAVE DATA ==========================
    % Check if the datafile exists, if so, append to it.
    if isfile(parameters.datafile)
        existingData = readtable(parameters.datafile);
        newData = struct2table(timingsReport);
        writetable([existingData; newData], parameters.datafile);
        existingData2 = readtable(parameters.datafile_dm);
        newData = struct2table(designMatrix);
        writetable([existingData2; newData], parameters.datafile_dm);
    else
        writetable(struct2table(timingsReport), parameters.datafile);
        writetable(struct2table(designMatrix), parameters.datafile_dm);
    end


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
end
function main_MI(miNumberOfBlocks)
    % main_MI(miNumberOfBlocks)
    %
    % Motor Imagery (MI) part of the six-fingers experiment.
    %
    % Input:
    %   miNumberOfBlocks - (optional) number of blocks to run. Default is 4.

    if nargin < 1
        miNumberOfBlocks = 4;
    end


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
        'c5', {}, ...
        'c6', {} ...
        );

    addpath('supportFiles');

    %   Load parameters
    %--------------------------------------------------------------------------------------------------------------------------------------%
    loadParameters(' MOTOR IMAGERY ');

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
        datapixx = 1;
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
    
    for block = 1:miNumberOfBlocks
        trialList = parameters.fingerList_MI(randperm(length(parameters.fingerList_MI))); % Randomized trial list
        for i = 1:parameters.miTrials
            % Fixation
%             showFixationWindow();
            fixationPath = fullfile('images','hand.png');
            [startTime, endTime] = showImageBlockWindow(fixationPath,'rest');
            duration = endTime - startTime;

%             % Append timing
            timingsReport(end+1) = struct( ...
                'trial', i, ...
                'phase', 'MI', ...
                'finger', 'Rest', ...
                'startTime', startTime, ...
                'endTime', endTime, ...
                'duration', duration ...
            );
            
            % % Append design matrix
            designMatrix(end+1:end+parameters.fixationDuration) = struct( ...
                'c1', 0, ...
                'c2', 0, ...
                'c3', 0, ...
                'c4', 0, ...
                'c5', 0, ...
                'c6', 0);


            % Stimulus + Timing
            imgPath = fullfile('images', parameters.miImageMap(trialList{i}));
            [startTime, endTime] = showImageBlockWindow(imgPath, trialList{i});
            duration = endTime - startTime;

%             % Append timing
            timingsReport(end+1) = struct( ...
                'trial', i, ...
                'phase', 'MI', ...
                'finger', trialList{i}, ...
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
                'c5', 0, ...
                'c6', 0);
            if trialList{i} == "thumb"
                [designMatrix(end+1-parameters.stimulusDuration:end).c1] = deal(1);
            elseif trialList{i} == "index"
                [designMatrix(end+1-parameters.stimulusDuration:end).c2] = deal(1);
            elseif trialList{i} == "middle"
                [designMatrix(end+1-parameters.stimulusDuration:end).c3] = deal(1);
            elseif trialList{i} == "ring"
                [designMatrix(end+1-parameters.stimulusDuration:end).c4] = deal(1);
            elseif trialList{i} == "pinky"
                [designMatrix(end+1-parameters.stimulusDuration:end).c5] = deal(1);
            elseif trialList{i} == "sixth"
                [designMatrix(end+1-parameters.stimulusDuration:end).c6] = deal(1);
            end



        end
    end

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
        'c5', 0, ...
        'c6', 0 ...
        );


    % End of experiment screen
    startEoeTime = showEoeWindow();

    % ======================== SAVE DATA ==========================
    writetable(struct2table(timingsReport), parameters.datafile);
    writetable(struct2table(designMatrix), parameters.datafile_dm);

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
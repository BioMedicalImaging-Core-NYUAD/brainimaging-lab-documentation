function main_ME(meNumberOfBlocks)
    % main_ME(meNumberOfBlocks)
    %
    % Motor Execution (ME) part of the six-fingers experiment.
    %
    % Input:
    %   meNumberOfBlocks - (optional) number of blocks to run. Default is 4.

    if nargin < 1
        meNumberOfBlocks = 4;
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

    % ======================== MOTOR EXECUTION (ME) ==========================
    isTerminationKeyPressed = false;
    if parameters.isDemoMode
        showTTLWindow_1();
    else
        showTTLWindow_2();
    end

    for block = 1:meNumberOfBlocks
        trialList = parameters.fingerList(randperm(length(parameters.fingerList))); % Randomized trial list
        for i = 1:parameters.meTrials
            % Fixation
%             showFixationWindow();
            fixationPath = fullfile('images','Rest.png');
            showImageBlockWindow(fixationPath,'rest');

            % Stimulus + Timing
            imgPath = fullfile('images', parameters.imageMap(trialList{i}));
            [startTime, endTime] = showImageBlockWindow(imgPath, trialList{i});
            duration = endTime - startTime;

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
end
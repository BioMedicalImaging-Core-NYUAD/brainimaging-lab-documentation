function main()
% MAIN - Button-pressing experiment with circular path and traveling dot
%
% Participants view a circular path with a continuously traveling dot. During
% stimulus presentation, the circular path changes to a target color (white,
% red, yellow, green, or blue). Participants press the corresponding button
% for the color they see.
%
% Visual elements:
% - Circular path: Black during non-stimulus phases, changes to target color during stimulus
% - Traveling dot: Continuously moves along path; changes to green/red for feedback

%
% Trial structure:
% 1. Stimulus: Circular path displays target color
% 2. Response: Participant responds while path returns to black
% 3. Feedback: Traveling dot changes color to  indicate correctness
% 4. Inter-trial interval: Brief pause before next trial
%
% All timing and visual parameters are configurable in setup_param.m

% Clear workspace and close any open windows
clear all; close all; sca;

% Add general experiments folder to path for utility functions
% Use relative path from current file location
scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fullfile(scriptDir, '..', '..');
vpixxPath = fullfile(projectRoot, 'experiments', 'general', 'vpixx-utilities');
addpath(vpixxPath);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEBUG CONFIGURATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Centralized debug settings - modify these to control experiment behavior
debugConfig = struct();
debugConfig.enabled = 1;              % 1 = debug mode, 0 = production mode
debugConfig.useVPixx = 1;             % 1 = use VPixx hardware, 0 = use keyboard
debugConfig.fullscreen = 1;            % 1 = fullscreen, 0 = windowed mode
debugConfig.skipSyncTests = 1;       % 1 = skip sync tests, 0 = run sync tests
debugConfig.displayMode = 1;          % 1 = NYUAD lab, 2 = laptop/development
debugConfig.manualTrigger = 1;        % 1 = manual trigger (5 or t), 0 = scanner trigger
debugConfig.buttonbox = 1;        % 1 = button box, 0 = keyboard
debugConfig.eyetracking = 1;       % 1 = enable Eyelink, 0 = disable

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETUP DISPLAY AND EXPERIMENT PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Setup display with debug configuration
VP = setup_display(debugConfig);

% Setup experiment parameters
[VP, pa] = setup_param(VP, debugConfig);

% Setup keyboard mappings
kb = setup_keyboard();

% Add Eyetracking directory to path
eyetrackingDir = fullfile(fileparts(mfilename('fullpath')), 'Eyetracking');
addpath(eyetrackingDir);

% Initialize eyetracking (following reference pattern exactly)
if debugConfig.eyetracking
    el = initEyetracking(VP, pa);
    if isempty(el)
        pa.eyeTrackingEnabled = 0;
    else
        pa.eyeTrackingEnabled = 1;
    end
else
    el = [];
    pa.eyeTrackingEnabled = 0;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% START EXPERIMENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try
    % Calibration (following reference pattern - called before experiment starts)
    if exist('el','var') && ~isempty(el)
        [~, exitFlag] = initEyelinkStates('calibrate', VP.window, el);
        if exitFlag
            fprintf('\nCalibration failed or was cancelled. Disabling eye tracking.\n');
            el = [];
            pa.eyeTrackingEnabled = 0;
        end
    end
    
    % Wait for scanner trigger or manual trigger (displays message on screen)
    wait_trigger(VP, debugConfig.manualTrigger);
    if exist('el','var') && ~isempty(el)
        err = Eyelink('CheckRecording');
        if err ~= 0
            initEyelinkStates('startrecording', VP.window, el);
            fprintf('Eyelink now recording ..\n');
        end
    end

    experimentStartTime = GetSecs;
    fprintf('\n=== %s ===\n', pa.experimentName);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAIN EXPERIMENT LOOP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Initialize fixation angle (starts at 0 radians)
    currentFixationAngle = 0;

    % Setup KbQueue once for efficient button detection throughout experiment
    KbQueueCreate();
    KbQueueStart();

    % Display input method
    if ~debugConfig.buttonbox
        fprintf('\nDEBUG MODE - Keyboard Controls:\n');
        fprintf('  Press 1 = White\n');
        fprintf('  Press 2 = Red\n');
        fprintf('  Press 3 = Yellow\n');
        fprintf('  Press 4 = Green\n');
        fprintf('  Press 5 = Blue\n');
        fprintf('  Press ESC = Abort experiment\n\n');
    else
        fprintf('\nSCANNER MODE - Use VPixx button box\n');
        fprintf('  Press ESC = Abort experiment\n\n');
    end

% Main trial-based loop - run exactly pa.nTrials trials
for trialIdx = 1:pa.nTrials
    pa.trialCounter = pa.trialCounter + 1;
    trialStartTime = GetSecs;

    % Check for ESC key to abort experiment using KbQueue
    [pressed, firstPress] = KbQueueCheck();
    if pressed && firstPress(kb.escKey)
        fprintf('\n*** Experiment terminated by user (ESC pressed) ***\n');
        break;
    end

    % Get target color from predefined sequence
    targetColor = pa.colorSequence{trialIdx};
    
    % Store trial data (use direct indexing with pre-allocated arrays)
    pa.data.trialNumber(pa.trialCounter) = pa.trialCounter;
    pa.data.targetColor{pa.trialCounter} = targetColor;
    pa.data.trialStartTime(pa.trialCounter) = trialStartTime - experimentStartTime;
    pa.data.cumulativeTime(pa.trialCounter) = trialStartTime - experimentStartTime;
    pa.data.fixationAngle(pa.trialCounter) = currentFixationAngle;

    fprintf('Trial %d/%d: Target = %s\n', pa.trialCounter, pa.nTrials, targetColor);
    
    % Phase 1: Show single dot + moving fixation (1 second)
    targetIdx = find(strcmp(targetColor, pa.colors));
    stimulusStartTime = GetSecs;
    stimulusEndTime = stimulusStartTime + pa.stimulusDuration;
    vbl = stimulusStartTime;
    if exist('el','var') && ~isempty(el)
        try
            Eyelink('Message', sprintf('TRIAL_%d_STIMULUS_ONSET_%s', pa.trialCounter, upper(targetColor)));
            % Record one gaze sample at stimulus onset
            s = Eyelink('newestfloatsample');
            gx = NaN; gy = NaN;
            if ~isempty(s)
                lx = s.gx(1); ly = s.gy(1);
                rx = s.gx(2); ry = s.gy(2);
                if ~isnan(lx) && ~isnan(ly)
                    gx = lx; gy = ly;
                elseif ~isnan(rx) && ~isnan(ry)
                    gx = rx; gy = ry;
                end
            end
            pa.data.gazeX(pa.trialCounter) = gx;
            pa.data.gazeY(pa.trialCounter) = gy;
        catch
        end
    end

    while GetSecs < stimulusEndTime
        % Update traveling dot position continuously
        currentTime = GetSecs;
        currentFixationAngle = pa.fixationSpeed * (currentTime - experimentStartTime);

        % Draw stimulus: circular path (cued color) + traveling dot (white)
        drawCircleWithDot(VP.window, VP.windowCenter, pa.fixationRadiusPix, currentFixationAngle, ...
                         pa.travelingDotRadiusPix, pa.dotColor, pa.colorRGB(targetIdx,:), ...
                         pa.circleLineWidth, VP.backGroundColor);

        % Use optimized flip timing for smooth animation
        vbl = Screen('Flip', VP.window, vbl + 0.5 * VP.ifi);
    end
    
    % Phase 2: Wait for response
    responseStartTime = GetSecs;
    responseReceived = false;
    responseTime = NaN;
    responseButton = '';
    vbl = responseStartTime;

    % Flush KbQueue to ignore any previous button presses
    KbQueueFlush();

    while (GetSecs - responseStartTime) < pa.responseWindow
        % Update traveling dot position
        currentTime = GetSecs;
        currentFixationAngle = pa.fixationSpeed * (currentTime - experimentStartTime);

        % Draw circular path (black) + traveling dot (white) during response phase
        drawCircleWithDot(VP.window, VP.windowCenter, pa.fixationRadiusPix, currentFixationAngle, ...
                         pa.travelingDotRadiusPix, pa.dotColor, pa.circleColorDefault, ...
                         pa.circleLineWidth, VP.backGroundColor);

        vbl = Screen('Flip', VP.window, vbl + 0.5 * VP.ifi);

        % Check for button press using KbQueue (only record first response)
        if ~responseReceived
                if ~debugConfig.buttonbox
                    % Check keyboard keys 1-5 for colors
                    [pressed, firstPress] = KbQueueCheck();
                    if pressed
                    [responseReceived, responseButton, responseTime] = ...
                        check_response(kb, firstPress, responseStartTime);
                    end
                else
                    % Use VPixx button box
                    pair = getButtonColor([], false);
                    if ~isempty(pair)
                        responseReceived = true;
                        responseTime = GetSecs - responseStartTime;
                        responseButton = pair{2}; % Get color from response
                    end
                end         
        end
    end

    % Record response data (use direct indexing with pre-allocated arrays)
    if responseReceived
        pa.data.response{pa.trialCounter} = responseButton;
        pa.data.reactionTime(pa.trialCounter) = responseTime;
        pa.data.correct(pa.trialCounter) = strcmp(responseButton, targetColor);
    else
        pa.data.response{pa.trialCounter} = 'no_response';
        pa.data.reactionTime(pa.trialCounter) = NaN;
        pa.data.correct(pa.trialCounter) = 0;
    end

    % Phase 3: Feedback
    feedbackStartTime = GetSecs;
    feedbackEndTime = feedbackStartTime + pa.feedbackDuration;
    vbl = feedbackStartTime;

    while GetSecs < feedbackEndTime
        % Update traveling dot position
        currentTime = GetSecs;
        currentFixationAngle = pa.fixationSpeed * (currentTime - experimentStartTime);

        % Choose traveling dot color based on correctness
        if responseReceived
            if pa.data.correct(pa.trialCounter)
                feedbackDotColor = pa.dotColorCorrect; % Green for correct
            else
                feedbackDotColor = pa.dotColorIncorrect; % Red for incorrect
            end
        else
            feedbackDotColor = pa.dotColorIncorrect; % Red for no response
        end

        % Draw circular path (black) + traveling dot (colored for feedback)
        drawCircleWithDot(VP.window, VP.windowCenter, pa.fixationRadiusPix, currentFixationAngle, ...
                         pa.travelingDotRadiusPix, feedbackDotColor, pa.circleColorDefault, ...
                         pa.circleLineWidth, VP.backGroundColor);

        % Use optimized flip timing for smooth animation
        vbl = Screen('Flip', VP.window, vbl + 0.5 * VP.ifi);
    end

    % Phase 4: Inter-trial interval
    itiStartTime = GetSecs;
    itiEndTime = itiStartTime + pa.itiDuration;
    vbl = itiStartTime;

    while GetSecs < itiEndTime
        % Update traveling dot position
        currentTime = GetSecs;
        currentFixationAngle = pa.fixationSpeed * (currentTime - experimentStartTime);

        % Draw circular path (black) + traveling dot (white) during ITI
        drawCircleWithDot(VP.window, VP.windowCenter, pa.fixationRadiusPix, currentFixationAngle, ...
                         pa.travelingDotRadiusPix, pa.dotColor, pa.circleColorDefault, ...
                         pa.circleLineWidth, VP.backGroundColor);

        % Use optimized flip timing for smooth animation
        vbl = Screen('Flip', VP.window, vbl + 0.5 * VP.ifi);
    end
    
    % Print trial result
    if responseReceived
        fprintf('  Response: %s, RT: %.3fs, Correct: %d\n', ...
                responseButton, responseTime, pa.data.correct(pa.trialCounter));
    else
        fprintf('  No response received\n');
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% END EXPERIMENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Trim pre-allocated arrays to actual number of trials completed
    nCompleted = pa.trialCounter;
    pa.data.trialNumber = pa.data.trialNumber(1:nCompleted);
    pa.data.targetColor = pa.data.targetColor(1:nCompleted);
    pa.data.response = pa.data.response(1:nCompleted);
    pa.data.correct = pa.data.correct(1:nCompleted);
    pa.data.reactionTime = pa.data.reactionTime(1:nCompleted);
    pa.data.trialStartTime = pa.data.trialStartTime(1:nCompleted);
    pa.data.cumulativeTime = pa.data.cumulativeTime(1:nCompleted);
    pa.data.fixationAngle = pa.data.fixationAngle(1:nCompleted);
    pa.data.gazeX = pa.data.gazeX(1:nCompleted);
    pa.data.gazeY = pa.data.gazeY(1:nCompleted);

    % End screen - show circular path with moving traveling dot (no stimulus)
    endScreenStartTime = GetSecs;
    endScreenEndTime = endScreenStartTime + pa.endScreenDuration;
    vbl = endScreenStartTime;

    while GetSecs < endScreenEndTime
        % Update traveling dot position
        currentTime = GetSecs;
        currentFixationAngle = pa.fixationSpeed * (currentTime - experimentStartTime);

        % Draw circular path (black) + traveling dot (white)
        drawCircleWithDot(VP.window, VP.windowCenter, pa.fixationRadiusPix, currentFixationAngle, ...
                         pa.travelingDotRadiusPix, pa.dotColor, pa.circleColorDefault, ...
                         pa.circleLineWidth, VP.backGroundColor);

        % Use optimized flip timing for smooth animation
        vbl = Screen('Flip', VP.window, vbl + 0.5 * VP.ifi);
    end

    % Stop and save Eyelink data (guarded)
    if exist('el','var') && ~isempty(el)
        initEyelinkStates('eyestop', VP.window, {pa.eyeFileBase, pa.eyeDataDir});
    end

catch ME
    % Error occurred - display detailed message
    fprintf('\n!!! ERROR OCCURRED !!!\n');
    fprintf('Error message: %s\n', ME.message);
    if ~isempty(ME.stack)
        fprintf('Error in: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
        % Print full stack trace
        fprintf('\nStack trace:\n');
        for i = 1:length(ME.stack)
            fprintf('  %d. %s (line %d)\n', i, ME.stack(i).name, ME.stack(i).line);
        end
    end
end

% Clean up resources (always executed)
fprintf('\nCleaning up resources...\n');

% Clean up keyboard queue
try
    KbQueueStop();
    KbQueueRelease();
    fprintf('  Keyboard queue released\n');
catch ME
    fprintf('  Warning: Could not release keyboard queue: %s\n', ME.message);
end

% Close Psychtoolbox windows
try
    sca; % Screen('CloseAll')
    fprintf('  Psychtoolbox windows closed\n');
catch ME
    fprintf('  Warning: Could not close Psychtoolbox windows: %s\n', ME.message);
end

% Close VPixx connection
try
    if Datapixx('IsReady')
        Datapixx('Close');
        fprintf('  VPixx connection closed\n');
    end
catch ME
    fprintf('  Warning: Could not close VPixx connection: %s\n', ME.message);
end

fprintf('Cleanup complete.\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CALCULATE AND DISPLAY RESULTS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Calculate final metrics
totalExperimentTime = GetSecs - experimentStartTime;
nTrials = pa.trialCounter;
nCorrect = sum(pa.data.correct);
accuracy = nCorrect / nTrials * 100;

fprintf('\n=== EXPERIMENT COMPLETE ===\n');
fprintf('Total trials completed: %d\n', nTrials);
fprintf('Total experiment time: %.2f seconds (%.2f minutes)\n', totalExperimentTime, totalExperimentTime/60);
fprintf('Results Summary:\n');
fprintf('Target Color\tResponse\n');
fprintf('------------\t--------\n');

for i = 1:nTrials
    fprintf('%s\t\t%s\n', pa.data.targetColor{i}, pa.data.response{i});
end

fprintf('\nOverall Accuracy: %d out of %d (%.1f%%)\n', nCorrect, nTrials, accuracy);

% Store total experiment time in data structure
pa.totalExperimentTime = totalExperimentTime;

% Save data
save(pa.dataFileName, 'pa');
fprintf('Data saved to %s\n', pa.dataFileName);

% Optional: visualize eye tracking if enabled
if isfield(pa, 'eyeTrackingEnabled') && pa.eyeTrackingEnabled
    fprintf('Generating eye tracking visualization...\n');
    try
        visualize_eyetracking(pa.dataFileName);
    catch ME
        warning(ME.identifier, '%s', ME.message);
    end
end

end

% Helper function to draw circular path with traveling dot (no stimulus)
function drawCircleWithDot(window, screenCenter, circleRadiusPix, dotAngle, dotSize, dotColor, circleColor, circleLineWidth, backGroundColor)
% DRAW_CIRCLE_WITH_DOT - Draw circular path outline with traveling dot
%
% Inputs:
%   window - Psychtoolbox window pointer
%   screenCenter - [x, y] center of screen
%   circleRadiusPix - radius of circular path in pixels
%   dotAngle - current angle of traveling dot in radians
%   dotSize - size of traveling dot in pixels
%   dotColor - color of traveling dot [R, G, B]
%   circleColor - color of circular path outline [R, G, B]
%   circleLineWidth - thickness of circular path outline
%   backGroundColor - background color

% Clear screen
Screen('FillRect', window, backGroundColor);

% Draw circular path outline
Screen('FrameOval', window, circleColor * 255, ...
       [screenCenter(1)-circleRadiusPix, screenCenter(2)-circleRadiusPix, ...
        screenCenter(1)+circleRadiusPix, screenCenter(2)+circleRadiusPix], ...
       circleLineWidth);

% Calculate traveling dot position on circular path
dotX = screenCenter(1) + circleRadiusPix * cos(dotAngle);
dotY = screenCenter(2) + circleRadiusPix * sin(dotAngle);

% Draw traveling dot
Screen('FillOval', window, dotColor * 255, ...
       [dotX-dotSize, dotY-dotSize, dotX+dotSize, dotY+dotSize]);
end


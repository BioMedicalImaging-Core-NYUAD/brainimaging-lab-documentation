function main()
% MAIN - Simple button-pressing experiment with colored dots
% 
% This experiment presents 10 trials where participants see 5 colored dots
% (white, red, yellow, green, blue) and must press the corresponding button
% on the VPixx response box.5
%
% Trial structure:
% 1. Fixation cross + 5 colored dots (1 second)
% 2. Target dot stays, others disappear (1 second) 
% 3. All dots disappear, participant responds (2 seconds)
% 4. Feedback (fixation turns green if correct)
% 5. Blank screen (1 second)
% 6. Next trial

% Clear workspace and close any open windows
clear all; close all; sca;

% Add general experiments folder to path for utility functions
addpath('/Users/pw1246/Documents/GitHub/brainimaging-lab-documentation/experiments/general/vpixx-utilities');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEBUG CONFIGURATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Centralized debug settings - modify these to control experiment behavior
debugConfig = struct();
debugConfig.enabled = 1;              % 1 = debug mode, 0 = production mode
debugConfig.useVPixx = 1;             % 1 = use VPixx hardware, 0 = use keyboard
debugConfig.fullscreen = 1;            % 1 = fullscreen, 0 = windowed mode
debugConfig.skipSyncTests = 1;         % 1 = skip sync tests, 0 = run sync tests
debugConfig.displayMode = 1;          % 1 = NYUAD lab, 2 = laptop/development
debugConfig.manualTrigger = 1;        % 1 = manual trigger (5 or t), 0 = scanner trigger

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETUP DISPLAY AND EXPERIMENT PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Setup display with debug configuration
VP = setup_display(debugConfig);

% Setup experiment parameters
[VP, pa] = setup_param(VP, debugConfig);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% START EXPERIMENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try
    experimentStartTime = GetSecs;
    fprintf('\n=== %s ===\n', pa.experimentName);

    % Wait for scanner trigger or manual trigger
    wait_trigger(debugConfig.manualTrigger);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAIN EXPERIMENT LOOP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Initialize fixation angle (starts at 0 radians)
    currentFixationAngle = 0;

    % Setup KbQueue once for efficient button detection throughout experiment
    KbQueueCreate();
    KbQueueStart();

    % Main time-based loop
    experimentEndTime = experimentStartTime + pa.totalDuration;

    % Display input method
    if debugConfig.enabled
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

while GetSecs < experimentEndTime
    pa.trialCounter = pa.trialCounter + 1;
    trialStartTime = GetSecs;

    % Check for ESC key to abort experiment
    [~, ~, keyCode] = KbCheck(-1);
    if keyCode(KbName('ESCAPE'))
        fprintf('\n*** Experiment terminated by user (ESC pressed) ***\n');
        break;
    end

    % Calculate remaining time
    remainingTime = experimentEndTime - GetSecs;
    if remainingTime <= 0
        break; % Exit if time is up
    end
    
    % Choose target color from predefined sequence
    if pa.trialCounter <= pa.nTrials
        targetColor = pa.colorSequence{pa.trialCounter};
    else
        % If we exceed planned trials, cycle through colors
        colorIdx = mod(pa.trialCounter - 1, length(pa.colors)) + 1;
        targetColor = pa.colors{colorIdx};
    end
    
    % Store trial data (use direct indexing with pre-allocated arrays)
    pa.data.trialNumber(pa.trialCounter) = pa.trialCounter;
    pa.data.targetColor{pa.trialCounter} = targetColor;
    pa.data.trialStartTime(pa.trialCounter) = trialStartTime - experimentStartTime;
    pa.data.cumulativeTime(pa.trialCounter) = trialStartTime - experimentStartTime;
    pa.data.fixationAngle(pa.trialCounter) = currentFixationAngle;
    
    fprintf('Trial %d: Target = %s (%.1fs remaining)\n', pa.trialCounter, targetColor, remainingTime);
    
    % Phase 1: Show single dot + moving fixation (1 second)
    targetIdx = find(strcmp(targetColor, pa.colors));
    stimulusStartTime = GetSecs;
    stimulusEndTime = stimulusStartTime + pa.stimulusDuration;
    vbl = stimulusStartTime;

    while GetSecs < stimulusEndTime && GetSecs < experimentEndTime
        % Update fixation position continuously
        currentTime = GetSecs;
        currentFixationAngle = pa.fixationSpeed * (currentTime - experimentStartTime);

        % Draw stimulus with current fixation position
        drawSingleDotStimulus(VP.window, pa.dotCenter, pa.colorRGB(targetIdx,:), pa.dotRadiusPix, ...
                             VP.windowCenter, pa.fixationRadiusPix, currentFixationAngle, ...
                             pa.fixationSize, pa.fixationThickness, pa.fixColor, VP.backGroundColor);

        % Use optimized flip timing for smooth animation
        vbl = Screen('Flip', VP.window, vbl + 0.5 * VP.ifi);
    end
    
    % Check if experiment should end
    if GetSecs >= experimentEndTime
        break;
    end
    
    % Phase 2: Wait for response
    responseStartTime = GetSecs;
    responseReceived = false;
    responseTime = NaN;
    responseButton = '';
    vbl = responseStartTime;

    % Flush KbQueue to ignore any previous button presses
    KbQueueFlush();

    while (GetSecs - responseStartTime) < pa.responseWindow && GetSecs < experimentEndTime
        % Update fixation position
        currentTime = GetSecs;
        currentFixationAngle = pa.fixationSpeed * (currentTime - experimentStartTime);

        % Draw only fixation during response phase (no dots)
        drawFixationOnly(VP.window, VP.windowCenter, pa.fixationRadiusPix, currentFixationAngle, ...
                        pa.fixationSize, pa.fixationThickness, pa.fixColor, VP.backGroundColor);

        % Use optimized flip timing for smooth animation
        vbl = Screen('Flip', VP.window, vbl + 0.5 * VP.ifi);

        % Check for button press using KbQueue
        [pressed, firstPress] = KbQueueCheck();
        if pressed
            if debugConfig.enabled
                % DEBUG MODE: Check keyboard keys 1-5 for colors using KbQueue
                % 1=white, 2=red, 3=yellow, 4=green, 5=blue
                if firstPress(KbName('1!'))
                    responseButton = 'white';
                    responseReceived = true;
                    responseTime = firstPress(KbName('1!')) - responseStartTime;
                elseif firstPress(KbName('2@'))
                    responseButton = 'red';
                    responseReceived = true;
                    responseTime = firstPress(KbName('2@')) - responseStartTime;
                elseif firstPress(KbName('3#'))
                    responseButton = 'yellow';
                    responseReceived = true;
                    responseTime = firstPress(KbName('3#')) - responseStartTime;
                elseif firstPress(KbName('4$'))
                    responseButton = 'green';
                    responseReceived = true;
                    responseTime = firstPress(KbName('4$')) - responseStartTime;
                elseif firstPress(KbName('5%'))
                    responseButton = 'blue';
                    responseReceived = true;
                    responseTime = firstPress(KbName('5%')) - responseStartTime;
                end

                if responseReceived
                    break;
                end
            else
                % SCANNER MODE: Use VPixx button box
                pair = getButtonColor(pa.buttonSelection, false);
                if ~isempty(pair)
                    responseReceived = true;
                    responseTime = GetSecs - responseStartTime;
                    responseButton = pair{2}; % Get color from response
                    break;
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
    
    % Check if experiment should end
    if GetSecs >= experimentEndTime
        break;
    end
    
    % Phase 3: Feedback
    feedbackStartTime = GetSecs;
    feedbackEndTime = feedbackStartTime + pa.feedbackDuration;
    vbl = feedbackStartTime;

    while GetSecs < feedbackEndTime && GetSecs < experimentEndTime
        % Update fixation position
        currentTime = GetSecs;
        currentFixationAngle = pa.fixationSpeed * (currentTime - experimentStartTime);

        % Choose fixation color based on correctness
        if responseReceived
            if pa.data.correct(end)
                fixColor = pa.fixColorCorrect;
            else
                fixColor = pa.fixColorIncorrect;
            end
        else
            fixColor = pa.fixColorIncorrect; % No response = incorrect
        end

        % Draw only fixation during feedback phase (no dots, colored fixation)
        drawFixationOnly(VP.window, VP.windowCenter, pa.fixationRadiusPix, currentFixationAngle, ...
                        pa.fixationSize, pa.fixationThickness, fixColor, VP.backGroundColor);

        % Use optimized flip timing for smooth animation
        vbl = Screen('Flip', VP.window, vbl + 0.5 * VP.ifi);
    end
    
    % Check if experiment should end
    if GetSecs >= experimentEndTime
        break;
    end
    
    % Phase 4: Inter-trial interval
    itiStartTime = GetSecs;
    itiEndTime = itiStartTime + pa.itiDuration;
    vbl = itiStartTime;

    while GetSecs < itiEndTime && GetSecs < experimentEndTime
        % Update fixation position
        currentTime = GetSecs;
        currentFixationAngle = pa.fixationSpeed * (currentTime - experimentStartTime);

        % Draw only moving fixation (no dot)
        fixationX = VP.windowCenter(1) + pa.fixationRadiusPix * cos(currentFixationAngle);
        fixationY = VP.windowCenter(2) + pa.fixationRadiusPix * sin(currentFixationAngle);
        Screen('FillRect', VP.window, VP.backGroundColor);
        drawFixation(VP.window, fixationX, fixationY, pa.fixationSize, pa.fixationThickness, pa.fixColor);

        % Use optimized flip timing for smooth animation
        vbl = Screen('Flip', VP.window, vbl + 0.5 * VP.ifi);
    end
    
    % Print trial result
    if responseReceived
        fprintf('  Response: %s, RT: %.3fs, Correct: %d\n', ...
                responseButton, responseTime, pa.data.correct(end));
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

    % End screen - static fixation
    Screen('FillRect', VP.window, VP.backGroundColor);
    drawFixation(VP.window, VP.windowCenter(1), VP.windowCenter(2), pa.fixationSize, pa.fixationThickness, pa.fixColor);
    Screen('Flip', VP.window);
    WaitSecs(pa.endScreenDuration);

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
nTrials = pa.trialCounter;
nCorrect = sum(pa.data.correct);
accuracy = nCorrect / nTrials * 100;

fprintf('\n=== EXPERIMENT COMPLETE ===\n');
fprintf('Total trials completed: %d\n', nTrials);
fprintf('Total experiment time: %.1f seconds\n', GetSecs - experimentStartTime);
fprintf('Results Summary:\n');
fprintf('Target Color\tResponse\n');
fprintf('------------\t--------\n');

for i = 1:nTrials
    fprintf('%s\t\t%s\n', pa.data.targetColor{i}, pa.data.response{i});
end

fprintf('\nOverall Accuracy: %d out of %d (%.1f%%)\n', nCorrect, nTrials, accuracy);

% Save data
save(pa.dataFileName, 'pa');
fprintf('Data saved to %s\n', pa.dataFileName);

end

% Helper function to draw single dot with moving fixation
function drawFixationOnly(window, screenCenter, fixationRadiusPix, fixationAngle, fixSize, fixThickness, fixColor, backGroundColor)
% DRAW_FIXATION_ONLY - Draw only the moving fixation cross without any dots
%
% Inputs:
%   window - Psychtoolbox window pointer
%   screenCenter - [x, y] center of screen
%   fixationRadiusPix - radius of fixation movement in pixels
%   fixationAngle - current angle of fixation in radians
%   fixSize - size of fixation cross
%   fixThickness - thickness of fixation lines
%   fixColor - color of fixation cross [R, G, B]
%   backGroundColor - background color

% Clear screen
Screen('FillRect', window, backGroundColor);

% Calculate fixation position
fixationX = screenCenter(1) + fixationRadiusPix * cos(fixationAngle);
fixationY = screenCenter(2) + fixationRadiusPix * sin(fixationAngle);

% Draw fixation cross
Screen('DrawLine', window, fixColor, ...
       fixationX - fixSize/2, fixationY, fixationX + fixSize/2, fixationY, fixThickness);
Screen('DrawLine', window, fixColor, ...
       fixationX, fixationY - fixSize/2, fixationX, fixationY + fixSize/2, fixThickness);
end

% Helper function to draw single dot with moving fixation
function drawSingleDotStimulus(window, dotCenter, dotColor, dotRadiusPix, screenCenter, fixationRadiusPix, fixationAngle, fixSize, fixThickness, fixColor, backGroundColor)
% DRAW_SINGLE_DOT_STIMULUS - Draw single dot with moving fixation cross
%
% Inputs:
%   window - Psychtoolbox window pointer
%   dotCenter - [x, y] center of dot
%   dotColor - color of dot [R, G, B]
%   dotRadiusPix - radius of dot in pixels
%   screenCenter - [x, y] center of screen
%   fixationRadiusPix - radius of fixation movement in pixels
%   fixationAngle - current angle of fixation in radians
%   fixSize - size of fixation cross
%   fixThickness - thickness of fixation lines
%   fixColor - color of fixation cross [R, G, B]
%   backGroundColor - background color

% Clear screen with background color
Screen('FillRect', window, backGroundColor);

% Draw single dot at center
Screen('FillOval', window, dotColor, ...
       [dotCenter(1)-dotRadiusPix, dotCenter(2)-dotRadiusPix, ...
        dotCenter(1)+dotRadiusPix, dotCenter(2)+dotRadiusPix]);

% Calculate fixation position on circular path
fixationX = screenCenter(1) + fixationRadiusPix * cos(fixationAngle);
fixationY = screenCenter(2) + fixationRadiusPix * sin(fixationAngle);

% Draw fixation cross at calculated position
Screen('DrawLine', window, fixColor, ...
       fixationX - fixSize/2, fixationY, fixationX + fixSize/2, fixationY, fixThickness);
Screen('DrawLine', window, fixColor, ...
       fixationX, fixationY - fixSize/2, fixationX, fixationY + fixSize/2, fixThickness);
end


% Helper function to draw fixation cross
function drawFixation(window, centerX, centerY, fixSize, fixThickness, color)
    % Horizontal line
    Screen('FillRect', window, color, ...
           [centerX-fixSize, centerY-fixThickness/2, ...
            centerX+fixSize, centerY+fixThickness/2]);
    % Vertical line
    Screen('FillRect', window, color, ...
           [centerX-fixThickness/2, centerY-fixSize, ...
            centerX+fixThickness/2, centerY+fixSize]);
end

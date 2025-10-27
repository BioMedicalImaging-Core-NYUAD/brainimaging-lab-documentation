function main()
% MAIN - Simple button-pressing experiment with colored dots
% 
% This experiment presents 10 trials where participants see 5 colored dots
% (white, red, yellow, green, blue) and must press the corresponding button
% on the VPixx response box.
%
% Trial structure:
% 1. Fixation cross + 5 colored dots (1 second)
% 2. Target dot stays, others disappear (1 second) 
% 3. All dots reappear, participant responds (2 seconds max)
% 4. Feedback (dot disappears 200ms, fixation turns green if correct)
% 5. Blank screen (1 second)
% 6. Next trial

% Clear workspace and close any open windows
clear all; close all; sca;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETUP DISPLAY AND EXPERIMENT PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Setup display (skipSync=1, Display=2 for laptop, debugTrigger=0)
VP = setup_display(1, 2, 0);

% Setup experiment parameters
[VP, pa] = setup_param(VP);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% START EXPERIMENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try
    experimentStartTime = GetSecs;
    fprintf('\n=== %s ===\n', pa.experimentName);

    % Wait for scanner trigger or manual trigger
    wait_trigger(pa.debugMode);

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
    fprintf('Experiment will run for %.1f seconds\n', pa.totalDuration);
    fprintf('Each cycle: %.1fs stimulus + %.1fs response + %.1fs feedback + %.1fs ITI = %.1fs total\n', ...
            pa.stimulusDuration, pa.responseWindow, pa.feedbackDuration, pa.itiDuration, pa.trialCycleDuration);

    % Display input method
    if pa.debugMode
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
    
    % Store trial data
    pa.data.trialNumber(end+1) = pa.trialCounter;
    pa.data.targetColor{end+1} = targetColor;
    pa.data.trialStartTime(end+1) = trialStartTime - experimentStartTime;
    pa.data.cumulativeTime(end+1) = trialStartTime - experimentStartTime;
    pa.data.fixationAngle(end+1) = currentFixationAngle;
    
    fprintf('Trial %d: Target = %s (%.1fs remaining)\n', pa.trialCounter, targetColor, remainingTime);
    
    % Phase 1: Show single dot + moving fixation (1 second)
    targetIdx = find(strcmp(targetColor, pa.colors));
    stimulusStartTime = GetSecs;
    stimulusEndTime = stimulusStartTime + pa.stimulusDuration;
    
    while GetSecs < stimulusEndTime && GetSecs < experimentEndTime
        % Update fixation position continuously
        currentTime = GetSecs;
        currentFixationAngle = pa.fixationSpeed * (currentTime - experimentStartTime);
        
        % Draw stimulus with current fixation position
        drawSingleDotStimulus(VP.window, pa.dotCenter, pa.colorRGB(targetIdx,:), pa.dotRadiusPix, ...
                             VP.windowCenter, pa.fixationRadiusPix, currentFixationAngle, ...
                             pa.fixationSize, pa.fixationThickness, pa.fixColor, VP.backGroundColor);
        Screen('Flip', VP.window);
        
        % Small delay for smooth fixation movement
        WaitSecs(0.016); % ~60 FPS
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

    % Flush KbQueue to ignore any previous button presses
    KbQueueFlush();

    while (GetSecs - responseStartTime) < pa.responseWindow && GetSecs < experimentEndTime
        % Update fixation position
        currentTime = GetSecs;
        currentFixationAngle = pa.fixationSpeed * (currentTime - experimentStartTime);
        
        % Draw stimulus with moving fixation
        drawSingleDotStimulus(VP.window, pa.dotCenter, pa.colorRGB(targetIdx,:), pa.dotRadiusPix, ...
                             VP.windowCenter, pa.fixationRadiusPix, currentFixationAngle, ...
                             pa.fixationSize, pa.fixationThickness, pa.fixColor, VP.backGroundColor);
        Screen('Flip', VP.window);

        % Check for button press using KbQueue
        [pressed, firstPress] = KbQueueCheck();
        if pressed
            if pa.debugMode
                % DEBUG MODE: Check keyboard keys 1-5 for colors
                % 1=white, 2=red, 3=yellow, 4=green, 5=blue
                [~, ~, keyCode] = KbCheck(-1);
                if keyCode(KbName('1!'))
                    responseButton = 'white';
                    responseReceived = true;
                elseif keyCode(KbName('2@'))
                    responseButton = 'red';
                    responseReceived = true;
                elseif keyCode(KbName('3#'))
                    responseButton = 'yellow';
                    responseReceived = true;
                elseif keyCode(KbName('4$'))
                    responseButton = 'green';
                    responseReceived = true;
                elseif keyCode(KbName('5%'))
                    responseButton = 'blue';
                    responseReceived = true;
                end

                if responseReceived
                    responseTime = GetSecs - responseStartTime;
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
        
        % Small delay for smooth animation
        WaitSecs(0.016);
    end

    % Record response data
    if responseReceived
        pa.data.response{end+1} = responseButton;
        pa.data.reactionTime(end+1) = responseTime;
        pa.data.correct(end+1) = strcmp(responseButton, targetColor);
    else
        pa.data.response{end+1} = 'no_response';
        pa.data.reactionTime(end+1) = NaN;
        pa.data.correct(end+1) = 0;
    end
    
    % Check if experiment should end
    if GetSecs >= experimentEndTime
        break;
    end
    
    % Phase 3: Feedback (2 seconds)
    feedbackStartTime = GetSecs;
    feedbackEndTime = feedbackStartTime + pa.feedbackDuration;
    
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
        
        % Draw stimulus with colored fixation
        drawSingleDotStimulus(VP.window, pa.dotCenter, pa.colorRGB(targetIdx,:), pa.dotRadiusPix, ...
                             VP.windowCenter, pa.fixationRadiusPix, currentFixationAngle, ...
                             pa.fixationSize, pa.fixationThickness, fixColor, VP.backGroundColor);
        Screen('Flip', VP.window);
        
        % Small delay
        WaitSecs(0.016);
    end
    
    % Check if experiment should end
    if GetSecs >= experimentEndTime
        break;
    end
    
    % Phase 4: Inter-trial interval (1 second)
    itiStartTime = GetSecs;
    itiEndTime = itiStartTime + pa.itiDuration;
    
    while GetSecs < itiEndTime && GetSecs < experimentEndTime
        % Update fixation position
        currentTime = GetSecs;
        currentFixationAngle = pa.fixationSpeed * (currentTime - experimentStartTime);
        
        % Draw only moving fixation (no dot)
        fixationX = VP.windowCenter(1) + pa.fixationRadiusPix * cos(currentFixationAngle);
        fixationY = VP.windowCenter(2) + pa.fixationRadiusPix * sin(currentFixationAngle);
        Screen('FillRect', VP.window, VP.backGroundColor);
        drawFixation(VP.window, fixationX, fixationY, pa.fixationSize, pa.fixationThickness, pa.fixColor);
        Screen('Flip', VP.window);
        
        % Small delay
        WaitSecs(0.016);
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
    % End screen - static fixation for 5 seconds
    Screen('FillRect', VP.window, VP.backGroundColor);
    drawFixation(VP.window, VP.windowCenter(1), VP.windowCenter(2), pa.fixationSize, pa.fixationThickness, pa.fixColor);
    Screen('Flip', VP.window);
    WaitSecs(5.0);

catch ME
    % Error occurred - display message
    fprintf('\n!!! ERROR OCCURRED !!!\n');
    fprintf('Error message: %s\n', ME.message);
    fprintf('Error in: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
end

% Clean up resources (always executed)
try
    KbQueueStop();
    KbQueueRelease();
catch
    % KbQueue might not be initialized
end
sca; % Screen('CloseAll')
try
    Datapixx('Close');
catch
    % Datapixx might not be open
end

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
function drawSingleDotStimulus(window, dotCenter, dotColor, dotRadiusPix, screenCenter, fixationRadiusPix, fixationAngle, fixSize, fixThickness, fixColor, backGroundColor)
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
    drawFixation(window, fixationX, fixationY, fixSize, fixThickness, fixColor);
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

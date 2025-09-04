function [startTime, endTime] = showImageBlockWindow(imagePath, fingerName)
% Presents a static image for a fixed duration, optimized for fMRI block designs.
%
% This function avoids a frame-by-frame loop, instead using GetSecs() for
% precise, time-based control of the stimulus duration. It presents the
% image with a single Screen('Flip'), waits for the block duration while
% checking for an exit key, and then returns.

    global screen;
    global parameters;
    global isTerminationKeyPressed;

    % Only run if the termination key has not been pressed
    if isTerminationKeyPressed
        startTime = -1; % Return invalid times if aborted
        endTime = -1;
        return;
    end

    % --- Preparation ---
    % Give this process maximum priority for precise timing
    topPriorityLevel = MaxPriority(screen.win);
    Priority(topPriorityLevel);

    % Load image file and create the texture
    try
        imgMatrix = imread(imagePath);
        scaleFactor = 0.3;
        imgMatrix = imresize(imgMatrix, scaleFactor);
        imageTexture = Screen('MakeTexture', screen.win, imgMatrix);
    catch
        % In case of error, clean up and exit gracefully
        Priority(0);
        error('Could not load image: %s', imagePath);
    end

    % --- Presentation ---
    % Draw the texture to the back buffer. It will not be visible yet.
    Screen('DrawTexture', screen.win, imageTexture);

    % Flip the screen to show the image. This command is the most critical
    % for timing. It executes at the next vertical retrace of the monitor.
    % The returned 'vbl' is a high-precision timestamp of when the flip occurred.
    [vbl, startTime] = Screen('Flip', screen.win);
    
    % Log the precise start time to the command window for debugging
    fprintf('Stimulus ON: %s \n', fingerName);

    % Calculate the target end time for the block
    endTime = startTime + parameters.stimulusDuration;

    % --- Wait for the block duration to elapse ---
    % Instead of a 'for' loop counting frames, we use a 'while' loop that
    % continuously checks the master clock (GetSecs). The image remains on
    % screen during this time.
    while GetSecs < endTime
        % Check for a quit key press (e.g., 'q')
        [keyIsDown, ~, keyCode] = KbCheck();
        if keyIsDown && (keyCode(KbName('q')) || keyCode(KbName('Q')))
            isTerminationKeyPressed = true;
            % The main experiment loop will handle the shutdown
            break; % Exit the while loop immediately
        end

        % VERY IMPORTANT: Give the CPU a tiny break.
        % Without this, the 'while' loop will hog 100% of a CPU core.
        % A 1 ms wait is more than enough to prevent this and has no
        % impact on timing precision for this purpose.
        WaitSecs(0.001);
    end

    % --- Clean Up for this Function ---
    % NOTE: The screen is NOT cleared here. The next call to Screen('Flip')
    % in your main script (e.g., to show a fixation cross) will replace the image.
    % This is standard practice.
    
    fprintf('Stimulus OFF: %s \n', fingerName);
    
    % Release the texture from memory
    Screen('Close', imageTexture);
    
    % Restore normal process priority
    Priority(0);
    
    % Flush any pending events
    FlushEvents;
end
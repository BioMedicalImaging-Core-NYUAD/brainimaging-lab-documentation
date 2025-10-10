function [startTime, endTime] = showImageBlockWindow(imagePath, fingerName)
% Presents a static image WITH A DYNAMIC PACING CUE for a fixed duration.
    startTime = GetSecs;
    global screen;
    global parameters;
    global isTerminationKeyPressed;
    
    if isTerminationKeyPressed
        startTime = -1;
        endTime = -1;
        return;
    end
    
    % --- Preparation ---
    topPriorityLevel = MaxPriority(screen.win);
    Priority(topPriorityLevel);
    
    try
        imgMatrix = imread(imagePath);
        scaleFactor = 0.3;
        imgMatrix = imresize(imgMatrix, scaleFactor);
        imageTexture = Screen('MakeTexture', screen.win, imgMatrix);
    catch
        Priority(0);
        error('Could not load image: %s', imagePath);
    end

    % --- Presentation ---
    % Get the start time and calculate the target end time
    
    endTime_c = startTime + parameters.stimulusDuration;
    % >> First, draw the background image texture on every frame
    Screen('DrawTexture', screen.win, imageTexture);
    Screen('Flip', screen.win);
    
    fprintf('Stimulus ON: %s \n', fingerName);
    oldTextSize = Screen('TextSize', screen.win);
    Screen('TextSize', screen.win,oldTextSize + 10 );
    % >> This is now a frame-by-frame drawing loop
    while GetSecs < endTime_c-0.13
        % Check for a quit key press
        [keyIsDown, ~, keyCode] = KbCheck();
        if keyIsDown && (keyCode(KbName('q')) || keyCode(KbName('Q')))
            isTerminationKeyPressed = true;
            break; 
        end
        

        
        % % >> PACING CUE LOGIC
        % % >> Determine the color of the cross based on time
        % % >> This creates a pulse at the frequency defined in your parameters
        % pulseInterval = 1 / parameters.pacingFrequency;
        % if mod(GetSecs - startTime, pulseInterval) < (pulseInterval / 2)
        %     crossColor = [255 255 255]; % Light grey
        % else
        %     crossColor = [80 80 80]; % Dark grey
        % end
        % 
        % windowRect = Screen('Rect', screen.win);
        % [xCenter, yCenter] = RectCenter(windowRect);
        % verticalOffset = 50; 
        % xPosition = 'center';
        % yPosition = yCenter + verticalOffset;
        % 
        % DrawFormattedText(screen.win, '+', xPosition, yPosition, crossColor);
        % >> END PACING CUE LOGIC
        
        % >> Flip the screen to show the updated frame (image + cross)
        
    end
    Screen('TextSize', screen.win, oldTextSize);

    fprintf('Stimulus OFF: %s \n', fingerName);
    
    % --- Clean Up ---
    Screen('Close', imageTexture);
    Priority(0);
    FlushEvents;
    endTime = GetSecs;
end
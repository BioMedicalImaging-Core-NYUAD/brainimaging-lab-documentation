function [startTime, endTime] = showImageBlockWindow(imagePath)
    global screen;
    global parameters;
    global isTerminationKeyPressed;

    if ~isTerminationKeyPressed

        topPriorityLevel = MaxPriority(screen.win);
        Priority(topPriorityLevel);

        % Load image
        try
            imgMatrix = imread(imagePath);
        catch
            error('Could not load image: %s', imagePath);
        end

        % Make texture from image
        imageTexture = Screen('MakeTexture', screen.win, imgMatrix);

        % Number of frames to display
        numFrames = round(parameters.stimulusDuration / screen.ifi);

        for frame = 1:numFrames
            % Draw image texture
            Screen('DrawTexture', screen.win, imageTexture);

            % Flip screen
            if frame == 1
                [vbl, startTime] = Screen('Flip', screen.win);
            elseif frame == numFrames
                [~, endTime] = Screen('Flip', screen.win);
                endTime = endTime + screen.ifi;
            else
                Screen('Flip', screen.win);
            end

            % Check for keypress to exit
            [keyIsDown, ~, keyCode] = KbCheck();
            if keyIsDown && any(keyCode)
                if keyCode(KbName('q')) || keyCode(KbName('Q'))
                    isTerminationKeyPressed = true;
                    ShowCursor();
                    ListenChar(0);
                    Screen('Close');
                    sca;
                    close all;
                    return;
                end
            end
        end

        % Clean up
        Screen('Close', imageTexture);
        Priority(0);
        FlushEvents;
    else
        return;
    end
end

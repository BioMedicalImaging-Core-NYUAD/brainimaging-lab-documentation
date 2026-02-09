function [startTime, endTime] = showFixationWindow()
    global screen;
    global parameters;
    global isTerminationKeyPressed;

    fprintf('Resting...\n');

    if ~isTerminationKeyPressed

        topPriorityLevel = MaxPriority(screen.win);
        Priority(topPriorityLevel);

        numFrames = round(parameters.fixationDuration / screen.ifi);

        % Set fixation size in pixels
        fixationLength = 80; % length of each line (can make this a parameter if you want)
        crossColor = screen.white;

        for frame = 1:numFrames
            % Draw fixation cross
            [xCenter, yCenter] = RectCenter(screen.screenRect);

            coords = [-fixationLength fixationLength 0 0; 0 0 -fixationLength fixationLength];
            Screen('DrawLines', screen.win, coords, 10, crossColor, [xCenter yCenter]);

            % Flip screen
            if frame == 1
                [vbl, startTime] = Screen('Flip', screen.win);
            elseif frame == numFrames
                [~, endTime] = Screen('Flip', screen.win);
                endTime = endTime + screen.ifi;
            else
                Screen('Flip', screen.win);
            end

            % Check for quit key
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

        Priority(0);
        FlushEvents;
    else
        return;
    end
end
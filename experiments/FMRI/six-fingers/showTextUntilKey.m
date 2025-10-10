function [startTime, endTime] = showTextUntilKey(text)
    global screen;
    global parameters;
    global isTerminationKeyPressed;

    if ~isTerminationKeyPressed

        topPriorityLevel = MaxPriority(screen.win);
        Priority(topPriorityLevel);

        white = screen.white;
        Screen('TextSize', screen.win, parameters.textSize);

        % Initial draw and flip
        DrawFormattedText(screen.win, text, 'center', 'center', white);
        [vbl, startTime] = Screen('Flip', screen.win);

        while true
            [keyIsDown, secs, keyCode] = KbCheck();

            if keyIsDown
                keysPressed = find(keyCode);
                
                % Terminate if 'Q' or 'q' is pressed
                if keysPressed(1) == KbName('Q') || keysPressed(1) == KbName('q')
                    isTerminationKeyPressed = 1;
                    ShowCursor();
                    ListenChar(0);
                    Screen('Close');
                    sca;
                    close all;
                    return;
                else
                    endTime = GetSecs();
                    break;
                end
            end

            % To avoid high CPU usage
            WaitSecs(0.01);
        end

        Priority(0);
        FlushEvents;

    else
        return;
    end
end

function [startTime, endTime] = showBlockWindow(text)
    global screen;
    global parameters;
    global isTerminationKeyPressed;
    
    if(~isTerminationKeyPressed)

        topPriorityLevel = MaxPriority(screen.win);
        Priority(topPriorityLevel);
        
        numFrames = round(parameters.blockDuration/screen.ifi);
        for frame = 1:numFrames
            white = screen.white;
            Screen('TextSize', screen.win, parameters.textSize);
            DrawFormattedText(screen.win, text, 'center', 'center',white);
            if frame == 1
                [vbl, startTime, tstamp, miss_check]=Screen('Flip', screen.win);
            else
                if frame == numFrames
                    [vbl, t, tstamp, miss_check]=Screen('Flip', screen.win);
                    endTime = t+screen.ifi;
                else
                    Screen('Flip', screen.win);
                end
            end  
            
            
            [keyIsDown, secs, keyCode] = KbCheck();
            if sum(keyCode)==1   % if at least one key was pressed
                keysPressed = find(keyCode);
                % in the case of multiple keypresses, just consider the first one
                if find(keysPressed(1)== KbName('Q') || keysPressed(1)==KbName('q'))
                    isTerminationKeyPressed = 1;
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
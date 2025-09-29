function [startTime, endTime] = showBlockWindow(text, blocktype)
    global screen;
    global parameters;
    global isTerminationKeyPressed;
    
    if ~parameters.isDemoMode
        Datapixx('SetDoutValues', 0);
        Datapixx('RegWrRd');
    end
    
    if(~isTerminationKeyPressed)

        topPriorityLevel = MaxPriority(screen.win);
        Priority(topPriorityLevel);
        
        
        numFrames = round(parameters.blockDuration/screen.ifi);
        for frame = 1:numFrames
            white = screen.white;
            black = screen.black;
      
            Screen('TextSize', screen.win, parameters.textSize);
            
            % blocktype ==0 means eyes closed
            % blocktype ==1 means eyes open
            
            if blocktype == 0
                Screen('FillRect', screen.win, black);
                DrawFormattedText(screen.win, text, 'center', 'center',white);
            elseif blocktype == 1
                Screen('FillRect', screen.win, white);
                DrawFormattedText(screen.win, text, 'center', 'center',black);
            end
               
            if frame == 1
                [vbl, startTime, tstamp, miss_check]=Screen('Flip', screen.win);
                % This is the first frame of the block, so we can just send
                % one marker on the EEG data here
                
                % Sending an S1 marker on the EEG data
                if ~parameters.isDemoMode

                    Datapixx('SetDoutValues', 2^2);
                    Datapixx('RegWrRd');
                    
                end
                toc
            else
                if frame == numFrames
                    [vbl, t, tstamp, miss_check]=Screen('Flip', screen.win);
                    %
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
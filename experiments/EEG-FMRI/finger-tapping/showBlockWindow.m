function [startTime, endTime] = showBlockWindow(text, trigger_code)
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

        tapduration = 0.8; % the user has tapduration seconds to finish the tap
        
        pauseduration = 0.2;
        
        framesperTap = round(tapduration/screen.ifi); % tapduration converted to frames
        
        framesperPause = round(pauseduration/screen.ifi); % tapduration converted to frames
        
        % The issue is that:
        % - we have a certain number of frames that correspond to the block
        % duration
        % - we need every 1 second 
        % - 
        % state = stop
        % state = tap
        
        for frame = 1:numFrames
            disp(['number of frames ', int2str(frame)]);
            white = screen.white;
            Screen('TextSize', screen.win, parameters.textSize);
            DrawFormattedText(screen.win, text, 'center', 'center',white);
            
%             state = 1; % 1 is tap and 2 is stop
%             last_state = 0;
%             if state == 1
%                
%                 % tap state
%                 
%                 % we want to flip the tapping screen, unless it is already
%                 % flipped
%                 if last_state ==1
%                 
%             end    
            % Finger state
            if frame == 1
                % If frame == 1 or mod(frame, framesperTap) ==0:
                [vbl, startTime, tstamp, miss_check]=Screen('Flip', screen.win);
                % This is the first frame of the block, so we can just send
                % one marker on the EEG data here
                
                % TODO: First trial of the first block is good we just need to
                % add the stop window

                % Sending an S1 marker on the EEG data that marks the
                % beginning of the block
                if ~parameters.isDemoMode
                    
                    Datapixx('SetDoutValues', trigger_code);
                    Datapixx('RegWrRd');
                    Datapixx('SetDoutValues', 0);
                    Datapixx('RegWrRd');
                    
                end
             
                
            else
%                 % Stop state
%                 if mod(frame, framesperTap) == 0
%                     % we need to tell the person to tap a finger once
%                     
%                     DrawFormattedText(screen.win, parameters.stopTap, 'center', 'center',white);
%                     
%                     Screen('Flip', screen.win);
%                     
%                     
% 
%                     % We need to send a trigger specific for the finger
%                     % that is tapped we can use
%                     if ~parameters.isDemoMode
%                         % We will use a different marker for each finger
%                         Datapixx('SetDoutValues', trigger_code);
%                         Datapixx('RegWrRd');
%                         Datapixx('SetDoutValues', 0);
%                         Datapixx('RegWrRd');
%                     end
% 
%                 end
                
                
                
                
                toc
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
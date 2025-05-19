function [startTime, endTime, interBlockRandomWaitduration] = showBlockWindowtest(text, trigger_code)
    global screen;
    global parameters;
    global isTerminationKeyPressed;
    

    % -- Reset output triggers if not in demo mode --
    if ~parameters.isDemoMode
        Datapixx('SetDoutValues', 0);
        Datapixx('RegWrRd');
    end

    % -- Highest priority for accurate timing --
    topPriorityLevel = MaxPriority(screen.win);
    Priority(topPriorityLevel);
    
    
    % Add random duration at beginning of block

    try
        % -- Convert total block duration (e.g., 12s) to frames --
        numFrames    = round(parameters.blockDuration / screen.ifi);
        
        interBlockRandomWaitduration = parameters.IBW(randperm(length(parameters.IBW),1));
        
        
        parameters.tapduration
        parameters.pauseduration
        
        % -- Convert tap/pause durations to frames --
        tapFrames = round(parameters.tapduration / screen.ifi);    % 1 second of tapping
        pauseFrames = round(parameters.pauseduration / screen.ifi);    % 0.2 seconds of pause

        
        interBlockRandomWaitFrames = round(interBlockRandomWaitduration / screen.ifi);
        
                
        % -- For convenience, define the total cycle length in frames --
        cycleFrames  = tapFrames + pauseFrames;

        % -- This will store whether we're currently showing "Tap" or "Stop" --
        prevState = 'none';  % used to detect when we need to flip


        maxRandWaitFrames = round(parameters.maxRandWaitTime / screen.ifi);
        
        leftoutFrames = maxRandWaitFrames - interBlockRandomWaitFrames;
        
        % -- On the first frame, we do one flip to get an initial timestamp --
        Screen('TextSize', screen.win, parameters.textSize);
        DrawFormattedText(screen.win, text, 'center', 'center', screen.white);
        [vbl, startTime, tstamp, miss_check] = Screen('Flip', screen.win);
        
        for waitframe = 1:interBlockRandomWaitFrames
            
            [vbl, ~] = Screen('Flip', screen.win);
            
        end
        
        


        % -- (Optional) Send a trigger to mark block start in the EEG data --
%         if ~parameters.isDemoMode
%             Datapixx('SetDoutValues', trigger_code); % e.g., "S1" marker
%             Datapixx('RegWrRd');
%             Datapixx('SetDoutValues', 0);
%             Datapixx('RegWrRd');
%         end
        
        
        numFrames = numFrames - maxRandWaitFrames;
        
            
        % -- Main loop over all frames in this block --
        for frame = 1 : numFrames
            disp(['number of frames ', int2str(frame)]);
            % ---------------------------------------------------
            % 1) Figure out if we are in "Tap" or "Stop" segment
            % ---------------------------------------------------
            % We cycle every (tapFrames + pauseFrames) frames
            toc
            cycFrame = mod(frame-1, cycleFrames) + 1; 
            if cycFrame <= tapFrames
                currentState = 'tap';
            else
                currentState = 'stop';
            end
            disp(['current state, frame', currentState, int2str(frame)]);
            % ---------------------------------------------------
            % 2) Only flip when the text *changes*
            % ---------------------------------------------------
            if ~strcmp(currentState, prevState)
                if strcmp(currentState, 'tap')
                    % Show TAPPING text
                    DrawFormattedText(screen.win, text, ...
                                      'center', 'center', screen.white);
                    
                    % (Optional) Send trigger for “tap start”
                    if parameters.useVpixx
                        Datapixx('SetDoutValues', trigger_code); 
                        Datapixx('RegWrRd');

                    end
                    
                else
                    % Show STOP text
                    DrawFormattedText(screen.win, parameters.stopTap, ...
                                      'center', 'center', screen.white);


                end
                
                
                prevState = currentState;
            
           
            end
            
            
            if strcmp(currentState, 'tap')
                
                DrawFormattedText(screen.win, text, ...
                    'center', 'center', screen.white);
                [vbl, ~] = Screen('Flip', screen.win);
            
            elseif strcmp(currentState, 'stop')
                DrawFormattedText(screen.win, parameters.stopTap, ...
                    'center', 'center', screen.white);
                [vbl, ~] = Screen('Flip', screen.win);
            end
            
                    
            % ---------------------------------------------------
            % 3) Keyboard check for early termination (“Q” key)
            % ---------------------------------------------------
            [keyIsDown, ~, keyCode] = KbCheck();
            if keyIsDown
                if keyCode(KbName('Q')) || keyCode(KbName('q'))
                    isTerminationKeyPressed = 1;
                    ShowCursor(); ListenChar(0);
                    sca; % Screen close all
                    Priority(0);
                    return;
                end
            end
            
            if parameters.useVpixx
                Datapixx('SetDoutValues', 0);
                Datapixx('RegWrRd');
            end
            
        end
        
        for leftOutWaitFrame = 1:leftoutFrames
            
            [vbl, ~] = Screen('Flip', screen.win);
            
        end
        
        % -- End of block: one final flip to timestamp the endTime (optional) --
        [~, blockEnd] = Screen('Flip', screen.win);
        endTime = blockEnd + screen.ifi;  % (whatever you prefer)

    catch ME
        Priority(0);
        rethrow(ME);
    end

    Priority(0);
    FlushEvents;

end

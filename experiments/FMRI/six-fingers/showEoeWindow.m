%   Start of experiment window
function startTime = showEoeWindow()
    global screen;
    global parameters;
    
    white = screen.white;
    text = parameters.thankYouMsg;;
    %Demonstrates given text on current window. Waits until user presses 
    %the SPACE key and moves to another window
    % Retreive the maximum priority number
    topPriorityLevel = MaxPriority(screen.win);
    Priority(topPriorityLevel);
    Screen('TextSize', screen.win, parameters.textSize);
    numFrames = round(parameters.eoeTaskDuration/screen.ifi);
    for frame = 1:numFrames
        DrawFormattedText(screen.win, text, 'center', 'center',white);
        if frame == 1
            [vbl, startTime, tstamp, miss_check]=Screen('Flip', screen.win);
        else
            Screen('Flip', screen.win);
        end
    end
    Priority(0);

end




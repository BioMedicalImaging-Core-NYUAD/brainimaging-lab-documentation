function showTTLWindow_1()
    global screen;
    global parameters;


    white = screen.white;
    text = parameters.ttlMsg;

    KbName('UnifyKeyNames');
    Screen('TextSize', screen.win, parameters.textSize);
    DrawFormattedText(screen.win, text, 'center', 'center',white);
    Screen('Flip', screen.win);
    
    while true
        [keyIsDown, secs, keyCode] = KbCheck();
        if sum(keyCode)==1   % if at least one key was pressed
            keysPressed = find(keyCode);
            % in the case of multiple keypresses, just consider the first one
            if find(keysPressed(1)== KbName('`~') || keysPressed(1)==KbName('5%')|| keysPressed(1)==KbName('5') || keysPressed(1)==KbName('escape') || keysPressed(1)==KbName('esc'))
                break;
            end
        end
    end
end
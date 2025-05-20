function showTTLWindow_1()
    global screen;
    global parameters;


    white = screen.white;
    text = parameters.ttlMsg;

    KbName('UnifyKeyNames');
    Screen('TextSize', screen.win, parameters.textSize);
    DrawFormattedText(screen.win, text, 'center', 'center',white);
    Screen('Flip', screen.win);
    
    % 3 is the number of the keyboard device on the stimulus computer in
    % NYUAD
    while true
        [keyIsDown, secs, keyCode] = KbCheck();
        disp('checking keypress');

        disp('keyIsDown:');
        disp(keyIsDown);

        disp('secs:');
        disp(secs);

        disp('keyCode:');
        disp(find(keyCode)); % This will show only the indices of keys that are pressed
        
        if sum(keyCode)==1   % if at least one key was pressed
            keysPressed = find(keyCode);
            
            % in the case of multiple keypresses, just consider the first one
            disp(keysPressed(1));
            if find(keysPressed(1)== KbName('`~') || keysPressed(1)==KbName('5%')|| keysPressed(1)==KbName('5') || keysPressed(1)==KbName('escape') || keysPressed(1)==KbName('esc'))
                break;
            end
        end
    end
end
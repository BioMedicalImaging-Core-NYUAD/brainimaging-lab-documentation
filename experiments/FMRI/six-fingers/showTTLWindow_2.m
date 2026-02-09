function showTTLWindow_2()
    % for nyuad scanner
    global screen;
    global parameters;
    global datapixx;

    white = screen.white;
    text = parameters.ttlMsg;

    KbName('UnifyKeyNames');
    Screen('TextSize', screen.win, parameters.textSize);
    DrawFormattedText(screen.win, text, 'center', 'center',white);
    Screen('Flip', screen.win);
    
    sprintf('before if condition datapixx %d',datapixx)
    if ~datapixx
        sprintf('IN IF CONDITION');
        % get set
        key5down=0;
        while ~key5down
            [keyisdown, secs, keycode] = KbCheck(-1);
            key5down = keycode(KbName('5%'));
        end
        sprintf('Scanner failed to trigger!!!!');
    else
        % wait for trigger from datapixx
        sprintf('IN ELSE CONDITION');
        Datapixx('RegWrRd');
        init_check = dec2bin(Datapixx('GetDinValues'));
        trigger_state = init_check(14);
        %sprintf('trigger_state = %s ', num2str(trigger_state));
        while 1
            Datapixx('RegWrRd');
            regcheck = dec2bin(Datapixx('GetDinValues'));
            %sprintf('regcheck(14) =  %s     trigger_state = %s ', num2str(regcheck(14)), num2str(trigger_state));
            if regcheck(14) ~= trigger_state
                fprintf('Triggered!\n')
                break;
            end
        end
        
    end
    
end
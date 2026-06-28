function wait_trigger(VP, manualTrigger)
% WAIT_TRIGGER - Wait for scanner trigger or manual key press.

if nargin < 2
    error('wait_trigger:missingInput', 'Both VP and manualTrigger are required');
end

Screen('FillRect', VP.window, VP.backGroundColor);
Screen('TextSize', VP.window, 36);
DrawFormattedText(VP.window, 'Waiting for Trigger...', 'center', VP.windowCenter(2) - 40, [1 1 1] * 255);
if manualTrigger
    DrawFormattedText(VP.window, '(debug mode - press ''t'')', 'center', VP.windowCenter(2) + 20, [0.7 0.7 0.7] * 255);
end
Screen('Flip', VP.window);

if manualTrigger
    fprintf('DEBUG MODE: Press t to start experiment\n');
    while KbCheck(-1); end
    while true
        [keyIsDown, ~, keyCode] = KbCheck(-1);
        if keyIsDown
            if keyCode(KbName('5%')) || keyCode(KbName('t'))
                fprintf('Manual trigger received!\n');
                break;
            elseif keyCode(KbName('escape'))
                Screen('CloseAll');
                error('Experiment cancelled');
            end
        end
        WaitSecs(0.001);
    end
else
    fprintf('Waiting for scanner trigger...\n');
    if ~Datapixx('IsReady'), Datapixx('Open'); end
    Datapixx('RegWrRd');
    init_check = dec2bin(Datapixx('GetDinValues'));
    trigger_state = init_check(14);
    while true
        Datapixx('RegWrRd');
        regcheck = dec2bin(Datapixx('GetDinValues'));
        if regcheck(14) ~= trigger_state
            fprintf('SCANNER TRIGGER RECEIVED!\n');
            break;
        end
        [keyIsDown, ~, keyCode] = KbCheck(-1);
        if keyIsDown && keyCode(KbName('escape'))
            Screen('CloseAll');
            error('Experiment cancelled');
        end
        WaitSecs(0.001);
    end
end

while KbCheck(-1); end

end

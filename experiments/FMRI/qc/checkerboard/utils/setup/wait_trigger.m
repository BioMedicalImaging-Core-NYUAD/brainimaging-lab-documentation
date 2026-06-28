function wait_trigger(VP, manualTrigger)
% WAIT_TRIGGER - Wait for scanner trigger or manual key press.

if nargin < 2
    error('wait_trigger:missingInput', 'Both VP and manualTrigger are required');
end

% Continuously redraw and flip the trigger screen every frame to keep
% the GPU pipeline warm — prevents PsychVulkanCore timestamp timeouts
% on the first stimulus flip after trigger.

if manualTrigger
    fprintf('DEBUG MODE: Press t to start experiment\n');
    while KbCheck(-1); end
    while true
        Screen('FillRect', VP.window, VP.backGroundColor);
        Screen('TextSize', VP.window, 36);
        DrawFormattedText(VP.window, 'Waiting for Trigger...', 'center', VP.windowCenter(2) - 40, [1 1 1] * 255);
        DrawFormattedText(VP.window, '(debug mode - press ''t'')', 'center', VP.windowCenter(2) + 20, [0.7 0.7 0.7] * 255);
        Screen('Flip', VP.window);
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
    end
else
    fprintf('Waiting for scanner trigger...\n');
    if ~Datapixx('IsReady'), Datapixx('Open'); end
    Datapixx('RegWrRd');
    init_check = dec2bin(Datapixx('GetDinValues'));
    trigger_state = init_check(14);
    while true
        Screen('FillRect', VP.window, VP.backGroundColor);
        Screen('TextSize', VP.window, 36);
        DrawFormattedText(VP.window, 'Waiting for Trigger...', 'center', VP.windowCenter(2) - 40, [1 1 1] * 255);
        Screen('Flip', VP.window);
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
    end
end

while KbCheck(-1); end

end

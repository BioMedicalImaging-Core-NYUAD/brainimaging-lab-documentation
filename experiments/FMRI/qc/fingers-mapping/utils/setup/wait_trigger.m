function wait_trigger(VP, manualTrigger)
% WAIT_TRIGGER - Wait for scanner trigger or manual keyboard trigger.

if nargin < 2
    error('wait_trigger:missingInput', 'VP and manualTrigger are required');
end

% Continuously redraw and flip the trigger screen every frame to keep
% the GPU pipeline warm — prevents PsychVulkanCore timestamp timeouts
% on the first stimulus flip after trigger.

if manualTrigger
    fprintf('DEBUG MODE: press 5 or t to start\n');
    while KbCheck(-1); end
    while true
        Screen('FillRect', VP.window, VP.backGroundColor);
        Screen('TextSize', VP.window, 36);
        DrawFormattedText(VP.window, 'Waiting for Trigger...', 'center', VP.windowCenter(2) - 40, [255 255 255]);
        DrawFormattedText(VP.window, '(debug mode - press 5 or t)', 'center', VP.windowCenter(2) + 20, [180 180 180]);
        Screen('Flip', VP.window);
        [keyIsDown, ~, keyCode] = KbCheck(-1);
        if keyIsDown
            if keyCode(KbName('5%')) || keyCode(KbName('5')) || keyCode(KbName('t'))
                fprintf('Manual trigger received.\n');
                break;
            elseif keyCode(KbName('ESCAPE'))
                error('Experiment cancelled');
            end
        end
    end
else
    fprintf('Waiting for scanner trigger via VPixx DIN bit 14...\n');
    if ~Datapixx('IsReady')
        Datapixx('Open');
    end

    Datapixx('RegWrRd');
    init_check = dec2bin(Datapixx('GetDinValues'));
    if length(init_check) < 14
        error('VPixx DIN not properly configured. Need at least 14 bits.');
    end
    trigger_state = init_check(14);

    while true
        Screen('FillRect', VP.window, VP.backGroundColor);
        Screen('TextSize', VP.window, 36);
        DrawFormattedText(VP.window, 'Waiting for Trigger...', 'center', VP.windowCenter(2) - 40, [255 255 255]);
        Screen('Flip', VP.window);
        Datapixx('RegWrRd');
        regcheck = dec2bin(Datapixx('GetDinValues'));
        if regcheck(14) ~= trigger_state
            fprintf('Scanner trigger received.\n');
            break;
        end
        [keyIsDown, ~, keyCode] = KbCheck(-1);
        if keyIsDown && keyCode(KbName('ESCAPE'))
            error('Experiment cancelled');
        end
    end
end

while KbCheck(-1); end

end

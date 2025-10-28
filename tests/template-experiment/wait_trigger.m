function wait_trigger(VP, manualTrigger)
% WAIT_TRIGGER - Wait for scanner trigger or manual trigger
%
% Inputs:
%   VP - Viewing Parameters structure (for screen display)
%   manualTrigger - Boolean: true = manual trigger, false = scanner trigger
%
% Output:
%   none (function blocks until trigger received)
%
% Usage:
%   wait_trigger(VP, true);   % Debug mode (press t)
%   wait_trigger(VP, false);  % Scanner mode

% Input validation
if nargin < 2
    error('wait_trigger:missingInput', 'Both VP and manualTrigger parameters are required');
end

if ~isstruct(VP)
    error('wait_trigger:invalidInput', 'VP must be a structure');
end

if ~islogical(manualTrigger) && ~isnumeric(manualTrigger)
    error('wait_trigger:invalidInput', 'manualTrigger must be a boolean or numeric value');
end

% Display "Waiting for Trigger..." message on screen
Screen('FillRect', VP.window, VP.backGroundColor);

% Set text properties
Screen('TextSize', VP.window, 36);
Screen('TextFont', VP.window, 'Arial');

% Draw "Waiting for Trigger..." message
DrawFormattedText(VP.window, 'Waiting for Trigger...', 'center', VP.windowCenter(2) - 40, [1 1 1] * 255);

% If debug mode, add second line with instruction
if manualTrigger
    DrawFormattedText(VP.window, '(debug mode - press ''t'')', 'center', VP.windowCenter(2) + 20, [0.7 0.7 0.7] * 255);
end

Screen('Flip', VP.window);

if manualTrigger
    % DEBUG MODE: Manual trigger via keyboard (5 or t)
    fprintf('DEBUG MODE: Press 5 or t to start experiment\n');
    
    % Clear any existing key presses
    while KbCheck(-1); end
    
    % Wait for trigger key
    while true
        [keyIsDown, ~, keyCode] = KbCheck(-1);
        if keyIsDown
            if keyCode(KbName('5')) || keyCode(KbName('t'))
                fprintf('Manual trigger received!\n');
                break;
            elseif keyCode(KbName('escape'))
                fprintf('Experiment cancelled by user\n');
                Screen('CloseAll');
                error('Experiment cancelled');
            end
        end
        % Small delay to prevent excessive CPU usage
        WaitSecs(0.001);
    end
    
else
    % SCANNER MODE: Wait for VPixx DIN trigger
    fprintf('Waiting for scanner trigger...\n');
    
    % Initialize VPixx
    if ~Datapixx('IsReady')
        Datapixx('Open');
    end
    
    % Get initial state of trigger bit (bit 14)
    Datapixx('RegWrRd');
    init_check = dec2bin(Datapixx('GetDinValues'));
    
    % Ensure we have enough bits
    if length(init_check) < 14
        error('VPixx DIN not properly configured. Need at least 14 bits.');
    end
    
    trigger_state = init_check(14); % Bit 14 for scanner trigger
    fprintf('Initial trigger state: %s\n', trigger_state);
    
    % Wait for trigger
    while true
        Datapixx('RegWrRd');
        regcheck = dec2bin(Datapixx('GetDinValues'));
        
        % Check if trigger bit changed
        if regcheck(14) ~= trigger_state
            fprintf('SCANNER TRIGGER RECEIVED!\n');
            break;
        end
        
        % Also check for escape key (for emergency stop)
        [keyIsDown, ~, keyCode] = KbCheck(-1);
        if keyIsDown && keyCode(KbName('escape'))
            fprintf('Experiment cancelled by user\n');
            Screen('CloseAll');
            error('Experiment cancelled');
        end
        
        % Small delay to prevent excessive CPU usage
        WaitSecs(0.001);
    end
end

% Clear any remaining key presses
while KbCheck(-1); end

end

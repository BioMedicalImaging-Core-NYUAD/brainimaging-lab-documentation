function testKBCheck()
    % Clear the Command Window
    clc;

    % Standardize key names across operating systems
    KbName('UnifyKeyNames');
    
    % Display instructions
    fprintf('Press any key to display its information.\n');
    fprintf('Press Esc to exit.\n\n');
    
    while true
        % Check the keyboard state
        [keyIsDown, secs, keyCode] = KbCheck(3);

        % If any key is pressed
        if keyIsDown
            % Find which keys are pressed
            pressedKeys = find(keyCode);
            
            % Display a header
            fprintf('--- Key Press Detected ---\n');
            
            % 1. keyIsDown (logical: 0 or 1)
            fprintf('keyIsDown: %d\n', keyIsDown);
            
            % 2. secs (time of press)
            fprintf('secs: %.4f\n', secs);
            
            % 3. Pressed key indices and names
            if isempty(pressedKeys)
                fprintf('No keys are pressed.\n');
            else
                fprintf('Pressed keys indices: %s\n', mat2str(pressedKeys));
                
                % KbName returns a string or cell array of strings
                keyNames = KbName(pressedKeys);
                
                % If multiple keys are pressed, KbName returns a cell array
                if iscell(keyNames)
                    fprintf('Pressed keys names: %s\n', strjoin(keyNames, ', '));
                else
                    fprintf('Pressed key name: %s\n', keyNames);
                end
            end
            
            % Check if Escape is among the pressed keys
            if any(keyCode(KbName('Escape'))) || any(keyCode(KbName('ESCAPE')))
                fprintf('Esc key pressed. Exiting...\n');
                break;
            end
        end
    end
end

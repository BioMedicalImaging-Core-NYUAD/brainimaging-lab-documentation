function checkAllKeyboards()
    % Clear the Command Window
    clc;
    
    % Standardize key names across operating systems
    KbName('UnifyKeyNames');
    
    % Get a list of all HID (Human Interface Device) devices
    allDevices = PsychHID('Devices');
    
    % Get only the devices recognized as keyboards
    keyboardIndices = GetKeyboardIndices;
    
    % If no keyboards are found, exit
    if isempty(keyboardIndices)
        disp('No keyboard devices found!');
        return;
    end
    
    % Display how many keyboard-like devices are found
    fprintf('Found %d keyboard device(s):\n\n', length(keyboardIndices));
    
    % Print info for each keyboard-like device
    for i = 1:length(keyboardIndices)
        thisDevIndex = keyboardIndices(i);
        devInfo = allDevices(thisDevIndex);
        
        fprintf('Keyboard #%d:\n', i);
        fprintf('  Device index: %d\n', thisDevIndex);
        fprintf('  Product:      %s\n', devInfo.product);
        fprintf('  Usage Name:   %s\n', devInfo.usageName);
        fprintf('  Manufacturer: %s\n', devInfo.manufacturer);
        fprintf('\n');
    end
    
    % Ask user if they want to do a quick keypress test on each device
    answer = input('Would you like to test keypress detection on each device? (y/n) ','s');
    if lower(answer) ~= 'y'
        disp('Exiting without keypress test.');
        return;
    end
    
    % Test each keyboard device with KbCheck
    disp('Press ESC on any device to skip its test and move to the next one.');
    for i = 1:length(keyboardIndices)
        deviceIndex = keyboardIndices(i);
        devInfo = allDevices(deviceIndex);
        
        fprintf('\n--- Testing device #%d: index=%d, product="%s" ---\n',...
            i, deviceIndex, devInfo.product);
        disp('Press any key to see its index/name. Press ESC to skip testing this device.');
        
        while true
            [keyIsDown, secs, keyCode] = KbCheck(deviceIndex);
            if keyIsDown
                % If ESC is pressed, skip to next device
                if keyCode(KbName('ESCAPE'))
                    disp('ESC detected. Skipping to next device...');
                    break;
                end
                
                % Find which keys are pressed
                pressedKeys = find(keyCode);
                if ~isempty(pressedKeys)
                    % Display the pressed keys (indices)
                    fprintf('Time: %.4f | Pressed key indices: %s\n',...
                        secs, mat2str(pressedKeys));
                    
                    % Display the corresponding key names
                    keyNames = KbName(pressedKeys);
                    if iscell(keyNames)
                        fprintf('Key names: %s\n\n', strjoin(keyNames, ', '));
                    else
                        fprintf('Key name: %s\n\n', keyNames);
                    end
                end
                
                % Add a short delay so we don't spam the Command Window
                WaitSecs(0.2);
            end
            WaitSecs(0.01);
        end
    end
    
    disp('Done checking all keyboards!');
end

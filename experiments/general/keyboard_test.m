function showTTLWindow_debug_trycatch()
    KbName('UnifyKeyNames');

    ListenChar(2);  % Suppress all keyboard input to MATLAB
    try
        % === Open Psychtoolbox window ===
        screenNumber = max(Screen('Screens'));
        [win, ~] = Screen('OpenWindow', screenNumber, 0);  % black background

        Screen('TextSize', win, 24);
        DrawFormattedText(win, 'Debug Mode\n\nPress keys – ESC to quit.', 'center', 'center', [255 255 255]);
        Screen('Flip', win);

        fprintf('\n--- Keyboard Debug Mode ---\n');
        fprintf('Press any key. Key names and codes will be shown.\n');
        fprintf('Press ESC to exit.\n\n');

        % === Keyboard loop ===
        while true
            [keyIsDown, ~, keyCode] = KbCheck(-1);  % check all keyboards
            if keyIsDown
                pressedKeys = find(keyCode);
                keyNames = KbName(pressedKeys);
                if ~iscell(keyNames), keyNames = {keyNames}; end

                for i = 1:length(pressedKeys)
                    fprintf('Key pressed: %-10s (code: %d)\n', keyNames{i}, pressedKeys(i));
                end

                if any(strcmpi(keyNames, {'ESCAPE', 'esc'}))
                    fprintf('\n[EXIT] ESC key pressed. Exiting...\n');
                    break;
                end

                WaitSecs(0.2);  % avoid flooding output
            end
        end

        % === Clean up normally ===
        Screen('CloseAll');
        ListenChar(0);

    catch ME
        % === Handle error gracefully ===
        Screen('CloseAll');
        ListenChar(0);
        fprintf('[ERROR] %s\n', ME.message);
        rethrow(ME);  % Optional: re-throw the original error for debugging
    end
end

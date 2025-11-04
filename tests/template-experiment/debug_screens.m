% Debug script to check screen configuration
% Run this to see which screens are available and their properties

clear all; close all;

fprintf('\n=== SCREEN CONFIGURATION DEBUG ===\n\n');

% Get all screens
screens = Screen('Screens');
fprintf('Available screens: %s\n', mat2str(screens));
fprintf('Number of screens: %d\n', length(screens));

% Check which screen PTB will use
maxScreen = max(Screen('Screens'));
fprintf('\nPTB will use screen: %d (max screen)\n', maxScreen);

% Get info for each screen
for i = 1:length(screens)
    screenNum = screens(i);
    fprintf('\n--- Screen %d ---\n', screenNum);

    % Get screen size
    [width, height] = Screen('WindowSize', screenNum);
    fprintf('  Resolution: %d x %d pixels\n', width, height);

    % Get display size in mm
    [widthMM, heightMM] = Screen('DisplaySize', screenNum);
    fprintf('  Physical size: %d x %d mm\n', widthMM, heightMM);

    % Get rect
    rect = Screen('Rect', screenNum);
    fprintf('  Rect: [%d %d %d %d]\n', rect(1), rect(2), rect(3), rect(4));

    % Check if this is the main display
    resolution = Screen('Resolution', screenNum);
    fprintf('  Color depth: %d bits\n', resolution.pixelSize);
    fprintf('  Refresh rate: %.2f Hz\n', resolution.hz);
end

fprintf('\n=== TESTING FULLSCREEN ON PROJECTOR SCREEN ===\n');
fprintf('Attempting to open fullscreen window on screen %d...\n', maxScreen);

try
    % Try VRI's exact setup
    PsychDefaultSetup(2);
    PsychImaging('PrepareConfiguration');
    PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');

    % Open FULLSCREEN window
    [window, windowRect] = PsychImaging('OpenWindow', maxScreen, [.5 .5 .5], [], [], [], [], [], []);

    fprintf('SUCCESS! Fullscreen window opened.\n');
    fprintf('Window rect: [%d %d %d %d]\n', windowRect(1), windowRect(2), windowRect(3), windowRect(4));

    % Do a flip
    Screen('Flip', window);
    fprintf('First flip successful!\n');

    % Draw some text
    DrawFormattedText(window, sprintf('Screen %d\n\nFullscreen Test\n\nYou should see this on the PROJECTOR\n\nPress any key to close', maxScreen), 'center', 'center', [1 1 1]);
    Screen('Flip', window);

    fprintf('\nCheck the PROJECTOR screen - do you see text?\n');
    fprintf('Press any key to close...\n');
    KbWait(-1);

    sca;
    fprintf('Test complete.\n');

catch ME
    fprintf('\nERROR occurred:\n');
    fprintf('Message: %s\n', ME.message);
    if ~isempty(ME.stack)
        fprintf('In: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
    end
    sca;
end

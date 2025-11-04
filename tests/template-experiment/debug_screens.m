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


% debug_screens
% 
% === SCREEN CONFIGURATION DEBUG ===
% 
% Available screens: [0 1]
% Number of screens: 2
% 
% PTB will use screen: 1 (max screen)
% 
% --- Screen 0 ---
%   Resolution: 1920 x 1080 pixels
%   Physical size: 530 x 301 mm
%   Rect: [0 0 1920 1080]
%   Color depth: 24 bits
%   Refresh rate: 144.00 Hz
% 
% --- Screen 1 ---
%   Resolution: 1920 x 1080 pixels
%   Physical size: 677 x 380 mm
%   Rect: [0 0 1920 1080]
%   Color depth: 24 bits
%   Refresh rate: 120.00 Hz
% 
% === TESTING FULLSCREEN ON PROJECTOR SCREEN ===
% Attempting to open fullscreen window on screen 1...
% 
% 
% PTB-INFO: This is Psychtoolbox-3 for Apple macOS, under Matlab 64-Bit ARM (Version 3.0.22 - Build date: Jul  8 2025).
% PTB-INFO: OS support status: macOS 15 Apple Silicon is not yet tested or supported at all for this release..
% PTB-INFO: For information about paid support and other commercial services, please type 'PsychPaidSupportAndServices'.
% PTB-INFO: Most parts of the Psychtoolbox distribution are licensed to you under terms of the MIT license, with some
% PTB-INFO: restrictions. See file 'License.txt' in the Psychtoolbox root folder for the exact licensing conditions.
% PTB-INFO: Psychtoolbox and its prebuilt mex files are distributed in the hope that they will be useful, but WITHOUT
% PTB-INFO: ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
% 
% 
% 
% PTB-INFO: OpenGL-Renderer is Apple :: Apple M2 Ultra :: 2.1 Metal - 89.4
% PTB-INFO: Renderer has 98304 MB of VRAM and a maximum 98304 MB of texture memory.
% PTB-INFO: Screen 1 : Window 10 : VBL startline = 1080 : VBL Endline = -1
% PTB-INFO: Will try to use mechanisms in the external display backend for accurate Flip timestamping.
% PTB-INFO: Reported monitor refresh interval from operating system = 8.333333 ms [120.000000 Hz].
% PTB-INFO: All startup display tests and calibrations disabled. Assuming a refresh interval of 120.000000 Hz. 
% PTB-INFO: Psychtoolbox imaging pipeline starting up for window with requested imagingmode 3150849 ...
% PTB-INFO: Will use 32 bits per color component floating point framebuffer for stimulus drawing.
% PTB-INFO: Will use 32 bits per color component floating point framebuffer for any stimulus post-processing.
% PTB-INFO: No image processing needed. Enabling zero-copy redirected output mode.
% PTB-Error: The OpenGL graphics hardware encountered the following OpenGL error before preflip (Preflip-I): invalid framebuffer operation.
% PTB-Error: The OpenGL graphics hardware encountered the following OpenGL error after flip (II): invalid framebuffer operation.
% PTB-Error: The OpenGL graphics hardware encountered the following OpenGL error after flip (II): invalid framebuffer operation.
% PTB-Error: The OpenGL graphics hardware encountered the following OpenGL error after flip (II): invalid framebuffer operation.
% PTB-Error: The OpenGL graphics hardware encountered the following OpenGL error after flip (II): invalid framebuffer operation.
% PTB-Error: The OpenGL graphics hardware encountered the following OpenGL error after flip (II): invalid framebuffer operation.
% SUCCESS! Fullscreen window opened.
% Window rect: [0 0 1920 1080]
% PTB-Error: The OpenGL graphics hardware encountered the following OpenGL error after flip (II): invalid framebuffer operation.
% First flip successful!
% PTB-Error: The OpenGL graphics hardware encountered the following OpenGL error before preflip (Preflip-I): invalid framebuffer operation.
% PTB-Error: The OpenGL graphics hardware encountered the following OpenGL error after flip (II): invalid framebuffer operation.
% 
% Check the PROJECTOR screen - do you see text?
% Press any key to close...
% 
% PsychHID-ERROR: Could not enumerate and attach to all HID devices (HIDBuildDeviceList(0,0) failed)!
% PsychHID-ERROR: One reason could be that some HID devices are already exclusively claimed by some 3rd party device drivers
% PsychHID-ERROR: or applications. I will now retry to only claim control of a hopefully safe subset of devices like standard
% PsychHID-ERROR: keyboards, mice, gamepads and supported USB-DAQ devices and other vendor defined devices and hope this goes better...
% PsychHID-INFO: That worked. A subset of regular mouse, keyboard etc. input devices and maybe some vendor defined devices will be available at least.

% Minimal test using EXACTLY VRI's setup sequence
% This will help isolate if the issue is environmental or code-related

clear all; close all; clc;

% VRI's exact setup sequence
global GL;

% Determine screen
scr.scr_num = max(Screen('Screens'));

% Set window size (windowed for debugging)
scr.windX_px = 800;
scr.windY_px = 600;
scr_dim = [0, 0, scr.windX_px, scr.windY_px]; % windowed mode

% VPixx setup (BEFORE PsychDefaultSetup)
const.vpixx = 0; % Set to 1 if you have VPixx hardware
if const.vpixx == 1
    Datapixx('Open')
    Datapixx('StopAllSchedules');
    Datapixx('RegWrRd');
end

% VRI's exact sequence
PsychDefaultSetup(2);
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');
ListenChar(0);

% Port audio
InitializePsychSound(1);
PsychPortAudio('Open');

% Open window
fprintf('Opening window...\n');
[window, windowRect] = PsychImaging('OpenWindow', scr.scr_num, [.5 .5 .5], scr_dim, [], [], [], [], []);
fprintf('Window opened successfully!\n');

% Get center
[xCenter, yCenter] = RectCenter(windowRect);

% Flip to clear
vbl = Screen('Flip', window);
fprintf('First flip successful!\n');

% Query frame duration
ifi = Screen('GetFlipInterval', window);
fprintf('Frame interval: %.4f ms\n', ifi * 1000);

% Blend function
Screen('BlendFunction', window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% Priority
topPriorityLevel = MaxPriority(window);
Priority(topPriorityLevel);

% Set SkipSyncTests AFTER window opens (VRI method)
Screen('Preference', 'SkipSyncTests', 1);

% Draw some text to verify window works
DrawFormattedText(window, 'VRI Setup Test\n\nIf you see this, the setup works!\n\nPress any key to exit', 'center', 'center', [1 1 1]);
Screen('Flip', window);

fprintf('\n=== SUCCESS ===\n');
fprintf('Window is open and displaying text.\n');
fprintf('Press any key to close...\n');

% Wait for key press
KbWait(-1);

% Cleanup
sca;
fprintf('Test complete.\n');

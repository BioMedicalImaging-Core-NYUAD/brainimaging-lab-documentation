function [scr, const] = scrConfig(const)
% scrConfig - Screen configuration using VRI's exact method

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GENERAL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
const.text_size = 20;
const.text_font = 'Helvetica';
const.fixationRadius_px = 15;

% Colors
const.white = [1, 1, 1];
const.gray = [.5, .5, .5];
const.black = [0, 0, 0];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SCREEN
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Screen('Preference', 'SkipSyncTests', 1);

scr.scr_num = max(Screen('Screens'));

% Resolution
resolution = Screen('Resolution', scr.scr_num);
scr.scrX_px = resolution.width;
scr.scrY_px = resolution.height;

% Viewing distance (default)
scr.scrViewingDist_cm = 57;

% Window dimensions
scr.windX_px = scr.scrX_px;
scr.windY_px = scr.scrY_px;
scr_dim = [0, 0, scr.windX_px, scr.windY_px];

% Center coordinates
scr.windCenter_px = [scr.windX_px/2, scr.windY_px/2];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% PSYCHTOOLBOX SETUP - VRI method exactly
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PsychDefaultSetup(2);
Screen('Preference', 'VisualDebugLevel', 3);

% PsychImaging setup
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');

% Open window - VRI's exact call
[const.window, const.windowRect] = PsychImaging('OpenWindow', scr.scr_num, ...
    [.5 .5 .5], scr_dim, [], [], [], [], []);

% Get center
[xCenter, yCenter] = RectCenter(const.windowRect);
scr.windCenter_px = [xCenter, yCenter];

% IFI
scr.ifi = Screen('GetFlipInterval', const.window);
scr.hz = 1 / scr.ifi;

fprintf('Screen configuration complete: %d x %d @ %.1f Hz\n', ...
    scr.scrX_px, scr.scrY_px, scr.hz);

end

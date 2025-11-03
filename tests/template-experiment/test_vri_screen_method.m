function test_vri_screen_method()
% TEST_VRI_SCREEN_METHOD - Use VRI's exact screen opening method
% This tests if the window opening is causing the calibration issue

clear all; close all; sca;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETUP (VRI method exactly)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
PA = struct();
PA.experimentDuration = 30;
PA.blinkSecThresh = 5;

% Eye tracking file setup
PA.eyeDataDir = fullfile(pwd, 'eyetracking_data');
if ~exist(PA.eyeDataDir, 'dir'), mkdir(PA.eyeDataDir); end
base = datestr(now,'mmddHHMM');
PA.eyeFileBase = base(1:min(end,8));
PA.eyeFileName = [PA.eyeFileBase '.edf'];

PA.fixationRadius_px = 15;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SCREEN SETUP - VRI METHOD EXACTLY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Screen('Preference', 'SkipSyncTests', 1);

screens = Screen('Screens');
scr_num = max(screens);

% VRI's exact PsychImaging setup
PsychImaging('PrepareConfiguration');
PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');

% VRI's exact OpenWindow call - simplified (no window size restrictions)
[window, windowRect] = PsychImaging('OpenWindow', scr_num, [.5 .5 .5], [], [], [], [], [], []);

fprintf('Window opened using VRI method\n');

% Get center
[xCenter, yCenter] = RectCenter(windowRect);
ifi = Screen('GetFlipInterval', window);

VP = struct();
VP.window = window;
VP.ifi = ifi;
VP.white = 1;
VP.gray = 0.5;
PA.screenCenter = [xCenter, yCenter];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ADD EYETRACKING PATH
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
eyetrackingDir = fullfile(fileparts(mfilename('fullpath')), 'Eyetracking');
addpath(eyetrackingDir);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% INITIALIZE EYELINK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try
    fprintf('\n=== Initializing EyeLink ===\n');
    PA.EL = initEyetracking_minimal(VP, PA);
    if isempty(PA.EL)
        fprintf('Eye tracking initialization failed. Exiting.\n');
        sca;
        return;
    end

    fprintf('\n=== Starting Calibration ===\n');
    fprintf('Watch for calibration targets on BOTH screens\n\n');

    [~, exitFlag] = initEyelinkStates('calibrate', VP.window, PA.EL);
    if exitFlag
        fprintf('Calibration cancelled. Exiting.\n');
        sca;
        return;
    end

    fprintf('\n=== Calibration Complete! ===\n');
    fprintf('SUCCESS - Calibration worked with VRI screen method\n');

    KbStrokeWait;

catch ME
    fprintf('\n!!! ERROR !!!\n');
    fprintf('%s\n', ME.message);
    if ~isempty(ME.stack)
        fprintf('In %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
    end
end

% Cleanup
try
    Eyelink('Shutdown');
catch
end
sca;
fprintf('\nDone.\n');

end

function EL = initEyetracking_minimal(VP, PA)
    [EL, exitFlag] = initEyelinkStates('eyestart', VP.window, {PA.eyeFileBase, PA});
    if exitFlag
        EL = [];
        return;
    end
    EL.eyeDataDir = PA.eyeDataDir;
    EL.eyeFile = PA.eyeFileBase;
end

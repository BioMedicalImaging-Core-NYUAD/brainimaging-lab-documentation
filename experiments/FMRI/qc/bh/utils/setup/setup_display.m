function [VP, debugConfig] = setup_display(debugConfig)
% SETUP_DISPLAY - Configure display parameters and initialize Psychtoolbox.

if ~isstruct(debugConfig)
    error('setup_display:invalidInput', 'debugConfig must be a structure');
end

requiredFields = {'skipSyncTests', 'enabled', 'displayMode', 'fullscreen', 'useVPixx'};
for i = 1:numel(requiredFields)
    if ~isfield(debugConfig, requiredFields{i})
        error('setup_display:missingField', 'debugConfig missing required field: %s', requiredFields{i});
    end
end

if ~ismember(debugConfig.displayMode, [1, 2])
    error('setup_display:invalidDisplayMode', 'displayMode must be 1 or 2');
end

KbName('UnifyKeyNames');
PsychDefaultSetup(1);
ListenChar(0);

if debugConfig.skipSyncTests
    Screen('Preference', 'SkipSyncTests', 1);
else
    Screen('Preference', 'SkipSyncTests', 0);
end
Screen('Preference', 'Verbosity', 0);

switch debugConfig.displayMode
    case 1
        VP.screenDistance = 880;   % mm, MRI center/projector estimate
        VP.screenWidthMm = 711;
        VP.screenHeightMm = VP.screenWidthMm * 9 / 16;
    case 2
        VP.screenDistance = 500;   % mm, laptop/development estimate
        VP.screenWidthMm = 345;
        VP.screenHeightMm = 215.4;
end

if debugConfig.useVPixx
    try
        if ~Datapixx('IsReady')
            Datapixx('Open');
        end
        Datapixx('StopAllSchedules');
        Datapixx('RegWrRd');
    catch ME
        fprintf('WARNING: VPixx requested but unavailable: %s\n', ME.message);
        debugConfig.useVPixx = 0;
        debugConfig.manualTrigger = 1;
    end
end

VP.screenID = max(Screen('Screens'));
if debugConfig.fullscreen
    VP.fullscreen = [];
else
    VP.fullscreen = [0 0 900 650];
end

VP.backGroundColor = [0 0 0];
[VP.window, VP.Rect] = Screen('OpenWindow', VP.screenID, VP.backGroundColor, VP.fullscreen);
[VP.windowCenter(1), VP.windowCenter(2)] = RectCenter(VP.Rect);
VP.windowWidthPix = VP.Rect(3) - VP.Rect(1);
VP.windowHeightPix = VP.Rect(4) - VP.Rect(2);
VP.screenWidthPix = VP.windowWidthPix;
VP.screenHeightPix = VP.windowHeightPix;
VP.ifi = Screen('GetFlipInterval', VP.window);
VP.vbl = Screen('Flip', VP.window);

VP.screenWidthDeg = 2 * atand(0.5 * VP.screenWidthMm / VP.screenDistance);
VP.pixelsPerDegree = VP.screenWidthPix / VP.screenWidthDeg;
VP.white = WhiteIndex(VP.screenID);
VP.black = BlackIndex(VP.screenID);
VP.gray = (VP.white + VP.black) / 2;

Screen('BlendFunction', VP.window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
Screen('TextFont', VP.window, 'Arial');

priorityLevel = MaxPriority(VP.window);
Priority(priorityLevel);

end

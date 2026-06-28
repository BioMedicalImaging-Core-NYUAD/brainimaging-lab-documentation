function [VP, debugConfig] = setup_display(debugConfig)
% SETUP_DISPLAY - Configure display and initialize Psychtoolbox.

if ~isstruct(debugConfig)
    error('setup_display:invalidInput', 'debugConfig must be a structure');
end

requiredFields = {'skipSyncTests', 'enabled', 'displayMode', 'fullscreen'};
for i = 1:length(requiredFields)
    if ~isfield(debugConfig, requiredFields{i})
        error('setup_display:missingField', 'debugConfig missing required field: %s', requiredFields{i});
    end
end

if ~ismember(debugConfig.displayMode, [1, 2])
    error('setup_display:invalidDisplayMode', 'debugConfig.displayMode must be 1 (NYUAD Lab) or 2 (Laptop)');
end

VP.debugTrigger = debugConfig.enabled;
global GL;

switch(debugConfig.displayMode)
    case 1
        VP.screenDistance = 835;    % mm
        VP.screenWidthMm = 643.55;    % mm
        VP.screenHeightMm = VP.screenWidthMm * 9/16;
        VP.whiteValue = 255;
        if debugConfig.fullscreen == 1
            VP.fullscreen = [];
        else
            VP.fullscreen = [1921 1 3839 1079];
        end
    case 2
        VP.screenDistance = 500;
        VP.screenWidthMm = 345;
        VP.screenHeightMm = 215.4;
        VP.whiteValue = 255;
        if debugConfig.fullscreen == 1
            VP.fullscreen = [];
        else
            VP.fullscreen = [0 0 800 500];
        end
end

VP.Display = debugConfig.displayMode;
VP.screenID = max(Screen('Screens'));

if VP.Display == 1 && isfield(debugConfig, 'useVPixx') && debugConfig.useVPixx
    if ~Datapixx('IsReady'), Datapixx('Open'); end
    Datapixx('StopAllSchedules');
    Datapixx('RegWrRd');
end

vpixxAvailable = false;
if isfield(debugConfig, 'useVPixx') && debugConfig.useVPixx
    try, vpixxAvailable = Datapixx('IsReady'); catch, end
end
if isfield(debugConfig, 'buttonbox') && debugConfig.buttonbox && ~vpixxAvailable
    fprintf('\nWARNING: Button box requested but VPixx not available. Switching to keyboard.\n');
    debugConfig.buttonbox = 0;
end

PsychDefaultSetup(1);
ListenChar(0);

if debugConfig.skipSyncTests == 1
    Screen('Preference', 'SkipSyncTests', 1);
else
    Screen('Preference', 'SkipSyncTests', 0);
end

VP.backGroundColor = [128 128 128];
[VP.window, VP.Rect] = Screen('OpenWindow', VP.screenID, VP.backGroundColor, VP.fullscreen);

[VP.windowCenter(1), VP.windowCenter(2)] = RectCenter(VP.Rect);
VP.windowWidthPix = VP.Rect(3) - VP.Rect(1);
VP.windowHeightPix = VP.Rect(4) - VP.Rect(2);
VP.screenWidthPix = VP.windowWidthPix;
VP.screenHeightPix = VP.windowHeightPix;

VP.vbl = Screen('Flip', VP.window);
VP.ifi = Screen('GetFlipInterval', VP.window);
VP.frameRate = 1/VP.ifi;

VP.screenWidthDeg = 2 * atand(0.5 * VP.screenWidthMm / VP.screenDistance);
VP.pixelsPerDegree = VP.screenWidthPix / VP.screenWidthDeg;

VP.white = WhiteIndex(VP.screenID);
VP.black = BlackIndex(VP.screenID);
VP.gray = (VP.white + VP.black) / 2;
if round(VP.gray) == VP.white, VP.gray = VP.black; end

Screen('BlendFunction', VP.window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
Priority(MaxPriority(VP.window));

VP.tstart = VP.vbl;
VP.telapsed = 0;

end

function VP = setup_display(debugConfig)
% SETUP_DISPLAY - Configure display parameters and initialize Psychtoolbox
%
% Input:
%   debugConfig - Debug configuration structure with display settings
%
% Output:
%   VP - Viewing Parameters structure with all display settings

% Input validation
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

if debugConfig.skipSyncTests == 1
    Screen('Preference','SkipSyncTests',1);
end

VP.debugTrigger = debugConfig.enabled;
global GL;
AssertOpenGL;
InitializeMatlabOpenGL(0,3);
PsychImaging('PrepareConfiguration');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFINE DISPLAY SPECIFIC VIEWING CONDITIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch(debugConfig.displayMode)
    case 1 % NYUAD Lab Setup
        VP.screenDistance = 880;   % mm
        VP.IOD = 66.5;             % mm
        VP.screenWidthMm = 711;    % mm
        VP.screenHeightMm = VP.screenWidthMm*9/16; % mm
        VP.whiteValue = 255;
        VP.stereoMode = 0;
        VP.multiSample = 32;
        if debugConfig.fullscreen == 1
            VP.fullscreen = []; % Fullscreen
        else
            VP.fullscreen = [0 0 1024 768]; % Windowed
        end
        
    case 2 % Laptop/Development
        VP.screenDistance = 500;   % mm
        VP.IOD = 62.5;             % mm
        VP.screenWidthMm = 345;    % mm
        VP.screenHeightMm = 215.4; % mm
        VP.whiteValue = 255;
        VP.stereoMode = 0;
        VP.multiSample = 32;
        if debugConfig.fullscreen == 1
            VP.fullscreen = []; % Fullscreen
        else
            VP.fullscreen = [0 0 800 500]; % Windowed
        end
        

end

VP.Display = debugConfig.displayMode;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETUP PSYCHTOOLBOX WITH OPENGL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Screen('Preference', 'Verbosity', 3);
Screen('Preference','VisualDebugLevel', 3);

VP.screenID = max(Screen('Screens'));
VP.centerPatch = 0.75;

% Setup VPixx if needed
switch VP.Display
    case 1
        PsychImaging('AddTask','General','UseDataPixx');
        
        if ~Datapixx('IsReady')
            Datapixx('Open');
        end
        
        if (Datapixx('IsVIEWPixx'))
            Datapixx('EnableVideoScanningBacklight');
        end
        Datapixx('EnableVideoStereoBlueline');
        Datapixx('SetVideoStereoVesaWaveform', 2);
        Datapixx('RegWrRd');
end

VP.backGroundColor = [255/2 255/2 255/2];
[VP.window, VP.Rect] = PsychImaging('OpenWindow', VP.screenID, VP.backGroundColor, VP.fullscreen, [], [], VP.stereoMode, VP.multiSample);

[VP.windowCenter(1), VP.windowCenter(2)] = RectCenter(VP.Rect);
VP.windowWidthPix = VP.Rect(3) - VP.Rect(1);
VP.windowHeightPix = VP.Rect(4) - VP.Rect(2);
VP.screenWidthPix = VP.windowWidthPix;
VP.screenHeightPix = VP.windowHeightPix;

% Setup OpenGL context
glBlendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);
Screen('BeginOpenGL', VP.window);
glViewport(0, 0, VP.windowWidthPix, VP.windowHeightPix);
glDisable(GL.LIGHTING);
glEnable(GL.DEPTH_TEST);
glEnable(GL.BLEND);
glBlendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA);
Screen('EndOpenGL', VP.window);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFINE STRUCTURE HOLDING ALL VIEWING PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
VP.ifi = Screen('GetFlipInterval', VP.window);
VP.frameRate = 1/Screen('GetFlipInterval', VP.window);

% Calculate visual angle parameters
VP.screenWidthDeg = 2*atand(0.5*VP.screenWidthMm/VP.screenDistance);
VP.pixelsPerDegree = VP.screenWidthPix/VP.screenWidthDeg;
VP.pixelsPerMm = VP.screenWidthPix/VP.screenWidthMm;
VP.MmPerDegree = VP.screenWidthMm/VP.screenWidthDeg;
VP.degreesPerMm = 1/VP.MmPerDegree;

% Define colors
VP.white = WhiteIndex(VP.screenID);
VP.black = BlackIndex(VP.screenID);
VP.gray = (VP.white + VP.black)/2;
if round(VP.gray) == VP.white
    VP.gray = VP.black;
end
VP.inc = VP.white - VP.gray;

% Set up alpha-blending
Screen('BlendFunction', VP.window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFINE FRUSTUM AND FIXATION PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ar = RectHeight(VP.Rect) / RectWidth(VP.Rect);
VP.halfWidth = VP.screenWidthMm/2;
VP.halfHeight = ar * VP.halfWidth;
VP.viewingAngle = atan(VP.halfWidth/VP.screenDistance);

VP.near = 250;
VP.far = 2500;
VP.halfFrustumWidth = VP.near * tan(VP.viewingAngle);
VP.halfFrustumHeight = ar * VP.halfFrustumWidth;

% Fixation cross parameters
VP.fixationSquareHalfSize = 0.5 * VP.pixelsPerDegree;
VP.fixationLineWidth = 1;
VP.fixationDotDiameter = 3;

% Initial flip to sync to VBL
VP.vbl = Screen('Flip', VP.window);
VP.tstart = VP.vbl;
VP.telapsed = 0;

% Set high priority
priorityLevel = MaxPriority(VP.window);
Priority(priorityLevel);

end

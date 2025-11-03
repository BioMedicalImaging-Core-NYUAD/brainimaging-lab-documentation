function VP = setup_display(debugConfig) % Initialize display and return viewing parameters
% SETUP_DISPLAY - Configure display parameters and initialize Psychtoolbox
%
% Input:
%   debugConfig - Debug configuration structure with display settings
%
% Output:
%   VP - Viewing Parameters structure with all display settings
 
% Input validation
if ~isstruct(debugConfig) % Ensure input is a struct
    error('setup_display:invalidInput', 'debugConfig must be a structure'); % Throw error if not
end % End input type check

requiredFields = {'skipSyncTests', 'enabled', 'displayMode', 'fullscreen'}; % Required config keys
for i = 1:length(requiredFields) % Loop over required fields
    if ~isfield(debugConfig, requiredFields{i}) % Check field exists
        error('setup_display:missingField', 'debugConfig missing required field: %s', requiredFields{i}); % Error if missing
    end % End field exists check
end % End required fields validation

if ~ismember(debugConfig.displayMode, [1, 2]) % Validate display mode
    error('setup_display:invalidDisplayMode', 'debugConfig.displayMode must be 1 (NYUAD Lab) or 2 (Laptop)'); % Error if invalid
end % End display mode validation

if debugConfig.skipSyncTests == 1 % Optionally skip sync tests for dev
    Screen('Preference','SkipSyncTests',1); % Insecure but useful for debugging
end % End skip sync tests block

VP.debugTrigger = debugConfig.enabled; % Enable debug trigger flag
global GL; % Use OpenGL constants
AssertOpenGL; % Ensure PTB is using OpenGL
InitializeMatlabOpenGL(0,3); % Initialize OpenGL (no debug, 3D)
PsychImaging('PrepareConfiguration'); % Start imaging pipeline configuration

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFINE DISPLAY SPECIFIC VIEWING CONDITIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch(debugConfig.displayMode) % Select hardware profile
    case 1 % NYUAD Lab Setup
        VP.screenDistance = 880;   % mm viewing distance
        VP.IOD = 66.5;             % mm interpupillary distance
        VP.screenWidthMm = 711;    % mm physical screen width
        VP.screenHeightMm = VP.screenWidthMm*9/16; % mm height from 16:9
        VP.whiteValue = 255; % Max luminance value
        VP.stereoMode = 0; % Mono rendering
        VP.multiSample = 32; % Anti-aliasing samples
        if debugConfig.fullscreen == 1 % Fullscreen toggle
            VP.fullscreen = []; % Fullscreen
        else
            VP.fullscreen = [0 0 1024 768]; % Windowed rectangle
        end
        
    case 2 % Laptop/Development
        VP.screenDistance = 500;   % mm viewing distance
        VP.IOD = 62.5;             % mm interpupillary distance
        VP.screenWidthMm = 345;    % mm physical screen width
        VP.screenHeightMm = 215.4; % mm physical screen height
        VP.whiteValue = 255; % Max luminance value
        VP.stereoMode = 0; % Mono rendering
        VP.multiSample = 32; % Anti-aliasing samples
        if debugConfig.fullscreen == 1 % Fullscreen toggle
            VP.fullscreen = []; % Fullscreen
        else
            VP.fullscreen = [0 0 800 500]; % Windowed rectangle
        end
        

end % End display profile switch

VP.Display = debugConfig.displayMode; % Store selected display profile

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETUP PSYCHTOOLBOX WITH OPENGL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
Screen('Preference', 'Verbosity', 3); % Verbose logging
Screen('Preference','VisualDebugLevel', 3); % Show startup splash/debug

VP.screenID = max(Screen('Screens')); % Use external screen if present
VP.centerPatch = 0.75; % Fractional center patch size

% Setup VPixx if needed
switch VP.Display % Only for lab hardware
    case 1 % VIEWPixx/Datapixx path
        PsychImaging('AddTask','General','UseDataPixx'); % Route via DataPixx
        
        if ~Datapixx('IsReady') % Ensure device open
            Datapixx('Open'); % Open connection
        end
        
        if (Datapixx('IsVIEWPixx')) % VIEWPixx specific
            Datapixx('EnableVideoScanningBacklight'); % Enable scanning backlight
        end
        Datapixx('EnableVideoStereoBlueline'); % Enable blue-line stereo sync
        Datapixx('SetVideoStereoVesaWaveform', 2); % Set VESA waveform type
        Datapixx('RegWrRd'); % Commit settings
end % End VPixx setup

VP.backGroundColor = [255/2 255/2 255/2]; % Mid-gray background
[VP.window, VP.Rect] = PsychImaging('OpenWindow', VP.screenID, VP.backGroundColor, VP.fullscreen, [], [], VP.stereoMode, VP.multiSample); % Create window

[VP.windowCenter(1), VP.windowCenter(2)] = RectCenter(VP.Rect); % Compute window center
VP.windowWidthPix = VP.Rect(3) - VP.Rect(1); % Window width in pixels
VP.windowHeightPix = VP.Rect(4) - VP.Rect(2); % Window height in pixels
VP.screenWidthPix = VP.windowWidthPix; % Effective screen width
VP.screenHeightPix = VP.windowHeightPix; % Effective screen height

% Setup OpenGL context
glBlendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA); % Set blending parameters
Screen('BeginOpenGL', VP.window); % Enter OpenGL mode
glViewport(0, 0, VP.windowWidthPix, VP.windowHeightPix); % Set viewport
glDisable(GL.LIGHTING); % Disable fixed-function lighting
glEnable(GL.DEPTH_TEST); % Enable depth testing
glEnable(GL.BLEND); % Enable alpha blending
glBlendFunc(GL.SRC_ALPHA, GL.ONE_MINUS_SRC_ALPHA); % Configure blend function
Screen('EndOpenGL', VP.window); % Exit OpenGL mode

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFINE STRUCTURE HOLDING ALL VIEWING PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
VP.ifi = Screen('GetFlipInterval', VP.window); % Inter-frame interval (s)
VP.frameRate = 1/Screen('GetFlipInterval', VP.window); % Refresh rate (Hz)

% Calculate visual angle parameters
VP.screenWidthDeg = 2*atand(0.5*VP.screenWidthMm/VP.screenDistance); % Screen width in degrees
VP.pixelsPerDegree = VP.screenWidthPix/VP.screenWidthDeg; % Pixel density per degree
VP.pixelsPerMm = VP.screenWidthPix/VP.screenWidthMm; % Pixel density per mm
VP.MmPerDegree = VP.screenWidthMm/VP.screenWidthDeg; % mm per degree
VP.degreesPerMm = 1/VP.MmPerDegree; % Degrees per mm

% Define colors
VP.white = WhiteIndex(VP.screenID); % White color index
VP.black = BlackIndex(VP.screenID); % Black color index
VP.gray = (VP.white + VP.black)/2; % Mid-gray
if round(VP.gray) == VP.white % Avoid white if rounding up
    VP.gray = VP.black; % Use black instead
end % End gray correction
VP.inc = VP.white - VP.gray; % Contrast increment

% Set up alpha-blending
Screen('BlendFunction', VP.window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); % PTB blend function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFINE FRUSTUM AND FIXATION PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ar = RectHeight(VP.Rect) / RectWidth(VP.Rect); % Aspect ratio
VP.halfWidth = VP.screenWidthMm/2; % Half screen width (mm)
VP.halfHeight = ar * VP.halfWidth; % Half screen height (mm)
VP.viewingAngle = atan(VP.halfWidth/VP.screenDistance); % Half FOV (rad)

VP.near = 250; % Near clipping plane (mm)
VP.far = 2500; % Far clipping plane (mm)
VP.halfFrustumWidth = VP.near * tan(VP.viewingAngle); % Frustum half-width
VP.halfFrustumHeight = ar * VP.halfFrustumWidth; % Frustum half-height

% Fixation cross parameters
VP.fixationSquareHalfSize = 0.5 * VP.pixelsPerDegree; % Half-size in pixels
VP.fixationLineWidth = 1; % Line width in pixels
VP.fixationDotDiameter = 3; % Dot diameter in pixels

% Initial flip to sync to VBL
VP.vbl = Screen('Flip', VP.window); % Get first VBL timestamp
VP.tstart = VP.vbl; % Set start time
VP.telapsed = 0; % Reset elapsed time

% Set high priority
priorityLevel = MaxPriority(VP.window); % Determine max priority
Priority(priorityLevel); % Apply process priority

end % End setup_display

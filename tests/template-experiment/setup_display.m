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

% VRI method - use PsychDefaultSetup instead of InitializeMatlabOpenGL
% This asserts OpenGL, setup unified keys and unit color range (0-1)
PsychDefaultSetup(2);
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

% Setup VPixx if needed (VRI method - DON'T add to imaging pipeline)
switch VP.Display % Only for lab hardware
    case 1 % VIEWPixx/Datapixx path
        if ~Datapixx('IsReady') % Ensure device open
            Datapixx('Open'); % Open connection
        end
        Datapixx('StopAllSchedules'); % Stop any running schedules
        Datapixx('RegWrRd'); % Synchronize registers
end % End VPixx setup

% Add FloatingPoint task for better precision (VRI method)
PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible');

% Initialize PsychSound BEFORE opening window (VRI method)
try
    InitializePsychSound(1); % 1 = request low-latency mode
catch
    fprintf('Warning: Could not initialize PsychSound\n');
end

VP.backGroundColor = [0.5 0.5 0.5]; % Mid-gray background (0-1 range, VRI method)
% Use simpler OpenWindow call matching VRI (no stereoMode, no multiSample)
[VP.window, VP.Rect] = PsychImaging('OpenWindow', VP.screenID, VP.backGroundColor, VP.fullscreen, [], [], [], [], []); % Create window

[VP.windowCenter(1), VP.windowCenter(2)] = RectCenter(VP.Rect); % Compute window center
VP.windowWidthPix = VP.Rect(3) - VP.Rect(1); % Window width in pixels
VP.windowHeightPix = VP.Rect(4) - VP.Rect(2); % Window height in pixels
VP.screenWidthPix = VP.windowWidthPix; % Effective screen width
VP.screenHeightPix = VP.windowHeightPix; % Effective screen height

% Flip to clear (VRI method)
VP.vbl = Screen('Flip', VP.window);

% Query the frame duration (VRI method)
VP.ifi = Screen('GetFlipInterval', VP.window); % Inter-frame interval (s)
VP.frameRate = 1/VP.ifi; % Refresh rate (Hz)

% Enable alpha-blending (VRI method)
Screen('BlendFunction', VP.window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFINE STRUCTURE HOLDING ALL VIEWING PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

% Set timestamps
VP.tstart = VP.vbl; % Set start time (using vbl from earlier flip)
VP.telapsed = 0; % Reset elapsed time

% Set high priority (VRI method)
priorityLevel = MaxPriority(VP.window); % Determine max priority
Priority(priorityLevel); % Apply process priority

end % End setup_display

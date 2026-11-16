function [VP, debugConfig] = setup_display(debugConfig) % Initialize display and return viewing parameters
% SETUP_DISPLAY - Configure display parameters and initialize Psychtoolbox
%
% Input:
%   debugConfig - Debug configuration structure with display settings
%
% Output:
%   VP - Viewing Parameters structure with all display settings
%   debugConfig - Updated debug configuration (buttonbox may be modified if VPixx unavailable)

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

VP.debugTrigger = debugConfig.enabled; % Enable debug trigger flag
global GL; % Use OpenGL constants

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFINE DISPLAY SPECIFIC VIEWING CONDITIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
switch(debugConfig.displayMode) % Select hardware profile
    case 1 % NYUAD Lab Setup
        VP.screenDistance = 835;   % mm viewing distance
        VP.IOD = 66.5;             % mm interpupillary distance
        VP.screenWidthMm = 643.55;    % mm physical screen width
        VP.screenHeightMm = VP.screenWidthMm*9/16; % mm height from 16:9
        VP.whiteValue = 255; % Max luminance value
        if debugConfig.fullscreen == 1 % Fullscreen toggle
            VP.fullscreen = []; % Fullscreen on screen 1 (projector)
        else
            % Fullscreen-sized windowed mode on projector screen (screen 1)
            % Screen 0 is 1920 wide, so screen 1 starts at x=1920
            % Screen 1 dimensions: 1920 x 1080
            % Rect format: [left top right bottom]
            % [1920 0 3840 1080] = screen 1 start + full 1920x1080 dimensions
            VP.fullscreen = [1921 1 3839 1079]; % Fullscreen windowed on projector (screen 1), no gaps
        end
        
    case 2 % Laptop/Development
        VP.screenDistance = 500;   % mm viewing distance
        VP.IOD = 62.5;             % mm interpupillary distance
        VP.screenWidthMm = 345;    % mm physical screen width
        VP.screenHeightMm = 215.4; % mm physical screen height
        VP.whiteValue = 255; % Max luminance value
        if debugConfig.fullscreen == 1 % Fullscreen toggle
            VP.fullscreen = []; % Fullscreen
        else
            VP.fullscreen = [0 0 800 500]; % Windowed rectangle
        end
        

end % End display profile switch

VP.Display = debugConfig.displayMode; % Store selected display profile

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETUP PSYCHTOOLBOX WITH OPENGL (VRI METHOD - EXACT ORDER MATTERS)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
VP.screenID = max(Screen('Screens')); % Use external screen if present
VP.centerPatch = 0.75; % Fractional center patch size

% Setup VPixx FIRST if needed (VRI order - BEFORE PsychDefaultSetup)
switch VP.Display % Only for lab hardware
    case 1 % VIEWPixx/Datapixx path (matching VRI method)
        if ~Datapixx('IsReady') % Ensure device open
            Datapixx('Open'); % Open connection
        end
        Datapixx('StopAllSchedules'); % Stop any running schedules
        Datapixx('RegWrRd'); % Synchronize DATAPixx registers to local register cache
end % End VPixx setup

% Check VPixx availability and adjust buttonbox setting if needed
vpixxAvailable = false;
if debugConfig.useVPixx
    try
        vpixxAvailable = Datapixx('IsReady');
    catch
        vpixxAvailable = false;
    end
end

if debugConfig.buttonbox && ~vpixxAvailable
    fprintf('\nWARNING: Button box requested but VPixx not available. Switching to keyboard input.\n');
    debugConfig.buttonbox = 0;
end

% (0) = only OpenGL assertion
% (1) = OpenGL + unified key names (no color range normalization, no imaging)
% (2) = (1) + color range 0-1 + ENABLES IMAGING PIPELINE (breaks EyeLink fullscreen on Apple Silicon)
PsychDefaultSetup(1);
ListenChar(0); % Listen for keyboard input

if debugConfig.skipSyncTests == 1
    Screen('Preference', 'SkipSyncTests', 1);
else
    Screen('Preference', 'SkipSyncTests', 0);
end

% Initialize PsychSound
InitializePsychSound(1); % 1 = request low-latency mode
PsychPortAudio('Open');

% CRITICAL FIX: Use plain Screen('OpenWindow') instead of PsychImaging
% PsychImaging pipeline interferes with EyeLink calibration callbacks in fullscreen on Apple Silicon
VP.backGroundColor = [128 128 128]; % Mid-gray background (0-255 range)
[VP.window, VP.Rect] = Screen('OpenWindow', VP.screenID, VP.backGroundColor, VP.fullscreen);

[VP.windowCenter(1), VP.windowCenter(2)] = RectCenter(VP.Rect); % Compute window center
VP.windowWidthPix = VP.Rect(3) - VP.Rect(1); % Window width in pixels
VP.windowHeightPix = VP.Rect(4) - VP.Rect(2); % Window height in pixels
VP.screenWidthPix = VP.windowWidthPix; % Effective screen width
VP.screenHeightPix = VP.windowHeightPix; % Effective screen height

% Flip to clear (VRI method - do this early)
VP.vbl = Screen('Flip', VP.window);

% Query the frame duration (VRI method)
VP.ifi = Screen('GetFlipInterval', VP.window); % Inter-frame interval (s)
VP.frameRate = 1/VP.ifi; % Refresh rate (Hz)

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

% Set up alpha-blending (VRI method)
Screen('BlendFunction', VP.window, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

% Set drawing to maximum priority level (VRI method)
priorityLevel = MaxPriority(VP.window);
Priority(priorityLevel);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEFINE FIXATION PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Fixation cross parameters
VP.fixationSquareHalfSize = 0.5 * VP.pixelsPerDegree; % Half-size in pixels
VP.fixationLineWidth = 1; % Line width in pixels
VP.fixationDotDiameter = 3; % Dot diameter in pixels

% Set timestamps
VP.tstart = VP.vbl; % Set start time (from earlier flip)
VP.telapsed = 0; % Reset elapsed time

end % End setup_display

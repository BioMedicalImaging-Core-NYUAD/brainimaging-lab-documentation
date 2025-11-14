function drawCircleWithDot(window, screenCenter, circleRadiusPix, dotAngle, dotSize, dotColor, circleColor, circleLineWidth, backGroundColor, fixationLineLengthPix, fixationLineWidth, fixationLineColor)
% DRAW_CIRCLE_WITH_DOT - Draw circular path outline with traveling dot and radial fixation line
%
% Inputs:
%   window - Psychtoolbox window pointer
%   screenCenter - [x, y] center of screen
%   circleRadiusPix - radius of circular path in pixels
%   dotAngle - current angle of traveling dot in radians
%   dotSize - size of traveling dot in pixels
%   dotColor - color of traveling dot [R, G, B]
%   circleColor - color of circular path outline [R, G, B]
%   circleLineWidth - thickness of circular path outline
%   backGroundColor - background color
%   fixationLineLengthPix - length of radial fixation line in pixels (optional)
%   fixationLineWidth - thickness of radial fixation line in pixels (optional)
%   fixationLineColor - color of radial fixation line [R, G, B] (optional, defaults to circleColor)

% Clear screen
Screen('FillRect', window, backGroundColor);

% Draw circular path outline
Screen('FrameOval', window, circleColor * 255, ...
    [screenCenter(1)-circleRadiusPix, screenCenter(2)-circleRadiusPix, ...
    screenCenter(1)+circleRadiusPix, screenCenter(2)+circleRadiusPix], ...
    circleLineWidth);

% Draw radial fixation line (forms cross with circular path)
if nargin >= 10 && ~isempty(fixationLineLengthPix) && fixationLineLengthPix > 0
    % Calculate radial line endpoints (from center outward in direction of dot)
    lineEndX = screenCenter(1) + fixationLineLengthPix * cos(dotAngle);
    lineEndY = screenCenter(2) + fixationLineLengthPix * sin(dotAngle);
    
    % Draw radial line
    if nargin >= 11 && ~isempty(fixationLineWidth)
        lineWidth = fixationLineWidth;
    else
        lineWidth = 2; % Default line width
    end
    
    % Use fixation line color if provided, otherwise use circle color
    if nargin >= 12 && ~isempty(fixationLineColor)
        lineColor = fixationLineColor * 255;
    else
        lineColor = circleColor * 255;
    end
    
    Screen('DrawLine', window, lineColor, ...
        screenCenter(1), screenCenter(2), lineEndX, lineEndY, lineWidth);
end

% Calculate traveling dot position on circular path
dotX = screenCenter(1) + circleRadiusPix * cos(dotAngle);
dotY = screenCenter(2) + circleRadiusPix * sin(dotAngle);

% Draw traveling dot
Screen('FillOval', window, dotColor * 255, ...
    [dotX-dotSize, dotY-dotSize, dotX+dotSize, dotY+dotSize]);

end


function drawCircleWithDot(window, screenCenter, circleRadiusPix, dotAngle, ~, ~, circleColor, circleLineWidth, backGroundColor, fixationLineLengthPix, fixationLineWidth, fixationLineColor)
% DRAW_CIRCLE_WITH_DOT - Draw circular path outline with radial fixation line (replaces traveling dot)
%
% Inputs:
%   window - Psychtoolbox window pointer
%   screenCenter - [x, y] center of screen
%   circleRadiusPix - radius of circular path in pixels
%   dotAngle - current angle of radial line in radians (rotates around circle)
%   ~ - dotSize (unused, kept for backward compatibility)
%   ~ - dotColor (unused, kept for backward compatibility)
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

% Draw radial fixation line (forms cross with circular path, replaces traveling dot)
% Short line segment centered on the circular path, perpendicular to the circle
if nargin >= 10 && ~isempty(fixationLineLengthPix) && fixationLineLengthPix > 0
    % Calculate center point of line (on the circular path)
    lineCenterX = screenCenter(1) + circleRadiusPix * cos(dotAngle);
    lineCenterY = screenCenter(2) + circleRadiusPix * sin(dotAngle);
    
    % Calculate line endpoints (half length on each side, in radial direction)
    halfLength = fixationLineLengthPix / 2;
    lineStartX = lineCenterX - halfLength * cos(dotAngle);
    lineStartY = lineCenterY - halfLength * sin(dotAngle);
    lineEndX = lineCenterX + halfLength * cos(dotAngle);
    lineEndY = lineCenterY + halfLength * sin(dotAngle);
    
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
    
    % Draw the short line segment centered on the circle (rotates with dotAngle)
    Screen('DrawLine', window, lineColor, ...
        lineStartX, lineStartY, lineEndX, lineEndY, lineWidth);
end

% Note: Traveling dot is replaced by the radial fixation line
% The line rotates around the circle, forming a cross with the circular path

end


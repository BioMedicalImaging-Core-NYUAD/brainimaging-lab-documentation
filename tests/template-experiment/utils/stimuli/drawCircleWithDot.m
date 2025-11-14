function drawCircleWithDot(window, screenCenter, circleRadiusPix, dotAngle, dotSize, dotColor, circleColor, circleLineWidth, backGroundColor)
% DRAW_CIRCLE_WITH_DOT - Draw circular path outline with traveling dot
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

% Clear screen
Screen('FillRect', window, backGroundColor);

% Draw circular path outline
Screen('FrameOval', window, circleColor * 255, ...
    [screenCenter(1)-circleRadiusPix, screenCenter(2)-circleRadiusPix, ...
    screenCenter(1)+circleRadiusPix, screenCenter(2)+circleRadiusPix], ...
    circleLineWidth);

% Calculate traveling dot position on circular path
dotX = screenCenter(1) + circleRadiusPix * cos(dotAngle);
dotY = screenCenter(2) + circleRadiusPix * sin(dotAngle);

% Draw traveling dot
Screen('FillOval', window, dotColor * 255, ...
    [dotX-dotSize, dotY-dotSize, dotX+dotSize, dotY+dotSize]);

end


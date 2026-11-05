function drawCircleWithDot(window, screenCenter, circleRadiusPix, dotAngle, dotSize, dotColor, circleColor, circleLineWidth, backGroundColor, cache)
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
%   cache - Optional cached dot positions (if not provided, calculates on the fly)

% Clear screen
Screen('FillRect', window, backGroundColor);

% Draw circular path outline
Screen('FrameOval', window, circleColor * 255, ...
    [screenCenter(1)-circleRadiusPix, screenCenter(2)-circleRadiusPix, ...
    screenCenter(1)+circleRadiusPix, screenCenter(2)+circleRadiusPix], ...
    circleLineWidth);

% Calculate traveling dot position on circular path
if nargin >= 10 && ~isempty(cache)
    % Use cached lookup table
    angleNormalized = mod(dotAngle, 2*pi);
    idx = round((angleNormalized / (2*pi)) * (cache.nSamples - 1)) + 1;
    idx = min(idx, cache.nSamples);  % Ensure within bounds
    dotX = screenCenter(1) + cache.dotX(idx);
    dotY = screenCenter(2) + cache.dotY(idx);
else
    % Calculate on the fly (backward compatible)
    dotX = screenCenter(1) + circleRadiusPix * cos(dotAngle);
    dotY = screenCenter(2) + circleRadiusPix * sin(dotAngle);
end

% Draw traveling dot
Screen('FillOval', window, dotColor * 255, ...
    [dotX-dotSize, dotY-dotSize, dotX+dotSize, dotY+dotSize]);

end


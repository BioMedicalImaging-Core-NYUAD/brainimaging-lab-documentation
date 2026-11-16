function draw_fixation(window, pa)
% DRAW_FIXATION - Background with a central fixation cross
%
% Inputs:
%   window - Psychtoolbox window (or offscreen window) to draw into
%   pa     - Parameters structure (pa.L.fixation, pa.colors)

Screen('FillRect', window, pa.colors.background);
Screen('FillRect', window, pa.colors.fixation, pa.L.fixation');

end

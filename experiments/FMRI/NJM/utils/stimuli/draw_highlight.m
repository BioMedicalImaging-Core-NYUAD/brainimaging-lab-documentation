function draw_highlight(window, pa, button)
% DRAW_HIGHLIGHT - Selection feedback: border around the chosen answer and its offer
%
% Inputs:
%   window - window to draw into (on top of the decision screen)
%   pa     - Parameters structure
%   button - 1 to 4

if isempty(button) || isnan(button), return; end
side = 1 + (button > 2);                                  % buttons 1-2 = Offer A, 3-4 = Offer B
Screen('FrameRect', window, pa.colors.highlight, pa.L.option(button, :), pa.L.highlightWidth);
Screen('FrameRect', window, pa.colors.highlight, pa.L.cardShort(side, :), pa.L.highlightWidth);

end

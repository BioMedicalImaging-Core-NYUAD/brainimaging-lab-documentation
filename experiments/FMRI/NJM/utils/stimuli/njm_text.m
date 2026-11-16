function njm_text(window, str, sizePx, color, rect, align, maxWidth, font)
% NJM_TEXT - Draw text centred vertically in a rectangle
%
% Inputs:
%   window   - window to draw into
%   str      - text (may contain line breaks)
%   sizePx   - text size in pixels
%   color    - RGB 0-255
%   rect     - [left top right bottom]
%   align    - 'center' (default) or 'left' (text starts at the left edge of rect)
%   maxWidth - optional: the text size is reduced until the text is not wider than this (pixels)
%   font     - optional font name
%
% Shrinking instead of clipping keeps long labels readable on any screen size.

if nargin < 6 || isempty(align), align = 'center'; end
if nargin >= 8 && ~isempty(font), Screen('TextFont', window, font); end
Screen('TextSize', window, sizePx);

if nargin >= 7 && ~isempty(maxWidth)
    lines = regexp(str, '\n', 'split');
    while sizePx > 8
        widest = 0;
        for i = 1:numel(lines)
            if isempty(lines{i}), continue; end
            b = Screen('TextBounds', window, lines{i});
            widest = max(widest, b(3) - b(1));
        end
        if widest <= maxWidth, break; end
        sizePx = sizePx - 1;
        Screen('TextSize', window, sizePx);
    end
end

if strcmp(align, 'left')
    DrawFormattedText(window, str, rect(1), 'center', color, [], [], [], 1.15, [], rect);
else
    DrawFormattedText(window, str, 'center', 'center', color, [], [], [], 1.15, [], rect);
end

end

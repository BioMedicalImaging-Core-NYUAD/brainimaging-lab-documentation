function exitFlag = show_text_screen(VP, pa, kb, pages, waitMode)
% SHOW_TEXT_SCREEN - Show instruction or message pages
%
% Inputs:
%   VP, pa, kb - Standard experiment structures
%   pages      - text, or cell array of texts (one per page)
%   waitMode   - 'key' (default): SPACE or right arrow = next page, B or left
%                arrow = previous page, ESC = stop (the experimenter turns the pages);
%                a number: each page is shown for that many seconds
%
% Output:
%   exitFlag - true if ESC was pressed

if nargin < 5 || isempty(waitMode), waitMode = 'key'; end
if ischar(pages), pages = {pages}; end
exitFlag = false;
margin = round(0.08 * (VP.Rect(3) - VP.Rect(1)));
rect = [VP.Rect(1) + margin, VP.Rect(2), VP.Rect(3) - margin, VP.Rect(4)];

p = 1;
while p <= numel(pages)
    Screen('FillRect', VP.window, pa.colors.background);
    njm_text(VP.window, pages{p}, pa.sizes.instructions, pa.colors.text, rect, 'center', rect(3) - rect(1), pa.sizes.font);
    Screen('Flip', VP.window);

    if isnumeric(waitMode)
        WaitSecs(waitMode);
        p = p + 1;
        continue;
    end

    while KbCheck(-1); WaitSecs(0.01); end              % wait for key release
    while true
        [down, ~, keyCode] = KbCheck(-1);
        if down
            if keyCode(kb.escKey), exitFlag = true; return; end
            if keyCode(kb.spaceKey) || keyCode(kb.rightKey), p = p + 1; break; end
            if keyCode(kb.backKey) || keyCode(kb.leftKey), p = max(1, p - 1); break; end
        end
        WaitSecs(0.005);
    end
end
while KbCheck(-1); WaitSecs(0.01); end

end

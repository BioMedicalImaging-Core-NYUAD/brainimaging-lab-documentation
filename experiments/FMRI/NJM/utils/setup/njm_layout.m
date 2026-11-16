function [L, sizes, colors] = njm_layout(VP, P)
% NJM_LAYOUT - Convert the screen layout in the JSON (degrees) to pixels
%
% Inputs:
%   VP - Viewing parameters (windowCenter, pixelsPerDegree)
%   P  - Parameters from the JSON (P.display)
%
% Outputs:
%   L      - pixel rectangles [left top right bottom]; row 1 = Offer A (left), row 2 = Offer B (right)
%            L.cardShort, L.cardFull, L.header, L.photo, L.row.<attribute>, L.icon.<attribute>,
%            L.textLeft, L.textMaxWidth, L.divider, L.prompt, L.option(1:4,:), L.counter, L.fixation
%   sizes  - text sizes in pixels (header, main, detail, prompt, option, counter, instructions)
%   colors - RGB triplets 0-255
%
% The same rectangles are used for drawing and for the eye-tracking areas of interest.

D = P.display; G = D.layout_deg;
ppd = VP.pixelsPerDegree;
cx = VP.windowCenter(1); cy = VP.windowCenter(2);
rectDeg = @(x, y, w, h) round([cx + (x - w / 2) * ppd, cy + (y - h / 2) * ppd, cx + (x + w / 2) * ppd, cy + (y + h / 2) * ppd]);

attrs = fieldnames(G.row_y);
margin = 0.45; iconGap = 0.35;                         % degrees
L = struct();
L.attributes = attrs;
for s = 1:2
    x = G.card_center_x(s); w = G.card_width;
    L.cardShort(s, :) = round([cx + (x - w / 2) * ppd, cy + G.card_top * ppd, cx + (x + w / 2) * ppd, cy + G.card_bottom_short * ppd]);
    L.cardFull(s, :)  = round([cx + (x - w / 2) * ppd, cy + G.card_top * ppd, cx + (x + w / 2) * ppd, cy + G.card_bottom_full * ppd]);
    L.header(s, :) = rectDeg(x, G.header_y, w, 1.0);
    L.photo(s, :) = rectDeg(x, G.photo.y, G.photo.w, G.photo.h);
    for a = 1:numel(attrs)
        y = G.row_y.(attrs{a});
        L.row.(attrs{a})(s, :) = rectDeg(x, y, w, G.row_height);
        iconX = x - w / 2 + margin + D.icon_size_deg / 2;
        L.icon.(attrs{a})(s, :) = rectDeg(iconX, y, D.icon_size_deg, D.icon_size_deg);
    end
    L.textLeft(s) = round(cx + (x - w / 2 + margin + D.icon_size_deg + iconGap) * ppd);
    L.divider(s, :) = round([cx + (x - w / 2 + margin) * ppd, cy + G.divider_y * ppd - 1, cx + (x + w / 2 - margin) * ppd, cy + G.divider_y * ppd + 1]);
end
L.textMaxWidth = round((G.card_width - 2 * margin - D.icon_size_deg - iconGap) * ppd);
L.rowHeight = round(G.row_height * ppd);
L.prompt = rectDeg(0, G.prompt_y, 20, 1.2);
for k = 1:numel(G.option_center_x)
    L.option(k, :) = rectDeg(G.option_center_x(k), G.option_y, G.option_w, G.option_h);
end
L.counter = rectDeg(0, G.counter_y, 12, 0.8);
half = D.fixation_half_size_deg * ppd; thick = max(2, round(D.fixation_line_deg * ppd));
L.fixation = round([cx - half, cy - thick / 2, cx + half, cy + thick / 2; cx - thick / 2, cy - half, cx + thick / 2, cy + half]);
L.highlightWidth = max(2, round(D.highlight_line_deg * ppd));

names = fieldnames(D.text_size_deg);
sizes = struct();
for i = 1:numel(names)
    sizes.(names{i}) = max(8, round(D.text_size_deg.(names{i}) * ppd));
end
sizes.font = D.font;

colors = struct('background', D.background_rgb(:)', 'card', D.card_rgb(:)', 'text', D.text_rgb(:)', ...
    'detail', D.detail_text_rgb(:)', 'fixation', D.fixation_rgb(:)', 'highlight', D.highlight_rgb(:)');

end

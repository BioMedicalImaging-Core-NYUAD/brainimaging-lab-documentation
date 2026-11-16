function draw_offer_screen(window, pa, tr, phase)
% DRAW_OFFER_SCREEN - Draw one of the three screens of a trial
%
% Inputs:
%   window - window (normally an offscreen window, see prepare_trial_screens)
%   pa     - Parameters structure (layout pa.L, textures pa.tex, colours, text sizes)
%   tr     - one element of pa.trials
%   phase  - 1 = employer photos + family background
%            2 = photos + background + salary, off days, workload
%            3 = photos + background + question and the four answer options
%
% Offer A is the left card, Offer B the right card; there is nothing between
% the cards (no "OR"), so gaze is not drawn to the middle.

L = pa.L; S = pa.sizes; C = pa.colors; P = pa.P;
Screen('FillRect', window, C.background);

if phase == 2
    cards = L.cardFull; attrs = L.attributes;
else
    cards = L.cardShort; attrs = {'employer_origin'};
end

for s = 1:2
    side = tr.side(s);
    Screen('FillRect', window, C.card, cards(s, :));
    njm_text(window, sprintf('Job Offer %s', side.letter), S.header, C.text, L.header(s, :), 'center', [], S.font);
    Screen('DrawTexture', window, pa.tex.face(side.face), [], L.photo(s, :));

    for a = 1:numel(attrs)
        name = attrs{a};
        row = L.row.(name)(s, :);
        Screen('DrawTexture', window, pa.tex.icon.(name), [], L.icon.(name)(s, :));
        mid = (row(2) + row(4)) / 2; h = L.rowHeight;
        mainRect = [L.textLeft(s), mid - 0.44 * h, L.textLeft(s) + L.textMaxWidth, mid + 0.06 * h];
        detailRect = [L.textLeft(s), mid + 0.06 * h, L.textLeft(s) + L.textMaxWidth, mid + 0.44 * h];
        njm_text(window, side.text.(name), S.main, C.text, mainRect, 'left', L.textMaxWidth);
        njm_text(window, side.detail.(name), S.detail, C.detail, detailRect, 'left', L.textMaxWidth);
    end
    if phase == 2
        Screen('FillRect', window, C.detail, L.divider(s, :));
    end
end

if phase == 3
    njm_text(window, P.response.prompt, S.prompt, C.text, L.prompt, 'center');
    for k = 1:size(L.option, 1)
        r = L.option(k, :);
        Screen('FillRect', window, C.card, r);
        label = regexprep(P.response.labels{k}, ' Offer ', '\nOffer ');
        h = r(4) - r(2);
        njm_text(window, sprintf('%d', k), S.option, C.detail, [r(1), r(2) + 0.04 * h, r(3), r(2) + 0.30 * h], 'center');
        njm_text(window, label, S.option, C.text, [r(1), r(2) + 0.30 * h, r(3), r(4) - 0.04 * h], 'center', (r(3) - r(1)) * 0.94);
    end
end

if ~isempty(tr.counterText)
    njm_text(window, tr.counterText, S.counter, C.detail, L.counter, 'center');
end

end

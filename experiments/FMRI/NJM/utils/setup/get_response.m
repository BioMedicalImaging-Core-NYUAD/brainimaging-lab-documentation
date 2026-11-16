function [pa, got, button, tPress] = get_response(pa, kb, pressed, firstPress, onset, auto)
% GET_RESPONSE - Check once for a response on the decision screen
%
% Inputs:
%   pa         - Parameters structure
%   kb         - Keyboard structure (kb.responseKeys)
%   pressed    - from KbQueueCheck (already read by the caller in this frame)
%   firstPress - from KbQueueCheck
%   onset      - GetSecs time at which the decision screen appeared
%   auto       - simulated response for this trial (pa.auto(k)); used only if pa.autoRespond
%
% Outputs:
%   got    - true if a response was found
%   button - 1 to 4 (1 = Definitely A, 2 = Probably A, 3 = Probably B, 4 = Definitely B)
%   tPress - GetSecs time of the press
%
% Sources, in this order: simulated participant (testing), keyboard keys 1-4
% (press time from the keyboard queue), VPixx response box (right box; the
% colour -> button mapping is in stimuli_data/response_mapping.csv / the JSON).

got = false; button = NaN; tPress = NaN;

if pa.autoRespond
    if ~auto.timeout && GetSecs >= onset + auto.rt
        got = true; button = auto.button; tPress = onset + auto.rt;
    end
    return;
end

if pressed
    t = firstPress(kb.responseKeys);
    idx = find(t > onset);
    if ~isempty(idx)
        [tPress, j] = min(t(idx));
        button = idx(j);
        got = true;
        return;
    end
end

if pa.useButtonBox
    try
        pair = getButtonColor(pa.resp.vpixxSelection, false);
        if ~isempty(pair)
            j = find(strcmpi(pair{2}, pa.resp.vpixxColors), 1);
            if ~isempty(j)
                got = true; button = j; tPress = GetSecs;
            end
        end
    catch ME
        fprintf('Warning: VPixx button box error (%s). Keyboard only from now on.\n', ME.message);
        pa.useButtonBox = false;
    end
end

end

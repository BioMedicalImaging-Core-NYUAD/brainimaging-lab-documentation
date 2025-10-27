function out = getButtonColor(selection, blocking)
%GETBUTTONCOLOR Return the (box,color) of the pressed response button.
%
% Usage:
%   pair = getbuttonColor();                          % blocking, listen to all
%   pair = getbuttonColor([], false);                 % non-blocking, listen to all
%   pair = getbuttonColor(struct('right box', {{'blue'}}, ...
%                              'left box',  {{'white','red'}}));
%
% Returns:
%   out = {'right box','green'}  % cell array of two strings, or [] if none (non-blocking)
%
% Notes:
% - Reads DIN via:
%       Datapixx('RegWrRd');
%       val = Datapixx('GetDinValues');
% - Looks only at the last 10 DIN bits (response lines).
% - If multiple lines are high or mapping is ambiguous, keeps polling (in blocking mode).

    if nargin < 1 || isempty(selection), selection = []; end
    if nargin < 2 || isempty(blocking),  blocking  = true; end

    % ---------- mapping (same semantics as your Python code) ----------
    % response code -> list of (box,color) pairs
    % (index = code 1..10 ; each value = Nx2 cell array of {'box','color'})
    RESP_TO_PAIRS = buildRespToPairs();

    % valid response codes present in mapping
    ALL_RESPONSE_CODES = find(~cellfun(@isempty, RESP_TO_PAIRS));

    % normalize selection to a set of allowed (box,color) pairs (lower-case)
    listen_pairs = normalizeSelection(selection);

    % main read loop
    if blocking
        while true
            pair = pollOnce(RESP_TO_PAIRS, ALL_RESPONSE_CODES, listen_pairs);
            if ~isempty(pair)
                out = pair;  % cellstr {'right box','green'}
                return
            end
            % otherwise keep polling
        end
    else
        out = pollOnce(RESP_TO_PAIRS, ALL_RESPONSE_CODES, listen_pairs); % [] if none/ambiguous
    end
end

% =====================================================================
function pair = pollOnce(RESP_TO_PAIRS, ALL_RESPONSE_CODES, listen_pairs)
    % One-shot poll; returns {'box','color'} or []

    Datapixx('RegWrRd');
    raw = Datapixx('GetDinValues');

    % Make a fixed-width binary string (24 bits matches your Python constant)
    % dec2bin returns MSB..LSB, so the LAST char is LSB.
    binStr = dec2bin(raw, 24);

    % Take last 10 bits (LSB on the RIGHT), then flip so index 1 -> code 1 (LSB)
    last10 = binStr(end-9:end);
    button_box = double(last10(end:-1:1) == '1'); % 1x10 numeric array

    % Which response codes are active?
    resp_codes = find(button_box == 1);                 % 1..10
    resp_codes = intersect(resp_codes, ALL_RESPONSE_CODES);

    if numel(resp_codes) ~= 1
        pair = [];  % none or multiple lines high → ignore this sample
        return
    end

    resp = resp_codes(1);
    candidates = RESP_TO_PAIRS{resp};  % Nx2 cell: {'right box','green'; ...}

    % If a selection was provided, intersect.
    if ~isempty(listen_pairs)
        keep = false(size(candidates,1),1);
        for i = 1:size(candidates,1)
            keep(i) = any( strcmpi(candidates{i,1}, listen_pairs(:,1)) & ...
                           strcmpi(candidates{i,2}, listen_pairs(:,2)) );
        end
        candidates = candidates(keep,:);
    end

    if size(candidates,1) == 1
        pair = candidates(1,:);  % {'box','color'}
    else
        % ambiguous or filtered out → no decision
        % fprintf('Ambiguous press on resp=%d; candidates: %s\n', resp, join(strcat(candidates(:,1),"/",candidates(:,2))', ', '));
        pair = [];
    end
end

% =====================================================================
function listen_pairs = normalizeSelection(selection)
    % Return Nx2 cell array of {'box','color'} (lower-case), or [] if "listen to all".
    if isempty(selection)
        % build full set from mapping
        mapping = buttonMapping();
        ks = mapping.keys;
        rows = {};
        for i = 1:numel(ks)
            rows(end+1,:) = strsplit(ks{i}, '|'); %#ok<AGROW>
        end
        listen_pairs = rows;
        return
    end

    % selection can use right_box/left_box OR 'right box'/'left box'
    listen_pairs = {};
    fns = fieldnames(selection);
    for i = 1:numel(fns)
        rawBox = lower(strtrim(fns{i}));
        % allow underscores
        rawBox = strrep(rawBox, '_', ' ');
        if ~ismember(rawBox, {'right box','left box'})
            error('Unknown selection box: %s (use right_box/left_box or "right box"/"left box")', fns{i});
        end
        colors = selection.(fns{i});
        if ischar(colors), colors = {colors}; end
        for j = 1:numel(colors)
            color = lower(strtrim(colors{j}));
            key = [rawBox '|' color];
            if ~buttonMapping().isKey(key)
                error('Unknown selection: %s / %s', rawBox, color);
            end
            listen_pairs(end+1,:) = {rawBox, color}; %#ok<AGROW>
        end
    end
    % de-duplicate
    if ~isempty(listen_pairs)
        tags = cellfun(@(a,b)[a '|' b], listen_pairs(:,1), listen_pairs(:,2), 'uni',0);
        [~, ia] = unique(tags, 'stable');
        listen_pairs = listen_pairs(ia,:);
    end
end


% =====================================================================
function RESP_TO_PAIRS = buildRespToPairs()
    % Build reverse map: response code -> list of (box,color)
    % Uses the mapping below where each entry has fields .response and .listen_to
    M = buttonMapping();  % key 'box|color' -> struct
    RESP_TO_PAIRS = cell(1, 10);  % codes 1..10 (expand if you use more)
    keys = M.keys;
    for i = 1:numel(keys)
        info = M(keys{i});

        resp = info.response;
        if resp < 1 || resp > numel(RESP_TO_PAIRS), continue; end
        if isempty(RESP_TO_PAIRS{resp})
            RESP_TO_PAIRS{resp} = {};
        end

        parts = strsplit(keys{i}, '|');
        RESP_TO_PAIRS{resp}(end+1,:) = {parts{1}, parts{2}}; %#ok<AGROW>
    end
end

% =====================================================================
function M = buttonMapping()
    % Flattened version of your Python button_mapping, lower-case keys.
    % key: 'right box|white' -> struct('response',6,'listen_to',5), etc.
    %
    % Update these integers to match your wiring.
    K = {};
    V = {};

    % right box
    K{end+1} = 'left box|white';  V{end+1} = struct('response', 5 );
    K{end+1} = 'left box|red';    V{end+1} = struct('response', 1);
    K{end+1} = 'left box|yellow'; V{end+1} = struct('response', 2);
    K{end+1} = 'left box|green';  V{end+1} = struct('response', 3);
    K{end+1} = 'left box|blue';   V{end+1} = struct('response', 4);

    % left box
    K{end+1} = 'right box|white';  V{end+1} = struct('response', 10);
    K{end+1} = 'right box|red';    V{end+1} = struct('response', 6);
    K{end+1} = 'right box|yellow'; V{end+1} = struct('response', 7);
    K{end+1} = 'right box|green';  V{end+1} = struct('response', 8);
    K{end+1} = 'right box|blue';   V{end+1} = struct('response', 9);

    M = containers.Map(K, V);
end

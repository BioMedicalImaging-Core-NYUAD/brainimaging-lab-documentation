function kb = setup_keyboard(pa)
% SETUP_KEYBOARD - Key mappings for the NJM task
%
% Input:
%   pa - Parameters structure (uses pa.P.response.keyboard_keys)
%
% Output:
%   kb - escKey, tKey, fiveKey, spaceKey, leftKey, rightKey, backKey and
%        kb.responseKeys(1:4): keyboard keys that stand for buttons 1-4
%        (keyboard testing; in the scanner the VPixx box is used)

KbName('UnifyKeyNames');

kb.escKey = KbName('ESCAPE');
kb.tKey = KbName('t');
kb.fiveKey = KbName('5%');
kb.spaceKey = KbName('space');
kb.leftKey = KbName('LeftArrow');
kb.rightKey = KbName('RightArrow');
kb.backKey = KbName('b');

names = pa.P.response.keyboard_keys;
kb.responseKeys = zeros(1, numel(names));
for i = 1:numel(names)
    kb.responseKeys(i) = KbName(names{i});
end

end

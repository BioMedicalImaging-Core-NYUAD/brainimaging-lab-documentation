function kb = setup_keyboard()
% SETUP_KEYBOARD - Keyboard mappings for checkerboard HRF task.

KbName('UnifyKeyNames');

kb.escKey = KbName('ESCAPE');
kb.oneKey = KbName('1!');
kb.tKey = KbName('t');

kb.responseKeys = [kb.oneKey];

end

function kb = setup_keyboard()
% SETUP_KEYBOARD - Keyboard mappings for motion localizer.

KbName('UnifyKeyNames');

kb.escKey = KbName('ESCAPE');
kb.oneKey = KbName('1!');
kb.tKey = KbName('t');

% Fixation-change detection buttons
kb.responseKeys = [kb.oneKey];
kb.responseGiven = 0;

end

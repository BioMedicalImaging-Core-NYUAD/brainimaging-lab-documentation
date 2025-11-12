function kb = setup_keyboard()
% SETUP_KEYBOARD - Setup keyboard mappings for button-pressing experiment
%
% Output:
%   kb - Keyboard structure with key mappings and color associations
%
% Usage:
%   kb = setup_keyboard();

% Unify key names across platforms
KbName('UnifyKeyNames');

% Define keyboard keys
kb.escKey = KbName('ESCAPE');
kb.oneKey = KbName('1!');
kb.twoKey = KbName('2@');
kb.threeKey = KbName('3#');
kb.fourKey = KbName('4$');
kb.fiveKey = KbName('5%');
kb.tKey = KbName('t');

% Map keys to color responses for the experiment
% In debug mode: 1=white, 2=red, 3=yellow, 4=green, 5=blue
kb.colorKeys = [kb.oneKey, kb.twoKey, kb.threeKey, kb.fourKey, kb.fiveKey];
kb.colorNames = {'white', 'red', 'yellow', 'green', 'blue'};

% Initialize response variables
kb.responseGiven = 0;
kb.responseButton = '';
kb.responseTime = NaN;

end

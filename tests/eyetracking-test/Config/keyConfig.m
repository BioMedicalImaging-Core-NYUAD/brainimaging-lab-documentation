function [my_key] = keyConfig()
% keyConfig - Keyboard configuration

KbName('UnifyKeyNames');

my_key.escape = KbName('ESCAPE');
my_key.space = KbName('space');
my_key.return = KbName('Return');
my_key.t = KbName('t');
my_key.five = KbName('5%');

end

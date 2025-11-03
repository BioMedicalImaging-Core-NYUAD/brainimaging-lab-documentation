function [responseReceived, responseButton, responseTime] = check_response(kb, firstPress, responseStartTime)
% CHECK_KEYBOARD_RESPONSE - Check for keyboard response and return color
%
% Inputs:
%   kb - Keyboard structure from setup_keyboard()
%   firstPress - firstPress array from KbQueueCheck
%   responseStartTime - Time when response period started
%
% Outputs:
%   responseReceived - Boolean indicating if a valid response was detected
%   responseButton - String with color name ('white', 'red', etc.) or empty
%   responseTime - Reaction time in seconds or NaN
%
% Usage:
%   [received, button, rt] = check_keyboard_response(kb, firstPress, startTime);

% Initialize output variables
responseReceived = false;
responseButton = '';
responseTime = NaN;

% Check each color key
for i = 1:length(kb.colorKeys)
    if firstPress(kb.colorKeys(i))
        responseButton = kb.colorNames{i};
        responseReceived = true;
        responseTime = firstPress(kb.colorKeys(i)) - responseStartTime;
        break;  % Stop after first valid response
    end
end

end

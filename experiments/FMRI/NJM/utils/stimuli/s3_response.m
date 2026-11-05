function [pa, exitFlag, currentFixationAngle, responseReceived, responseButton, responseTime] = s3_response(VP, pa, kb, experimentStartTime, currentFixationAngle, debugConfig)
% S3_RESPONSE - Response phase waiting for button press
%
% Input:
%   VP, pa, kb - Standard experiment structures
%   experimentStartTime - GetSecs time of the scanner trigger (time zero)
%   currentFixationAngle - Current angle of traveling dot
%   debugConfig - Debug configuration structure
%
% Output:
%   pa - Updated parameters structure
%   exitFlag - 1 if ESC pressed, 0 otherwise
%   currentFixationAngle - Updated angle
%   responseReceived - Whether response was received
%   responseButton - Button/color that was pressed
%   responseTime - Response time in seconds, from the onset of the response screen

responseReceived = false;
responseTime = NaN;
responseButton = '';
exitFlag = 0;

% Use the VPixx button box only if requested, available, and not already failed
useButtonBox = false;
if debugConfig.buttonbox && debugConfig.useVPixx && ...
        ~(isfield(pa, 'buttonBoxFailed') && pa.buttonBoxFailed)
    try
        useButtonBox = Datapixx('IsReady');
    catch
        useButtonBox = false;
    end
end

% First frame at its scheduled time (trigger-locked, see start_phase).
% Reaction times are measured from this onset.
currentFixationAngle = pa.fixationSpeed * (GetSecs - experimentStartTime);
drawCircleWithDot(VP.window, VP.windowCenter, pa.fixationRadiusPix, currentFixationAngle, ...
    pa.travelingDotRadiusPix, pa.dotColor, pa.circleColorDefault, ...
    pa.circleLineWidth, VP.backGroundColor, pa.dotCache);
[pa, phaseEnd, responseStartTime] = start_phase(VP, pa, experimentStartTime, pa.responseWindow, 'response');

% Discard presses made before the response screen appeared
KbQueueFlush();

while GetSecs < phaseEnd - 0.5 * VP.ifi
    currentFixationAngle = pa.fixationSpeed * (GetSecs - experimentStartTime);

    drawCircleWithDot(VP.window, VP.windowCenter, pa.fixationRadiusPix, currentFixationAngle, ...
        pa.travelingDotRadiusPix, pa.dotColor, pa.circleColorDefault, ...
        pa.circleLineWidth, VP.backGroundColor, pa.dotCache);

    Screen('Flip', VP.window);

    % Read the keyboard queue ONCE per frame: KbQueueCheck empties the queue,
    % so a second call in the same frame would lose the key press
    [pressed, firstPress] = KbQueueCheck();
    if pressed && firstPress(kb.escKey)
        fprintf('\n*** Experiment terminated by user (ESC pressed during response) ***\n');
        exitFlag = 1;
        break;
    end

    if pa.eyeTrackingEnabled
        pa = record_continuous_gaze(pa, experimentStartTime);
    end

    if ~responseReceived
        if useButtonBox
            try
                pair = getButtonColor([], false);
                if ~isempty(pair)
                    responseReceived = true;
                    responseTime = GetSecs - responseStartTime;
                    responseButton = pair{2};
                end
            catch ME
                fprintf('Warning: VPixx button box error (%s). Using keyboard from now on.\n', ME.message);
                pa.buttonBoxFailed = true;
                useButtonBox = false;
            end
        end

        if ~useButtonBox && pressed
            [responseReceived, responseButton, responseTime] = ...
                check_response(kb, firstPress, responseStartTime);
        end
    end
end

end

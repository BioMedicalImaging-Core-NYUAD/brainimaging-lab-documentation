function [pa, exitFlag, currentFixationAngle] = s4_feedback(VP, pa, kb, experimentStartTime, currentFixationAngle, responseReceived, correct)
% S4_FEEDBACK - Feedback phase with colored dot
%
% Input:
%   VP, pa, kb - Standard experiment structures
%   experimentStartTime - GetSecs time of the scanner trigger (time zero)
%   currentFixationAngle - Current angle of traveling dot
%   responseReceived - Whether response was received
%   correct - Whether response was correct
%
% Output:
%   pa - Updated parameters structure
%   exitFlag - 1 if ESC pressed, 0 otherwise
%   currentFixationAngle - Updated angle

exitFlag = 0;

if responseReceived && correct
    feedbackDotColor = pa.dotColorCorrect;
else
    feedbackDotColor = pa.dotColorIncorrect;
end

% First frame at its scheduled time (trigger-locked, see start_phase)
currentFixationAngle = pa.fixationSpeed * (GetSecs - experimentStartTime);
drawCircleWithDot(VP.window, VP.windowCenter, pa.fixationRadiusPix, currentFixationAngle, ...
    pa.travelingDotRadiusPix, feedbackDotColor, pa.circleColorDefault, ...
    pa.circleLineWidth, VP.backGroundColor, pa.dotCache);
[pa, phaseEnd] = start_phase(VP, pa, experimentStartTime, pa.feedbackDuration, 'feedback');

while GetSecs < phaseEnd - 0.5 * VP.ifi
    currentFixationAngle = pa.fixationSpeed * (GetSecs - experimentStartTime);

    drawCircleWithDot(VP.window, VP.windowCenter, pa.fixationRadiusPix, currentFixationAngle, ...
        pa.travelingDotRadiusPix, feedbackDotColor, pa.circleColorDefault, ...
        pa.circleLineWidth, VP.backGroundColor, pa.dotCache);

    Screen('Flip', VP.window);

    [pressed, firstPress] = KbQueueCheck();
    if pressed && firstPress(kb.escKey)
        fprintf('\n*** Experiment terminated by user (ESC pressed during feedback) ***\n');
        exitFlag = 1;
        break;
    end

    if pa.eyeTrackingEnabled
        pa = record_continuous_gaze(pa, experimentStartTime);
    end
end

end

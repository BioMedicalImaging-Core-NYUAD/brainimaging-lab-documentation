function [pa, exitFlag, currentFixationAngle] = s1_startExp(VP, pa, kb, experimentStartTime, currentFixationAngle)
% S1_STARTEXP - Start experiment period with moving dot only
%
% Input:
%   VP, pa, kb - Standard experiment structures
%   experimentStartTime - GetSecs time of the scanner trigger (time zero)
%   currentFixationAngle - Current angle of traveling dot
%
% Output:
%   pa - Updated parameters structure
%   exitFlag - 1 if ESC pressed, 0 otherwise
%   currentFixationAngle - Updated angle

exitFlag = 0;

% First frame at its scheduled time (trigger-locked, see start_phase)
currentFixationAngle = pa.fixationSpeed * (GetSecs - experimentStartTime);
drawCircleWithDot(VP.window, VP.windowCenter, pa.fixationRadiusPix, currentFixationAngle, ...
    pa.travelingDotRadiusPix, pa.dotColor, pa.circleColorDefault, ...
    pa.circleLineWidth, VP.backGroundColor, pa.dotCache);
[pa, phaseEnd] = start_phase(VP, pa, experimentStartTime, pa.startExpDuration, 'start');

while GetSecs < phaseEnd - 0.5 * VP.ifi
    currentFixationAngle = pa.fixationSpeed * (GetSecs - experimentStartTime);

    drawCircleWithDot(VP.window, VP.windowCenter, pa.fixationRadiusPix, currentFixationAngle, ...
        pa.travelingDotRadiusPix, pa.dotColor, pa.circleColorDefault, ...
        pa.circleLineWidth, VP.backGroundColor, pa.dotCache);

    Screen('Flip', VP.window);

    [pressed, firstPress] = KbQueueCheck();
    if pressed && firstPress(kb.escKey)
        fprintf('\n*** Experiment terminated by user (ESC pressed during start) ***\n');
        exitFlag = 1;
        break;
    end

    if pa.eyeTrackingEnabled
        pa = record_continuous_gaze(pa, experimentStartTime);
    end
end

end

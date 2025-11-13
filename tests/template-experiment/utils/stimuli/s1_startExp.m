function [pa, exitFlag, currentFixationAngle] = s1_startExp(VP, pa, kb, experimentStartTime, currentFixationAngle)
% S1_STARTEXP - Start experiment period with moving dot only
%
% Input:
%   VP, pa, kb - Standard experiment structures
%   experimentStartTime - Start time of experiment
%   currentFixationAngle - Current angle of traveling dot
%
% Output:
%   pa - Updated parameters structure
%   exitFlag - 1 if ESC pressed, 0 otherwise
%   currentFixationAngle - Updated angle

startExpStartTime = GetSecs;
startExpEndTime = startExpStartTime + pa.startExpDuration;
vbl = startExpStartTime;
exitFlag = 0;

while GetSecs < startExpEndTime
    currentTime = GetSecs;
    currentFixationAngle = pa.fixationSpeed * (currentTime - experimentStartTime);
    
    drawCircleWithDot(VP.window, VP.windowCenter, pa.fixationRadiusPix, currentFixationAngle, ...
        pa.travelingDotRadiusPix, pa.dotColor, pa.circleColorDefault, ...
        pa.circleLineWidth, VP.backGroundColor);
    
    vbl = Screen('Flip', VP.window, vbl + 0.5 * VP.ifi);
    
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


function [pa, exitFlag, currentFixationAngle] = s5_iti(VP, pa, kb, experimentStartTime, currentFixationAngle)
% S5_ITI - Inter-trial interval phase
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

itiStartTime = GetSecs;
itiEndTime = itiStartTime + pa.itiDuration;
vbl = itiStartTime;
exitFlag = 0;

while GetSecs < itiEndTime
    currentTime = GetSecs;
    currentFixationAngle = pa.fixationSpeed * (currentTime - experimentStartTime);
    
    drawCircleWithDot(VP.window, VP.windowCenter, pa.fixationRadiusPix, currentFixationAngle, ...
        pa.travelingDotRadiusPix, pa.dotColor, pa.circleColorDefault, ...
        pa.circleLineWidth, VP.backGroundColor, pa.dotCache);
    
    vbl = Screen('Flip', VP.window, vbl + 0.5 * VP.ifi);
    
    [pressed, firstPress] = KbQueueCheck();
    if pressed && firstPress(kb.escKey)
        fprintf('\n*** Experiment terminated by user (ESC pressed during ITI) ***\n');
        exitFlag = 1;
        break;
    end
    
    if pa.eyeTrackingEnabled
        pa = record_continuous_gaze(pa, experimentStartTime);
    end
end

end


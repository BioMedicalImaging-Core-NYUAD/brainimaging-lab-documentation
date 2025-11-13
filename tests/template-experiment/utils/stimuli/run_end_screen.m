function [pa, exitFlag, currentFixationAngle, blinkCounter] = run_end_screen(VP, pa, kb, experimentStartTime, currentFixationAngle, blinkCounter, blinkFrameThresh)
% RUN_END_SCREEN - Run end screen phase
%
% Input:
%   VP, pa, kb - Standard experiment structures
%   experimentStartTime - Start time of experiment
%   currentFixationAngle - Current angle of traveling dot
%   blinkCounter - Current blink counter
%   blinkFrameThresh - Blink frame threshold
%
% Output:
%   pa - Updated parameters structure
%   exitFlag - 1 if ESC pressed, 0 otherwise
%   currentFixationAngle - Updated angle
%   blinkCounter - Updated blink counter

endScreenStartTime = GetSecs;
endScreenEndTime = endScreenStartTime + pa.endScreenDuration;
vbl = endScreenStartTime;
exitFlag = 0;

while GetSecs < endScreenEndTime
    currentTime = GetSecs;
    currentFixationAngle = pa.fixationSpeed * (currentTime - experimentStartTime);
    
    drawCircleWithDot(VP.window, VP.windowCenter, pa.fixationRadiusPix, currentFixationAngle, ...
        pa.travelingDotRadiusPix, pa.dotColor, pa.circleColorDefault, ...
        pa.circleLineWidth, VP.backGroundColor);
    
    vbl = Screen('Flip', VP.window, vbl + 0.5 * VP.ifi);
    
    [pressed, firstPress] = KbQueueCheck();
    if pressed && firstPress(kb.escKey)
        fprintf('\n*** Experiment terminated by user (ESC pressed during end screen) ***\n');
        exitFlag = 1;
        break;
    end
    
    if pa.eyeTrackingEnabled
        evt = Eyelink('newestfloatsample');
        xPos = evt.gx; yPos = evt.gy;
        if isequal(xPos(1), xPos(2), yPos(1), yPos(2))
            blinkCounter = blinkCounter + 1;
            if blinkCounter >= blinkFrameThresh
                % play alarm: Beeper(400, 0.8, 1);
            end
        else
            blinkCounter = 0;
        end
        pa = record_continuous_gaze(pa, experimentStartTime);
    end
end

end


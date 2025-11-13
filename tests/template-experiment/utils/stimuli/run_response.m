function [pa, exitFlag, currentFixationAngle, blinkCounter, responseReceived, responseButton, responseTime] = run_response(VP, pa, kb, experimentStartTime, currentFixationAngle, blinkCounter, blinkFrameThresh, debugConfig)
% RUN_RESPONSE - Run response phase waiting for button press
%
% Input:
%   VP, pa, kb - Standard experiment structures
%   experimentStartTime - Start time of experiment
%   currentFixationAngle - Current angle of traveling dot
%   blinkCounter - Current blink counter
%   blinkFrameThresh - Blink frame threshold
%   debugConfig - Debug configuration structure
%
% Output:
%   pa - Updated parameters structure
%   exitFlag - 1 if ESC pressed, 0 otherwise
%   currentFixationAngle - Updated angle
%   blinkCounter - Updated blink counter
%   responseReceived - Whether response was received
%   responseButton - Button/color that was pressed
%   responseTime - Response time in seconds

responseStartTime = GetSecs;
responseReceived = false;
responseTime = NaN;
responseButton = '';
vbl = responseStartTime;
exitFlag = 0;

KbQueueFlush();

while (GetSecs - responseStartTime) < pa.responseWindow
    currentTime = GetSecs;
    currentFixationAngle = pa.fixationSpeed * (currentTime - experimentStartTime);
    
    drawCircleWithDot(VP.window, VP.windowCenter, pa.fixationRadiusPix, currentFixationAngle, ...
        pa.travelingDotRadiusPix, pa.dotColor, pa.circleColorDefault, ...
        pa.circleLineWidth, VP.backGroundColor);
    
    vbl = Screen('Flip', VP.window, vbl + 0.5 * VP.ifi);
    
    [pressed, firstPress] = KbQueueCheck();
    if pressed && firstPress(kb.escKey)
        fprintf('\n*** Experiment terminated by user (ESC pressed during response) ***\n');
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
    
    if ~responseReceived
        vpixxReady = false;
        if debugConfig.buttonbox && debugConfig.useVPixx
            try
                vpixxReady = Datapixx('IsReady');
            catch
                vpixxReady = false;
            end
        end
        
        if ~debugConfig.buttonbox || ~vpixxReady
            [pressed, firstPress] = KbQueueCheck();
            if pressed
                [responseReceived, responseButton, responseTime] = ...
                    check_response(kb, firstPress, responseStartTime);
            end
        else
            try
                pair = getButtonColor([], false);
                if ~isempty(pair)
                    responseReceived = true;
                    responseTime = GetSecs - responseStartTime;
                    responseButton = pair{2};
                end
            catch ME
                fprintf('Warning: VPixx button box error, falling back to keyboard\n');
                [pressed, firstPress] = KbQueueCheck();
                if pressed
                    [responseReceived, responseButton, responseTime] = ...
                        check_response(kb, firstPress, responseStartTime);
                end
            end
        end
    end
end

end


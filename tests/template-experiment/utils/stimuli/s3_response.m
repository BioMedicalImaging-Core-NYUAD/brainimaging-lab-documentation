function [pa, currentFixationAngle, responseReceived, responseButton, responseTime] = s3_response(VP, pa, kb, experimentStartTime, currentFixationAngle, debugConfig)
% S3_RESPONSE - Response phase waiting for button press
%
% Input:
%   VP, pa, kb - Standard experiment structures
%   experimentStartTime - Start time of experiment
%   currentFixationAngle - Current angle of traveling dot
%   debugConfig - Debug configuration structure
%
% Output:
%   pa - Updated parameters structure
%   currentFixationAngle - Updated angle
%   responseReceived - Whether response was received
%   responseButton - Button/color that was pressed
%   responseTime - Response time in seconds

responseStartTime = GetSecs;
responseReceived = false;
responseTime = NaN;
responseButton = '';
vbl = responseStartTime;

KbQueueFlush();

while (GetSecs - responseStartTime) < pa.responseWindow
    currentTime = GetSecs;
    currentFixationAngle = pa.fixationSpeed * (currentTime - experimentStartTime);
    
    drawCircleWithDot(VP.window, VP.windowCenter, pa.fixationRadiusPix, currentFixationAngle, ...
        pa.travelingDotRadiusPix, pa.dotColor, pa.circleColorDefault, ...
        pa.circleLineWidth, VP.backGroundColor, pa.fixationLineLengthPix, pa.fixationLineWidth, pa.fixationLineColorDefault);
    
    vbl = Screen('Flip', VP.window, vbl + 0.5 * VP.ifi);
    
    [pressed, firstPress] = KbQueueCheck();
    if pressed && firstPress(kb.escKey)
        fprintf('\n*** Experiment terminated by user (ESC pressed during response) ***\n');
        error('ExperimentAborted', 'User pressed ESC to abort experiment');
    end
    
    if pa.eyeTrackingEnabled
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


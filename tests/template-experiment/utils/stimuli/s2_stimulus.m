function [pa, currentFixationAngle] = s2_stimulus(VP, pa, kb, experimentStartTime, currentFixationAngle, targetColor, targetIdx)
% S2_STIMULUS - Stimulus phase with colored circle
%
% Input:
%   VP, pa, kb - Standard experiment structures
%   experimentStartTime - Start time of experiment
%   currentFixationAngle - Current angle of traveling dot
%   targetColor - Target color name
%   targetIdx - Index of target color in pa.colors
%
% Output:
%   pa - Updated parameters structure
%   currentFixationAngle - Updated angle

stimulusStartTime = GetSecs;
stimulusEndTime = stimulusStartTime + pa.stimulusDuration;
vbl = stimulusStartTime;

if pa.eyeTrackingEnabled
    try
        Eyelink('Message', sprintf('TRIAL_%d_STIMULUS_ONSET_%s', pa.trialCounter, upper(targetColor)));
        s = Eyelink('newestfloatsample');
        gx = NaN; gy = NaN;
        if ~isempty(s)
            lx = s.gx(1); ly = s.gy(1);
            rx = s.gx(2); ry = s.gy(2);
            if ~isnan(lx) && ~isnan(ly)
                gx = lx; gy = ly;
            elseif ~isnan(rx) && ~isnan(ry)
                gx = rx; gy = ry;
            end
        end
        pa.data.gazeX(pa.trialCounter) = gx;
        pa.data.gazeY(pa.trialCounter) = gy;
    catch
    end
end

while GetSecs < stimulusEndTime
    currentTime = GetSecs;
    currentFixationAngle = pa.fixationSpeed * (currentTime - experimentStartTime);
    
    drawCircleWithDot(VP.window, VP.windowCenter, pa.fixationRadiusPix, currentFixationAngle, ...
        pa.travelingDotRadiusPix, pa.dotColor, pa.colorRGB(targetIdx,:), ...
        pa.circleLineWidth, VP.backGroundColor);
    
    vbl = Screen('Flip', VP.window, vbl + 0.5 * VP.ifi);
    
    [pressed, firstPress] = KbQueueCheck();
    if pressed && firstPress(kb.escKey)
        fprintf('\n*** Experiment terminated by user (ESC pressed during stimulus) ***\n');
        error('ExperimentAborted', 'User pressed ESC to abort experiment');
    end
    
    if pa.eyeTrackingEnabled
        pa = record_continuous_gaze(pa, experimentStartTime);
    end
end

end


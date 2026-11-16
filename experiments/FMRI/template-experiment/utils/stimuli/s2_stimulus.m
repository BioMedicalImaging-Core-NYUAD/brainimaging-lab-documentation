function [pa, exitFlag, currentFixationAngle] = s2_stimulus(VP, pa, kb, experimentStartTime, currentFixationAngle, targetColor, targetIdx)
% S2_STIMULUS - Stimulus phase with colored circle
%
% Input:
%   VP, pa, kb - Standard experiment structures
%   experimentStartTime - GetSecs time of the scanner trigger (time zero)
%   currentFixationAngle - Current angle of traveling dot
%   targetColor - Target color name
%   targetIdx - Index of target color in pa.colors
%
% Output:
%   pa - Updated parameters structure (trial onset stored in pa.data)
%   exitFlag - 1 if ESC pressed, 0 otherwise
%   currentFixationAngle - Updated angle

exitFlag = 0;

% First frame at its scheduled time (trigger-locked, see start_phase)
currentFixationAngle = pa.fixationSpeed * (GetSecs - experimentStartTime);
drawCircleWithDot(VP.window, VP.windowCenter, pa.fixationRadiusPix, currentFixationAngle, ...
    pa.travelingDotRadiusPix, pa.dotColor, pa.colorRGB(targetIdx,:), ...
    pa.circleLineWidth, VP.backGroundColor, pa.dotCache);
[pa, phaseEnd, onsetTime] = start_phase(VP, pa, experimentStartTime, pa.stimulusDuration, 'stimulus');

% Trial onset = actual onset of the stimulus frame, in seconds from the trigger
pa.data.trialStartTime(pa.trialCounter) = onsetTime - experimentStartTime;
pa.data.cumulativeTime(pa.trialCounter) = onsetTime - experimentStartTime;

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

while GetSecs < phaseEnd - 1.5 * VP.ifi   % stop one frame early so the next phase starts on time
    currentFixationAngle = pa.fixationSpeed * (GetSecs - experimentStartTime);

    drawCircleWithDot(VP.window, VP.windowCenter, pa.fixationRadiusPix, currentFixationAngle, ...
        pa.travelingDotRadiusPix, pa.dotColor, pa.colorRGB(targetIdx,:), ...
        pa.circleLineWidth, VP.backGroundColor, pa.dotCache);

    Screen('Flip', VP.window);

    [pressed, firstPress] = KbQueueCheck();
    if pressed && firstPress(kb.escKey)
        fprintf('\n*** Experiment terminated by user (ESC pressed during stimulus) ***\n');
        exitFlag = 1;
        break;
    end

    if pa.eyeTrackingEnabled
        pa = record_continuous_gaze(pa, experimentStartTime);
    end
end

end

function [pa, currentFixationAngle] = s4_feedback(VP, pa, kb, experimentStartTime, currentFixationAngle, responseReceived, correct)
% S4_FEEDBACK - Feedback phase with extended fixation line for incorrect responses
%
% Input:
%   VP, pa, kb - Standard experiment structures
%   experimentStartTime - Start time of experiment
%   currentFixationAngle - Current angle of traveling dot
%   responseReceived - Whether response was received
%   correct - Whether response was correct
%
% Output:
%   pa - Updated parameters structure
%   currentFixationAngle - Updated angle

feedbackStartTime = GetSecs;
feedbackEndTime = feedbackStartTime + pa.feedbackDuration;
vbl = feedbackStartTime;

% Determine fixation line length: extended if incorrect, normal if correct
if responseReceived && ~correct
    % Incorrect: use extended length
    fixationLineLength = pa.fixationLineLengthExtendedPix;
else
    % Correct or no response: use normal length
    fixationLineLength = pa.fixationLineLengthPix;
end

while GetSecs < feedbackEndTime
    currentTime = GetSecs;
    currentFixationAngle = pa.fixationSpeed * (currentTime - experimentStartTime);
    
    % Use default black color for fixation line during feedback
    drawCircleWithDot(VP.window, VP.windowCenter, pa.fixationRadiusPix, currentFixationAngle, ...
        pa.travelingDotRadiusPix, pa.dotColor, pa.circleColorDefault, ...
        pa.circleLineWidth, VP.backGroundColor, fixationLineLength, pa.fixationLineWidth, pa.fixationLineColorDefault);
    
    vbl = Screen('Flip', VP.window, vbl + 0.5 * VP.ifi);
    
    [pressed, firstPress] = KbQueueCheck();
    if pressed && firstPress(kb.escKey)
        fprintf('\n*** Experiment terminated by user (ESC pressed during feedback) ***\n');
        error('ExperimentAborted', 'User pressed ESC to abort experiment');
    end
    
    if pa.eyeTrackingEnabled
        pa = record_continuous_gaze(pa, experimentStartTime);
    end
end

end


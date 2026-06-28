function s3_endScreen(VP, pa)
% S3_ENDSCREEN - Brief thank-you screen.

if isfield(pa, 'timingBaseTime') && ~isempty(pa.timingBaseTime) && isfield(pa, 'nextEpochOnset')
    designEndTime = pa.timingBaseTime + pa.nextEpochOnset;
elseif isfield(pa, 'experimentStartTime') && isfield(pa, 'nextEpochOnset')
    designEndTime = pa.experimentStartTime + pa.nextEpochOnset;
else
    designEndTime = [];
end

if ~isfield(pa, 'endScreenDuration') || pa.endScreenDuration <= 0
    if ~isempty(designEndTime)
        WaitSecs(max(0, designEndTime - GetSecs));
    end
    return;
end

Screen('FillRect', VP.window, VP.backGroundColor);
Screen('TextSize', VP.window, 42);
DrawFormattedText(VP.window, 'Thank you for your participation!', 'center', 'center', [255 255 255]);
% Use WaitSecs + bare Flip — bypasses broken PsychVulkanCore timed Flip.
if ~isempty(designEndTime)
    WaitSecs('UntilTime', designEndTime - 0.5 * VP.ifi);
end
Screen('Flip', VP.window);
WaitSecs(pa.endScreenDuration);

end

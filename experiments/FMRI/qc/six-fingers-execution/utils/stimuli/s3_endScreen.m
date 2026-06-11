function s3_endScreen(VP, pa)
% S3_ENDSCREEN - Brief thank-you screen.

Screen('FillRect', VP.window, VP.backGroundColor);
Screen('TextSize', VP.window, 42);
DrawFormattedText(VP.window, 'Thank you for your participation!', 'center', 'center', [255 255 255]);
if isfield(pa, 'timingBaseTime') && ~isempty(pa.timingBaseTime) && isfield(pa, 'nextEpochOnset')
    Screen('Flip', VP.window, pa.timingBaseTime + pa.nextEpochOnset - 0.5 * VP.ifi);
elseif isfield(pa, 'experimentStartTime') && isfield(pa, 'nextEpochOnset')
    Screen('Flip', VP.window, pa.experimentStartTime + pa.nextEpochOnset - 0.5 * VP.ifi);
else
    Screen('Flip', VP.window);
end
WaitSecs(pa.endScreenDuration);

end

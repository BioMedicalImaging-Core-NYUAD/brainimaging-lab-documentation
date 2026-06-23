function s4_endScreen(VP, pa)
% S4_ENDSCREEN - Optional final screen aligned to the planned design end.

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
DrawFormattedText(VP.window, 'Done', 'center', 'center', [255 255 255]);
if ~isempty(designEndTime)
    Screen('Flip', VP.window, designEndTime - 0.5 * VP.ifi);
else
    Screen('Flip', VP.window);
end
WaitSecs(pa.endScreenDuration);

end

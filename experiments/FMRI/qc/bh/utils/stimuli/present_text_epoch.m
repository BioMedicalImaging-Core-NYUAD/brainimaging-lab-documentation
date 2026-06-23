function [pa, exitFlag] = present_text_epoch(VP, pa, kb, experimentStartTime, trialType, instruction, cycleIdx, durationSec, dmRow, textColor)
% PRESENT_TEXT_EPOCH - Present one breathing instruction epoch.

exitFlag = false;
if nargin < 4 || isempty(experimentStartTime)
    experimentStartTime = GetSecs;
end
pa.requestedExperimentStartTime = experimentStartTime;

plannedOnset = pa.nextEpochOnset;
plannedEnd = plannedOnset + durationSec;
cycleText = sprintf('Cycle %d of %d', min(cycleIdx, pa.nCycles), pa.nCycles);
if cycleIdx > pa.nCycles
    cycleText = 'Final rest';
end

Screen('FillRect', VP.window, VP.backGroundColor);
Screen('TextSize', VP.window, 54);
DrawFormattedText(VP.window, instruction, 'center', VP.windowCenter(2) - 40, textColor);
Screen('TextSize', VP.window, 26);
DrawFormattedText(VP.window, cycleText, 'center', VP.windowCenter(2) + 45, pa.colors.secondary);

if ~isfield(pa, 'timingBaseTime') || isempty(pa.timingBaseTime)
    [vbl, stimulusOnset] = Screen('Flip', VP.window);
else
    targetOnset = pa.timingBaseTime + plannedOnset;
    [vbl, stimulusOnset] = Screen('Flip', VP.window, targetOnset - 0.5 * VP.ifi);
end
if isempty(stimulusOnset) || ~isfinite(stimulusOnset) || stimulusOnset <= 0
    actualOnset = vbl;
else
    actualOnset = stimulusOnset;
end
if ~isfield(pa, 'timingBaseTime') || isempty(pa.timingBaseTime)
    pa.timingBaseTime = actualOnset - plannedOnset;
    pa.experimentStartTime = pa.timingBaseTime;
end

targetOnset = pa.timingBaseTime + plannedOnset;
targetEnd = pa.timingBaseTime + plannedEnd;
fprintf('Stimulus ON: %s, cycle %d\n', trialType, cycleIdx);

lastDisplayedSecond = Inf;
while GetSecs < targetEnd - 0.5 * VP.ifi
    secondsRemaining = max(0, ceil(targetEnd - GetSecs));
    if secondsRemaining ~= lastDisplayedSecond
        Screen('FillRect', VP.window, VP.backGroundColor);
        Screen('TextSize', VP.window, 54);
        DrawFormattedText(VP.window, instruction, 'center', VP.windowCenter(2) - 55, textColor);
        Screen('TextSize', VP.window, 42);
        DrawFormattedText(VP.window, sprintf('%d', secondsRemaining), 'center', VP.windowCenter(2) + 30, [255 255 255]);
        Screen('TextSize', VP.window, 26);
        DrawFormattedText(VP.window, cycleText, 'center', VP.windowCenter(2) + 95, pa.colors.secondary);
        Screen('Flip', VP.window);
        lastDisplayedSecond = secondsRemaining;
    end

    [keyIsDown, ~, keyCode] = KbCheck(-1);
    if keyIsDown && (keyCode(kb.escKey) || keyCode(kb.qKey))
        fprintf('Experiment terminated by user.\n');
        exitFlag = true;
        break;
    end
    WaitSecs(0.005);
end

actualEnd = GetSecs;
fprintf('Stimulus OFF: %s, cycle %d\n', trialType, cycleIdx);

pa.eventCounter = pa.eventCounter + 1;
pa.events(pa.eventCounter).onset = plannedOnset;
pa.events(pa.eventCounter).duration = durationSec;
pa.events(pa.eventCounter).trial_type = trialType;
pa.events(pa.eventCounter).instruction = instruction;
pa.events(pa.eventCounter).cycle = cycleIdx;

pa.actualTiming(pa.eventCounter).plannedOnset = plannedOnset;
pa.actualTiming(pa.eventCounter).plannedDuration = durationSec;
pa.actualTiming(pa.eventCounter).actualOnset = actualOnset - pa.timingBaseTime;
pa.actualTiming(pa.eventCounter).waitReturn = actualEnd - pa.timingBaseTime;
pa.actualTiming(pa.eventCounter).onsetDelay = actualOnset - targetOnset;
pa.actualTiming(pa.eventCounter).trial_type = trialType;
pa.actualTiming(pa.eventCounter).instruction = instruction;
pa.actualTiming(pa.eventCounter).cycle = cycleIdx;
pa.nextEpochOnset = plannedEnd;

nRows = round(durationSec);
pa.designMatrix = [pa.designMatrix; repmat(dmRow, nRows, 1)];

end

function [pa, exitFlag] = present_image_epoch(VP, pa, kb, experimentStartTime, imagePath, trialType, fingerName, blockIdx, trialInBlock, durationSec, dmRow)
% PRESENT_IMAGE_EPOCH - Present one image epoch and append timing/design data.

exitFlag = false;

if ~exist(imagePath, 'file')
    error('present_image_epoch:missingImage', 'Could not find image: %s', imagePath);
end

if ~isfield(pa, 'textureMap') || ~isKey(pa.textureMap, imagePath)
    error('present_image_epoch:missingTexture', 'Image was not preloaded: %s', imagePath);
end

imageTexture = pa.textureMap(imagePath);
imageRect = Screen('Rect', imageTexture);
scaleFactor = 0.3;
targetRect = CenterRectOnPointd(imageRect * scaleFactor, VP.windowCenter(1), VP.windowCenter(2));

plannedOnset = pa.nextEpochOnset;
plannedEnd = plannedOnset + durationSec;

% Draw stimulus and tell GPU to start processing now (not at Flip time).
Screen('FillRect', VP.window, VP.backGroundColor);
Screen('DrawTexture', VP.window, imageTexture, [], targetRect);
Screen('DrawingFinished', VP.window);

% Use WaitSecs + bare Flip instead of timed Flip — bypasses broken
% PsychVulkanCore timed-presentation path on macOS.
if ~isfield(pa, 'timingBaseTime') || isempty(pa.timingBaseTime)
    Screen('Flip', VP.window);
else
    targetOnset = pa.timingBaseTime + plannedOnset;
    WaitSecs('UntilTime', targetOnset - 0.5 * VP.ifi);
    Screen('Flip', VP.window);
end

% Use GetSecs for onset — Flip return values (vbl/stimulusOnset) are
% unreliable with PsychVulkanCore on macOS.
actualOnset = GetSecs;

if ~isfield(pa, 'timingBaseTime') || isempty(pa.timingBaseTime)
    pa.timingBaseTime = actualOnset - plannedOnset;
    pa.experimentStartTime = pa.timingBaseTime;
end
targetOnset = pa.timingBaseTime + plannedOnset;
targetEnd = pa.timingBaseTime + plannedEnd;
fprintf('Stimulus ON: %s (%s)\n', fingerName, trialType);

% Continuously redraw and flip every frame to keep GPU pipeline warm —
% prevents PsychVulkanCore stalls on the next epoch's first Flip.
while GetSecs < targetEnd - 0.5 * VP.ifi
    [keyIsDown, ~, keyCode] = KbCheck(-1);
    if keyIsDown && (keyCode(kb.escKey) || keyCode(kb.qKey))
        fprintf('Experiment terminated by user.\n');
        exitFlag = true;
        break;
    end
    Screen('FillRect', VP.window, VP.backGroundColor);
    Screen('DrawTexture', VP.window, imageTexture, [], targetRect);
    Screen('Flip', VP.window);
end

actualEnd = GetSecs;

fprintf('Stimulus OFF: %s (%s)\n', fingerName, trialType);

pa.eventCounter = pa.eventCounter + 1;
pa.events(pa.eventCounter).onset = plannedOnset;
pa.events(pa.eventCounter).duration = durationSec;
pa.events(pa.eventCounter).trial_type = trialType;
pa.events(pa.eventCounter).finger = fingerName;
pa.events(pa.eventCounter).block = blockIdx;
pa.events(pa.eventCounter).trial = trialInBlock;

pa.actualTiming(pa.eventCounter).plannedOnset = plannedOnset;
pa.actualTiming(pa.eventCounter).plannedDuration = durationSec;
pa.actualTiming(pa.eventCounter).actualOnset = actualOnset - pa.timingBaseTime;
pa.actualTiming(pa.eventCounter).waitReturn = actualEnd - pa.timingBaseTime;
pa.actualTiming(pa.eventCounter).onsetDelay = actualOnset - targetOnset;
pa.actualTiming(pa.eventCounter).trial_type = trialType;
pa.actualTiming(pa.eventCounter).finger = fingerName;
pa.actualTiming(pa.eventCounter).block = blockIdx;
pa.actualTiming(pa.eventCounter).trial = trialInBlock;
pa.nextEpochOnset = plannedEnd;

nRows = round(durationSec);
pa.designMatrix = [pa.designMatrix; repmat(dmRow, nRows, 1)];

end

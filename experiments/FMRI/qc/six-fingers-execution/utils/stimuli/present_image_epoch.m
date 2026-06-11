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

Screen('FillRect', VP.window, VP.backGroundColor);
Screen('DrawTexture', VP.window, imageTexture, [], targetRect);
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
fprintf('Stimulus ON: %s (%s)\n', fingerName, trialType);

while GetSecs < targetEnd - 0.5 * VP.ifi
    [keyIsDown, ~, keyCode] = KbCheck(-1);
    if keyIsDown && (keyCode(kb.escKey) || keyCode(kb.qKey))
        fprintf('Experiment terminated by user.\n');
        exitFlag = true;
        break;
    end
    WaitSecs(0.01);
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

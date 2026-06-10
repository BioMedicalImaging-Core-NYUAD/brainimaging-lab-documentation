function [pa, exitFlag] = present_image_epoch(VP, pa, kb, experimentStartTime, imagePath, trialType, fingerName, blockIdx, trialInBlock, durationSec, dmRow)
% PRESENT_IMAGE_EPOCH - Present one image epoch and append timing/design data.

exitFlag = false;

if ~exist(imagePath, 'file')
    error('present_image_epoch:missingImage', 'Could not find image: %s', imagePath);
end

imgMatrix = imread(imagePath);
imageTexture = Screen('MakeTexture', VP.window, imgMatrix);
imageRect = Screen('Rect', imageTexture);
scaleFactor = 0.3;
targetRect = CenterRectOnPointd(imageRect * scaleFactor, VP.windowCenter(1), VP.windowCenter(2));

epochStart = GetSecs;
epochEnd = epochStart + durationSec;

fprintf('Stimulus ON: %s (%s)\n', fingerName, trialType);

while GetSecs < epochEnd
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
Screen('Close', imageTexture);

fprintf('Stimulus OFF: %s (%s)\n', fingerName, trialType);

pa.eventCounter = pa.eventCounter + 1;
pa.events(pa.eventCounter).onset = epochStart - experimentStartTime;
pa.events(pa.eventCounter).duration = actualEnd - epochStart;
pa.events(pa.eventCounter).trial_type = trialType;
pa.events(pa.eventCounter).finger = fingerName;
pa.events(pa.eventCounter).block = blockIdx;
pa.events(pa.eventCounter).trial = trialInBlock;

nRows = round(durationSec);
pa.designMatrix = [pa.designMatrix; repmat(dmRow, nRows, 1)];

end

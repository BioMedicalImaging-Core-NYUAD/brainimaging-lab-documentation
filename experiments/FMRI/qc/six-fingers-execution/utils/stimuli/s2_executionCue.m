function [pa, exitFlag] = s2_executionCue(VP, pa, kb, experimentStartTime, blockIdx, trialInBlock, fingerName)
% S2_EXECUTIONCUE - Present one highlighted finger cue (flexing or tapping).

imagePath = fullfile(pa.imageDir, pa.imageFiles(fingerName));
dmRow = zeros(1, numel(pa.fingerNames));
fingerIdx = find(strcmp(pa.fingerNames, fingerName), 1);
dmRow(fingerIdx) = 1;

[pa, exitFlag] = present_image_epoch(VP, pa, kb, experimentStartTime, ...
    imagePath, pa.taskType, fingerName, blockIdx, trialInBlock, pa.stimulusDuration, dmRow);

end

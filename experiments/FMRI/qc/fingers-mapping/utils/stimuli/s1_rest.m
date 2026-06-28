function [pa, exitFlag] = s1_rest(VP, pa, kb, experimentStartTime, blockIdx, trialInBlock)
% S1_REST - Present the neutral hand/rest image.

imagePath = fullfile(pa.imageDir, pa.restImageFile);
[pa, exitFlag] = present_image_epoch(VP, pa, kb, experimentStartTime, ...
    imagePath, 'rest', 'Rest', blockIdx, trialInBlock, pa.fixationDuration, zeros(1, numel(pa.fingerNames)));

end

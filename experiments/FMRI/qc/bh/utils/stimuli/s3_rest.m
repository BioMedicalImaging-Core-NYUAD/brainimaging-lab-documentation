function [pa, exitFlag] = s3_rest(VP, pa, kb, experimentStartTime, cycleIdx, durationSec)
% S3_REST - Present normal breathing cue.

dmRow = [0 0 1];
[pa, exitFlag] = present_text_epoch(VP, pa, kb, experimentStartTime, ...
    'rest', pa.instructions.rest, cycleIdx, durationSec, dmRow, pa.colors.rest);

end

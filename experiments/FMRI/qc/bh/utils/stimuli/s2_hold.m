function [pa, exitFlag] = s2_hold(VP, pa, kb, experimentStartTime, cycleIdx)
% S2_HOLD - Present breath-hold cue.

dmRow = [0 1 0];
[pa, exitFlag] = present_text_epoch(VP, pa, kb, experimentStartTime, ...
    'hold', pa.instructions.hold, cycleIdx, pa.holdDuration, dmRow, pa.colors.hold);

end

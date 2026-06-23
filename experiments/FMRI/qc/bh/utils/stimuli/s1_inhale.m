function [pa, exitFlag] = s1_inhale(VP, pa, kb, experimentStartTime, cycleIdx)
% S1_INHALE - Present slow inspiration cue.

dmRow = [1 0 0];
[pa, exitFlag] = present_text_epoch(VP, pa, kb, experimentStartTime, ...
    'inhale', pa.instructions.inhale, cycleIdx, pa.inhaleDuration, dmRow, pa.colors.inhale);

end

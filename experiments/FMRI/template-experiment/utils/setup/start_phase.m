function [pa, phaseEnd, onsetTime] = start_phase(VP, pa, experimentStartTime, duration, phaseName)
% START_PHASE - Show the first frame of a phase at its scheduled time and log it
%
% Phases are scheduled back-to-back from the scanner trigger:
%   planned onset = experimentStartTime + pa.scheduleTime
% so a late frame never pushes the following phases later (no drift).
%
% Call this right after drawing the first frame of the phase, then keep
% redrawing/flipping while GetSecs < phaseEnd - 1.5 * VP.ifi (Flip returns
% at a screen refresh; stopping at 0.5 frames would make every following
% phase exactly one frame late).
%
% Inputs:
%   VP                  - Viewing Parameters structure (window, ifi)
%   pa                  - Parameters structure (scheduleTime, phaseLog, trialCounter)
%   experimentStartTime - GetSecs time of the scanner trigger (time zero)
%   duration            - Planned phase duration in seconds
%   phaseName           - Label stored in pa.phaseLog (e.g. 'stimulus')
%
% Outputs:
%   pa        - Updated: pa.scheduleTime advanced, onset appended to pa.phaseLog
%   phaseEnd  - GetSecs time at which this phase is scheduled to end
%   onsetTime - GetSecs time of the first frame of this phase

plannedOnset = pa.scheduleTime;                 % seconds from trigger
targetOnset = experimentStartTime + plannedOnset;

% WaitSecs + plain Flip instead of a timed Flip: timed presentation is
% unreliable with PsychVulkanCore on the macOS stimulus computer
% (same approach as qc/fingers-mapping/utils/stimuli/present_image_epoch.m)
WaitSecs('UntilTime', targetOnset - 0.5 * VP.ifi);
Screen('Flip', VP.window);
onsetTime = GetSecs;                             % Flip timestamps are unreliable there too

phaseEnd = targetOnset + duration;
pa.scheduleTime = plannedOnset + duration;

k = numel(pa.phaseLog) + 1;
pa.phaseLog(k).trial = pa.trialCounter;
pa.phaseLog(k).phase = phaseName;
pa.phaseLog(k).plannedOnset = plannedOnset;
pa.phaseLog(k).actualOnset = onsetTime - experimentStartTime;
pa.phaseLog(k).onsetDelay = onsetTime - targetOnset;
pa.phaseLog(k).duration = duration;

end

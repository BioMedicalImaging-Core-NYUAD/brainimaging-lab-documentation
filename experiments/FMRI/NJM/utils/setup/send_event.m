function pa = send_event(pa, name, tActual, tPlanned)
% SEND_EVENT - Mark one task event: log it, and send it to the recorders
%
% Inputs:
%   pa       - Parameters structure
%   name     - event name from stimuli_data/physio_trigger_codes.csv (e.g. 'PHASE1_ONSET'); '' = nothing
%   tActual  - GetSecs time of the event
%   tPlanned - planned time in seconds from the trigger (NaN if not scheduled, e.g. a button press)
%
% What it does:
%   - appends the event to pa.log (planned time, actual time, delay)
%   - if pa.sendMarkers: puts the event code on the VPixx digital output for
%     ~10 ms (physiology recorder); present_screen resets it to 0
%   - if eye tracking is on: writes the event name into the EDF file

if isempty(name), return; end
if ~isfield(pa.codes, name)
    error('send_event:unknownEvent', 'Event "%s" is not in physio_trigger_codes.csv', name);
end
code = pa.codes.(name);

if pa.sendMarkers
    try
        Datapixx('SetDoutValues', dout_value(code, pa.doutMapping));
        Datapixx('RegWrRd');
        pa.doutResetAt = GetSecs + 0.010;
    catch ME
        warning('send_event:dout', 'VPixx digital output failed (%s): markers disabled.', ME.message);
        pa.sendMarkers = false;
    end
end

if pa.eyeTrackingEnabled
    try
        Eyelink('Message', '%s', name);
    catch
    end
end

k = numel(pa.log) + 1;
pa.log(k).trial = pa.currentTrial;
pa.log(k).event = name;
pa.log(k).code = code;
pa.log(k).planned = tPlanned / pa.timeScale;                 % real task time
pa.log(k).actual = (tActual - pa.t0) / pa.timeScale;
pa.log(k).delay = (tActual - pa.t0) - tPlanned;              % seconds on the wall clock; NaN if not scheduled

end

%--------------------------------------------------------------------------
function v = dout_value(code, mapping)
% 'direct': the code is written as it is (bit n of the code = DOUT bit n).
% 'spread': bit n of the code goes to DOUT bit 2n+2. In the lab's EEG-fMRI
%           wiring a DOUT value of 4 sets bit 0 of the receiver and 16 sets
%           bit 1 (experiments/EEG-FMRI/general/bit_test.m).
% Check on the hardware which one your physiology recorder needs.
switch mapping
    case 'spread'
        v = 0;
        for n = 0:7
            if bitand(code, 2 ^ n), v = v + 2 ^ (2 * n + 2); end
        end
    otherwise
        v = code;
end
end

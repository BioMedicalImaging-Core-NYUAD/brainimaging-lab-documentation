function [pa, exitFlag] = run_trial(VP, pa, kb, k)
% RUN_TRIAL - One NJM trial: employers -> offers -> decision -> fixation
%
% Inputs:
%   VP, pa, kb - Standard experiment structures
%   k          - trial number within the run
%
% Outputs:
%   pa       - Updated parameters structure (pa.data filled for trial k)
%   exitFlag - true if ESC was pressed
%
% Sequence (planned onsets in pa.sched(k), seconds from the trigger):
%   Phase 1  employer photos + family background          PHASE1_ONSET
%   gap 1    fixation cross                                GAP1_ONSET
%   Phase 2  full offers (salary, off days, workload)      PHASE2_ONSET
%   gap 2    fixation cross                                GAP2_ONSET
%   Phase 3  question + 4 options, ends at the button press PHASE3_ONSET, RESPONSE_Bn / RESPONSE_TIMEOUT
%            selection border for pa.feedbackDuration
%   fixation until the next trial (rest of the decision window + ITI +
%            pre-trial fixation). The next trial starts at its planned
%            time whatever the response time, so every run has the same length.

exitFlag = false;
s = pa.sched(k);
pa.currentTrial = k;
if pa.screenTrial ~= k
    pa = prepare_trial_screens(VP, pa, k);            % normally done during the previous fixation
end
el_trial_start(pa, k);

% Phase 1: employers
[pa, o] = present_screen(VP, pa, kb, pa.screenTex(1), s.phase1, s.gap1, struct('event', 'PHASE1_ONSET'));
pa.data.onset_phase1(k) = rel(pa, o.onset);
if o.esc, exitFlag = true; return; end

[pa, o] = present_screen(VP, pa, kb, [], s.gap1, s.phase2, struct('event', 'GAP1_ONSET'));
pa.data.onset_gap1(k) = rel(pa, o.onset);
if o.esc, exitFlag = true; return; end

% Phase 2: full offers
[pa, o] = present_screen(VP, pa, kb, pa.screenTex(2), s.phase2, s.gap2, struct('event', 'PHASE2_ONSET'));
pa.data.onset_phase2(k) = rel(pa, o.onset);
if o.esc, exitFlag = true; return; end

[pa, o] = present_screen(VP, pa, kb, [], s.gap2, s.phase3, struct('event', 'GAP2_ONSET'));
pa.data.onset_gap2(k) = rel(pa, o.onset);
if o.esc, exitFlag = true; return; end

% Phase 3: decision
[pa, o] = present_screen(VP, pa, kb, pa.screenTex(3), s.phase3, s.iti, ...
    struct('event', 'PHASE3_ONSET', 'collect', true, 'auto', pa.auto(k)));
pa.data.onset_phase3(k) = rel(pa, o.onset);
if o.esc, exitFlag = true; return; end

if o.responded
    b = o.button;
    pa = send_event(pa, sprintf('RESPONSE_B%d', b), o.pressTime, NaN);
    pa.data.response_button(k) = b;
    pa.data.reaction_time(k) = (o.pressTime - o.onset) / pa.timeScale;
    pa.data.choice{k} = pa.resp.choice{b};
    pa.data.confidence{k} = pa.resp.confidence{b};
    pa.data.response_label{k} = pa.resp.labels{b};
    if pa.trials(k).isCatch
        pa.data.catch_pass(k) = double(strcmp(pa.resp.choice{b}, pa.trials(k).dominantSide));
    end
    % selection feedback: border around the chosen option (also shows that the press was registered)
    tFeedbackEnd = (GetSecs - pa.t0) + pa.feedbackDuration;
    [pa, f] = present_screen(VP, pa, kb, pa.screenTex(3), NaN, tFeedbackEnd, struct('highlight', b));
    if f.esc, exitFlag = true; return; end
else
    pa = send_event(pa, 'RESPONSE_TIMEOUT', GetSecs, s.iti);
    pa.data.timeout(k) = true;
    if pa.trials(k).isCatch, pa.data.catch_pass(k) = 0; end
end
el_trial_end(pa, k);

% Fixation until the next trial (or the end of the run); pre-render the next trial meanwhile
if k < pa.nTrials
    tNext = pa.sched(k + 1).phase1; fixOpts = struct('event', 'ITI_ONSET', 'prepTrial', k + 1);
else
    tNext = pa.runEnd; fixOpts = struct('event', 'ITI_ONSET');
end
[pa, o] = present_screen(VP, pa, kb, [], NaN, tNext, fixOpts);
pa.data.onset_fixation_after(k) = rel(pa, o.onset);
pa.data.completed(k) = true;
pa.trialCounter = k;
if o.esc, exitFlag = true; end

end

%--------------------------------------------------------------------------
function t = rel(pa, tAbs)
% GetSecs time -> seconds from the trigger, in real task time
t = (tAbs - pa.t0) / pa.timeScale;
end

%--------------------------------------------------------------------------
function el_trial_start(pa, k)
% Eye tracker: trial id, trial variables and areas of interest for Data Viewer
if ~pa.eyeTrackingEnabled, return; end
try
    tr = pa.trials(k); d = pa.design(k, :);
    Eyelink('Message', 'TRIALID %d', tr.trialGlobal);
    Eyelink('Command', 'record_status_message "NJM run %d trial %d/%d"', pa.bidsInfo.runNumber, k, pa.nTrials);
    vars = {'trial_kind', tr.kind; 'A_origin', d.A_origin{1}; 'B_origin', d.B_origin{1}; ...
        'A_face', d.A_face{1}; 'B_face', d.B_face{1}; ...
        'A_salary', num2str(d.A_salary_aed); 'B_salary', num2str(d.B_salary_aed); ...
        'A_rest_days', num2str(d.A_rest_days); 'B_rest_days', num2str(d.B_rest_days); ...
        'A_workload', num2str(d.A_workload); 'B_workload', num2str(d.B_workload)};
    for i = 1:size(vars, 1)
        Eyelink('Message', '!V TRIAL_VAR %s %s', vars{i, 1}, vars{i, 2});
    end
    % Interest areas (pixels): photos and attribute rows of both offers, and the four options
    L = pa.L; id = 0; letters = 'AB';
    for sd = 1:2
        id = id + 1;
        Eyelink('Message', '!V IAREA RECTANGLE %d %d %d %d %d %s_photo', id, L.photo(sd, 1), L.photo(sd, 2), L.photo(sd, 3), L.photo(sd, 4), letters(sd));
        for a = 1:numel(L.attributes)
            r = L.row.(L.attributes{a})(sd, :); id = id + 1;
            Eyelink('Message', '!V IAREA RECTANGLE %d %d %d %d %d %s_%s', id, r(1), r(2), r(3), r(4), letters(sd), L.attributes{a});
        end
    end
    for b = 1:size(L.option, 1)
        r = L.option(b, :); id = id + 1;
        Eyelink('Message', '!V IAREA RECTANGLE %d %d %d %d %d option_%d', id, r(1), r(2), r(3), r(4), b);
    end
catch
end
end

%--------------------------------------------------------------------------
function el_trial_end(pa, k)
if ~pa.eyeTrackingEnabled, return; end
try
    b = pa.data.response_button(k);
    if isnan(b), b = 0; end
    Eyelink('Message', '!V TRIAL_VAR response_button %d', b);
    Eyelink('Message', '!V TRIAL_VAR reaction_time %.3f', pa.data.reaction_time(k));
    Eyelink('Message', 'TRIAL_RESULT %d', b);
catch
end
end

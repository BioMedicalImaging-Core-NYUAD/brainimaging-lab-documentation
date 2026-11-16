function create_bids_events(pa, info)
% CREATE_BIDS_EVENTS - Write the BIDS events.tsv and events.json of one run
%
% One row per phase of every trial that was shown, plus one row per button press:
%   phase1_employer   employer photos + family background   (duration = planned 4.0 s)
%   phase2_offer      full offers                           (duration = planned 5.0 s)
%   phase3_decision   decision screen                       (duration = response time, or the full window if no response)
%   response          button press                          (duration 0)
% Onsets are the measured onsets in seconds from the first scanner trigger.
% Every row carries the trial's attributes and the response, so each row can
% be modelled on its own (e.g. phase 1 by employer origin, phase 2 by job terms).

if isempty(info) || ~isfield(info, 'fullPathTSV'), return; end
d = pa.design; D = pa.data; T = pa.P.timing;
cols = {'onset', 'duration', 'trial_type', 'trial', 'trial_global', 'trial_id', 'trial_kind', 'is_catch', 'dominant_side', 'swapped', ...
    'A_origin', 'B_origin', 'A_face', 'B_face', 'A_salary_aed', 'B_salary_aed', 'A_rest_days', 'B_rest_days', 'A_workload', 'B_workload', ...
    'response_button', 'response_label', 'choice', 'confidence', 'response_time', 'timeout', 'catch_pass', ...
    'chosen_origin', 'chosen_salary_aed', 'chosen_rest_days', 'chosen_workload'};
rows = {};

for k = 1:pa.nTrials
    if isnan(D.onset_phase1(k)), continue; end              % trial never started
    answered = ~isnan(D.response_button(k));
    common = {num2str(d.trial_in_run(k)), num2str(d.trial_global(k)), num2str(d.trial_id(k)), d.trial_kind{k}, num2str(d.is_catch(k)), ...
        na_if(d.dominant_side{k}, 'none'), num2str(d.swapped(k)), d.A_origin{k}, d.B_origin{k}, d.A_face{k}, d.B_face{k}, ...
        num2str(d.A_salary_aed(k)), num2str(d.B_salary_aed(k)), num2str(d.A_rest_days(k)), num2str(d.B_rest_days(k)), ...
        num2str(d.A_workload(k)), num2str(d.B_workload(k))};
    if answered
        p = D.choice{k};                                      % 'A' or 'B'
        resp = {num2str(D.response_button(k)), D.response_label{k}, p, D.confidence{k}, sprintf('%.4f', D.reaction_time(k)), '0', ...
            num_or_na(D.catch_pass(k)), d.([p '_origin']){k}, num2str(d.([p '_salary_aed'])(k)), num2str(d.([p '_rest_days'])(k)), num2str(d.([p '_workload'])(k))};
    else
        resp = {'n/a', 'n/a', 'n/a', 'n/a', 'n/a', num2str(double(D.timeout(k))), num_or_na(D.catch_pass(k)), 'n/a', 'n/a', 'n/a', 'n/a'};
    end

    rows(end + 1, :) = [{sprintf('%.4f', D.onset_phase1(k)), sprintf('%.4f', T.phase1_employer_s), 'phase1_employer'}, common, resp]; %#ok<AGROW>
    if ~isnan(D.onset_phase2(k))
        rows(end + 1, :) = [{sprintf('%.4f', D.onset_phase2(k)), sprintf('%.4f', T.phase2_offer_s), 'phase2_offer'}, common, resp]; %#ok<AGROW>
    end
    if ~isnan(D.onset_phase3(k))
        if answered, dur = D.reaction_time(k); else, dur = T.phase3_decision_max_s; end
        rows(end + 1, :) = [{sprintf('%.4f', D.onset_phase3(k)), sprintf('%.4f', dur), 'phase3_decision'}, common, resp]; %#ok<AGROW>
        if answered
            rows(end + 1, :) = [{sprintf('%.4f', D.onset_phase3(k) + D.reaction_time(k)), '0', 'response'}, common, resp]; %#ok<AGROW>
        end
    end
end

if isempty(rows)
    fprintf('No trial was shown: no events file written.\n');
    return;
end

fid = fopen(info.fullPathTSV, 'w');
if fid == -1, error('create_bids_events:file', 'Cannot write %s', info.fullPathTSV); end
fprintf(fid, '%s\n', strjoin(cols, sprintf('\t')));
for r = 1:size(rows, 1)
    fprintf(fid, '%s\n', strjoin(rows(r, :), sprintf('\t')));
end
fclose(fid);

J = struct();
J.onset = struct('Description', 'Measured onset of the event, from the first scanner trigger', 'Units', 's');
J.duration = struct('Description', 'phase1/phase2: planned display time; phase3: response time (full window if no response); response: 0', 'Units', 's');
J.trial_type = struct('Description', 'Event type', 'Levels', struct( ...
    'phase1_employer', 'Employer photos and family background of both offers', ...
    'phase2_offer', 'Full offers: background, salary, off days, workload', ...
    'phase3_decision', 'Decision screen with the four answer options', ...
    'response', 'Button press'));
J.trial = struct('Description', 'Trial number within the run');
J.trial_global = struct('Description', 'Trial number within the session (1-48)');
J.trial_id = struct('Description', 'Row of stimuli_data/design/njm_fmri_trials.csv (the same pair of offers for every participant)');
J.trial_kind = struct('Description', 'Kind of choice', 'Levels', struct( ...
    'tradeoff', 'Offers differ in job terms; neither is better on everything', ...
    'identical_terms', 'Same job terms, different employer origin', ...
    'catch', 'Same employer origin, one offer better on salary, off days and workload'));
J.is_catch = struct('Description', '1 = catch trial (attention check)');
J.dominant_side = struct('Description', 'Catch trials: side of the better offer (A = left, B = right)');
J.swapped = struct('Description', '1 = the two offers of this trial_id are shown in swapped left/right position for this participant');
J.A_origin = struct('Description', 'Employer origin of Offer A (left); B_origin for Offer B (right)', 'Levels', struct( ...
    'SEA_SA', 'Southeast / South Asian family', 'ARAB', 'Arab / Emirati family', 'AFRICAN', 'Black / African family', 'WESTERN', 'White / Western family'));
J.A_face = struct('Description', 'Photo file shown for the employer (stimuli_data/faces)');
J.A_salary_aed = struct('Description', 'Monthly salary', 'Units', 'AED');
J.A_rest_days = struct('Description', 'Rest days per week (0, 0.5 = one day every two weeks, 1)');
J.A_workload = struct('Description', 'Household workload: 1 = light, 2 = moderate, 3 = heavy');
J.response_button = struct('Description', 'Button pressed: 1 index, 2 middle, 3 ring, 4 little finger of the right hand');
J.response_label = struct('Description', 'Meaning of the button');
J.choice = struct('Description', 'Chosen offer (A or B)');
J.confidence = struct('Description', 'definitely (buttons 1, 4) or probably (buttons 2, 3)');
J.response_time = struct('Description', 'Time from the onset of the decision screen to the button press', 'Units', 's');
J.timeout = struct('Description', '1 = no response within the decision window');
J.catch_pass = struct('Description', 'Catch trials: 1 = chose the better offer, 0 = did not (or no response)');
J.chosen_origin = struct('Description', 'Attributes of the chosen offer (chosen_origin, chosen_salary_aed, chosen_rest_days, chosen_workload)');
J.TaskName = pa.bidsInfo.taskName;
J.StimulusPresentation = struct('SoftwareName', 'Psychtoolbox', 'Code', 'brainimaging-lab-documentation/experiments/FMRI/NJM');
if pa.timeScale ~= 1 || pa.autoRespond
    J.TestRun = struct('Description', 'NOT REAL DATA: produced by the task in test mode', ...
        'TimeScale', pa.timeScale, 'SimulatedParticipant', pa.autoRespond);
end

fid = fopen(info.fullPathJSON, 'w');
if fid ~= -1
    try
        txt = jsonencode(J, 'PrettyPrint', true);
    catch
        txt = jsonencode(J);
    end
    fprintf(fid, '%s', txt);
    fclose(fid);
end
fprintf('Saved: %s\n', info.fullPathTSV);

end

%--------------------------------------------------------------------------
function s = num_or_na(x)
if isnan(x), s = 'n/a'; else, s = num2str(x); end
end

%--------------------------------------------------------------------------
function s = na_if(str, value)
if strcmp(str, value), s = 'n/a'; else, s = str; end
end

function design = make_subject_design(cfg, subjectID, sessionID)
% MAKE_SUBJECT_DESIGN - Randomise the NJM trial set for one participant
%
% Protocol safeguards implemented here (per participant, seeded by subject ID):
%   - trials are split into runs: each run gets 1 catch + 1 identical-terms
%     trial and the same number of trade-off trials, with employer origins
%     and job-term levels spread as evenly as possible over runs
%   - trial order is shuffled within each run (catch trial never first or
%     last; the same pair of origins never twice in a row)
%   - left/right position: half of the trials in every run are swapped
%     (spatial counterbalancing); the dominant option of the catch trials is
%     on the left in half of the runs and on the right in the other half
%   - faces: every face of an origin is used equally often, in an order that
%     differs between participants; the two faces of a trial always differ
%   - jitter: each run uses the jitter values in the JSON in a random order
%
% Inputs:
%   cfg       - from njm_load_config (cfg.mode 'task' or 'practice')
%   subjectID - e.g. '0201'
%   sessionID - e.g. '01'
%
% Output:
%   design - table, one row per trial in presentation order, with the
%            planned onsets (seconds from the first scanner trigger)

P = cfg.P; T = P.timing; S = P.session;
base = cfg.trials;
n = height(base);
isPractice = strcmp(cfg.mode, 'practice');
if isPractice, nRuns = 1; else, nRuns = S.n_runs; end
perRun = n / nRuns;
if perRun ~= round(perRun)
    error('make_subject_design:trialCount', '%d trials cannot be split evenly into %d runs', n, nRuns);
end

seed = njm_seed(subjectID, sessionID, cfg.mode);
rs = RandStream('mt19937ar', 'Seed', seed);   % private stream: leaves the global rng untouched

origins = P.attributes.employer_origin.levels(:)';
isCatch = strcmp(base.trial_kind, 'catch');
isIdent = strcmp(base.trial_kind, 'identical_terms');

%% 1) split into runs
runOf = ones(n, 1);
if nRuns > 1
    groups = {find(isCatch), find(isIdent), find(~isCatch & ~isIdent)};
    for g = 1:numel(groups)
        if mod(numel(groups{g}), nRuns) ~= 0
            error('make_subject_design:trialCount', 'Trial kinds cannot be split evenly over %d runs', nRuns);
        end
    end
    bestScore = inf;
    for attempt = 1:300
        cand = zeros(n, 1);
        for g = 1:numel(groups)
            idx = groups{g};
            labels = repmat((1:nRuns)', numel(idx) / nRuns, 1);
            cand(idx(randperm(rs, numel(idx)))) = labels;
        end
        score = run_balance_score(base, cand, nRuns, origins, P);
        if score < bestScore
            bestScore = score; runOf = cand;
        end
    end
end

%% 2) left/right position (swap P1/P2 on half of the trials of each run)
appear = zeros(1, numel(origins));
for o = 1:numel(origins)
    appear(o) = sum(strcmp(base.P1_origin, origins{o})) + sum(strcmp(base.P2_origin, origins{o}));
end
catchIdx = find(isCatch);
bestScore = inf; swapped = false(n, 1);
for attempt = 1:200
    cand = false(n, 1);
    % dominant option of the catch trials: left (A) for half of them, right (B) for the rest
    wantA = false(numel(catchIdx), 1);
    wantA(1:floor(numel(catchIdx) / 2)) = true;
    if mod(numel(catchIdx), 2) == 1 && rand(rs) < 0.5, wantA(end) = true; end
    wantA = wantA(randperm(rs, numel(wantA)));
    for c = 1:numel(catchIdx)
        domIsP1 = strcmp(base.dominant_profile{catchIdx(c)}, 'P1');
        cand(catchIdx(c)) = (domIsP1 ~= wantA(c));          % swapped when P1 must go to the right
    end
    for r = 1:nRuns
        rows = find(runOf == r);
        others = rows(~isCatch(rows));
        nSwap = floor(numel(rows) / 2) - sum(cand(rows(isCatch(rows))));
        nSwap = max(0, min(nSwap, numel(others)));
        pick = others(randperm(rs, numel(others), nSwap));
        cand(pick) = true;
    end
    leftOrigin = base.P1_origin; leftOrigin(cand) = base.P2_origin(cand);
    score = 0;
    for o = 1:numel(origins)
        score = score + (sum(strcmp(leftOrigin, origins{o})) - appear(o) / 2) ^ 2;
    end
    if score < bestScore
        bestScore = score; swapped = cand;
    end
end

%% 3) order within each run
order = zeros(n, 1); pos = 0;
excluded = P.catch_trials.excluded_positions(:)';
if isPractice, excluded = 1; end
for r = 1:nRuns
    rows = find(runOf == r);
    bestViol = inf; bestOrd = rows;
    for attempt = 1:1000
        ord = rows(randperm(rs, numel(rows)));
        viol = sum(ismember(find(isCatch(ord)), excluded));
        for k = 1:numel(ord) - 1
            a = sort({base.P1_origin{ord(k)}, base.P2_origin{ord(k)}});
            b = sort({base.P1_origin{ord(k + 1)}, base.P2_origin{ord(k + 1)}});
            viol = viol + isequal(a, b);
        end
        if viol < bestViol
            bestViol = viol; bestOrd = ord;
        end
        if viol == 0, break; end
    end
    order(pos + (1:numel(rows))) = bestOrd;
    pos = pos + numel(rows);
end

%% 4) faces
faces = cfg.faces;
useSet = 'fmri';
if isPractice && any(strcmp(faces.set, 'practice')), useSet = 'practice'; end
pool = cell(1, numel(origins)); queue = cell(1, numel(origins));
for o = 1:numel(origins)
    pool{o} = faces.file(strcmp(faces.employer_origin, origins{o}) & strcmp(faces.set, useSet));
    pool{o} = pool{o}(:)';
    if numel(pool{o}) < P.faces.min_per_origin_for_task
        error('make_subject_design:faces', ['Origin %s has %d face(s) in set ''%s'' (need at least %d).\n' ...
            'Add images to stimuli_data/faces_raw/%s/ and run prepare_faces.py'], ...
            origins{o}, numel(pool{o}), useSet, P.faces.min_per_origin_for_task, origins{o});
    end
    queue{o} = {};
end

%% 5) assemble rows in presentation order
jit = struct('pre', [], 'gap1', [], 'gap2', [], 'iti', []);
C = struct();
names = {'run', 'trial_in_run', 'trial_global', 'trial_id', 'is_catch', 'swapped', ...
    'A_salary_aed', 'A_rest_days', 'A_workload', 'B_salary_aed', 'B_rest_days', 'B_workload', ...
    'pretrial_fixation', 'gap1', 'gap2', 'iti', 'onset_fixation', 'onset_phase1', 'onset_gap1', ...
    'onset_phase2', 'onset_gap2', 'onset_phase3', 'onset_iti', 'trial_end', 'run_duration'};
for i = 1:numel(names), C.(names{i}) = zeros(n, 1); end
txt = {'trial_kind', 'dominant_side', 'A_origin', 'A_face', 'B_origin', 'B_face'};
for i = 1:numel(txt), C.(txt{i}) = cell(n, 1); end

t = 0;
for k = 1:n
    b = order(k);
    r = runOf(b);
    kInRun = k - (r - 1) * perRun;
    if kInRun == 1                                   % new run: new jitter order, clock restarts
        jit.pre  = draw_jitter(rs, T.pretrial_fixation_values_s, T.pretrial_fixation_counts, perRun);
        jit.gap1 = draw_jitter(rs, T.gap1_values_s, T.gap1_counts, perRun);
        jit.gap2 = draw_jitter(rs, T.gap2_values_s, T.gap2_counts, perRun);
        jit.iti  = draw_jitter(rs, T.iti_values_s, T.iti_counts, perRun);
        t = S.lead_in_fixation_s;
    end

    if swapped(b), first = 'P2'; second = 'P1'; else, first = 'P1'; second = 'P2'; end
    C.run(k) = r; C.trial_in_run(k) = kInRun; C.trial_global(k) = k; C.trial_id(k) = base.trial_id(b);
    C.trial_kind{k} = base.trial_kind{b}; C.is_catch(k) = base.is_catch(b); C.swapped(k) = swapped(b);
    C.A_origin{k} = base.([first '_origin']){b};        C.B_origin{k} = base.([second '_origin']){b};
    C.A_salary_aed(k) = base.([first '_salary_aed'])(b); C.B_salary_aed(k) = base.([second '_salary_aed'])(b);
    C.A_rest_days(k) = base.([first '_rest_days'])(b);   C.B_rest_days(k) = base.([second '_rest_days'])(b);
    C.A_workload(k) = base.([first '_workload'])(b);     C.B_workload(k) = base.([second '_workload'])(b);
    if base.is_catch(b)
        if strcmp(base.dominant_profile{b}, first), C.dominant_side{k} = 'A'; else, C.dominant_side{k} = 'B'; end
    else
        C.dominant_side{k} = 'none';
    end

    oA = find(strcmp(origins, C.A_origin{k})); oB = find(strcmp(origins, C.B_origin{k}));
    [C.A_face{k}, queue{oA}] = next_face(rs, queue{oA}, pool{oA}, '');
    [C.B_face{k}, queue{oB}] = next_face(rs, queue{oB}, pool{oB}, C.A_face{k});

    C.pretrial_fixation(k) = jit.pre(kInRun); C.gap1(k) = jit.gap1(kInRun);
    C.gap2(k) = jit.gap2(kInRun); C.iti(k) = jit.iti(kInRun);
    C.onset_fixation(k) = t;
    C.onset_phase1(k) = t + C.pretrial_fixation(k);
    C.onset_gap1(k) = C.onset_phase1(k) + T.phase1_employer_s;
    C.onset_phase2(k) = C.onset_gap1(k) + C.gap1(k);
    C.onset_gap2(k) = C.onset_phase2(k) + T.phase2_offer_s;
    C.onset_phase3(k) = C.onset_gap2(k) + C.gap2(k);
    C.onset_iti(k) = C.onset_phase3(k) + T.phase3_decision_max_s;
    C.trial_end(k) = C.onset_iti(k) + C.iti(k);
    t = C.trial_end(k);
    if kInRun == perRun
        C.run_duration(C.run == r) = t + S.lead_out_fixation_s;
    end
end

design = table(C.run, C.trial_in_run, C.trial_global, C.trial_id, C.trial_kind, C.is_catch, C.dominant_side, C.swapped, ...
    C.A_origin, C.A_face, C.A_salary_aed, C.A_rest_days, C.A_workload, ...
    C.B_origin, C.B_face, C.B_salary_aed, C.B_rest_days, C.B_workload, ...
    C.pretrial_fixation, C.gap1, C.gap2, C.iti, C.onset_fixation, C.onset_phase1, C.onset_gap1, ...
    C.onset_phase2, C.onset_gap2, C.onset_phase3, C.onset_iti, C.trial_end, C.run_duration, ...
    'VariableNames', {'run', 'trial_in_run', 'trial_global', 'trial_id', 'trial_kind', 'is_catch', 'dominant_side', 'swapped', ...
    'A_origin', 'A_face', 'A_salary_aed', 'A_rest_days', 'A_workload', ...
    'B_origin', 'B_face', 'B_salary_aed', 'B_rest_days', 'B_workload', ...
    'pretrial_fixation', 'gap1', 'gap2', 'iti', 'onset_fixation', 'onset_phase1', 'onset_gap1', ...
    'onset_phase2', 'onset_gap2', 'onset_phase3', 'onset_iti', 'trial_end', 'run_duration'});
design.seed = repmat(seed, n, 1);

end

%--------------------------------------------------------------------------
function score = run_balance_score(base, runOf, nRuns, origins, P)
% Lower is better: origins and term levels evenly spread over runs
score = 0;
sal = P.attributes.salary_aed.levels; rest = P.attributes.rest_days_per_week.levels; work = P.attributes.workload.levels;
for r = 1:nRuns
    rows = runOf == r; nSlots = 2 * sum(rows);
    for o = 1:numel(origins)
        c = sum(strcmp(base.P1_origin(rows), origins{o})) + sum(strcmp(base.P2_origin(rows), origins{o}));
        score = score + (c - nSlots / numel(origins)) ^ 2;
    end
    for l = 1:numel(sal)
        c = sum(base.P1_salary_aed(rows) == sal(l)) + sum(base.P2_salary_aed(rows) == sal(l));
        score = score + 0.5 * (c - nSlots / numel(sal)) ^ 2;
    end
    for l = 1:numel(rest)
        c = sum(abs(base.P1_rest_days(rows) - rest(l)) < 1e-6) + sum(abs(base.P2_rest_days(rows) - rest(l)) < 1e-6);
        score = score + 0.5 * (c - nSlots / numel(rest)) ^ 2;
    end
    for l = 1:numel(work)
        c = sum(base.P1_workload(rows) == work(l)) + sum(base.P2_workload(rows) == work(l));
        score = score + 0.5 * (c - nSlots / numel(work)) ^ 2;
    end
end
end

%--------------------------------------------------------------------------
function v = draw_jitter(rs, values, counts, nTrials)
% Each value 'count' times, in random order; cut or repeated to nTrials
full = repelem(values(:), counts(:));
v = zeros(nTrials, 1); filled = 0;
while filled < nTrials
    p = full(randperm(rs, numel(full)));
    take = min(numel(p), nTrials - filled);
    v(filled + (1:take)) = p(1:take);
    filled = filled + take;
end
end

%--------------------------------------------------------------------------
function [face, queue] = next_face(rs, queue, pool, avoid)
% Next face of this origin: cycle through the pool in random order, never
% returning 'avoid' (the other face of the same trial)
if isempty(queue), queue = pool(randperm(rs, numel(pool))); end
if ~isempty(avoid) && strcmp(queue{1}, avoid)
    j = find(~strcmp(queue, avoid), 1);
    if isempty(j)
        extra = pool(randperm(rs, numel(pool)));
        queue = [queue, extra];
        j = find(~strcmp(queue, avoid), 1);
    end
    tmp = queue{1}; queue{1} = queue{j}; queue{j} = tmp;
end
face = queue{1};
queue(1) = [];
end

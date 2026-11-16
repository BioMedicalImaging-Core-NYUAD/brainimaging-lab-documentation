function ok = njm_check_design(nSubjects)
% NJM_CHECK_DESIGN - Check the per-participant randomisation (no screen, no hardware)
%
% Builds the design of many made-up participants and checks every rule:
% 48 trials / 96 different job profiles, 4 runs of 12 with 1 catch and 1
% identical-terms trial each, catch trial never first or last, half of the
% trials swapped in every run, dominant catch option 2 x left / 2 x right,
% two different faces on every trial, planned run length the same for every
% run. Prints how well origins are balanced between left and right.
%
%   njm_check_design          100 participants
%   njm_check_design(500)

if nargin < 1, nSubjects = 100; end
scriptDir = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(scriptDir, 'utils')));
cfg = njm_load_config(scriptDir, 'task');
P = cfg.P; origins = P.attributes.employer_origin.levels(:)';
nRuns = P.session.n_runs; perRun = P.session.trials_per_run;

problems = {};
leftCount = zeros(nSubjects, numel(origins)); swapShare = zeros(nSubjects, 48); firstTrial = zeros(nSubjects, 1);
runLen = zeros(nSubjects, 1); faceMax = zeros(nSubjects, 1); faceMin = zeros(nSubjects, 1);
for s = 1:nSubjects
    id = sprintf('%04d', s);
    d = make_subject_design(cfg, id, '01');
    d2 = make_subject_design(cfg, id, '01');
    if ~isequal(d, d2), problems{end + 1} = sprintf('%s: design is not reproducible', id); end %#ok<AGROW>

    if height(d) ~= 48, problems{end + 1} = sprintf('%s: %d trials', id, height(d)); end %#ok<AGROW>
    prof = [strcat(d.A_origin, '|', string(d.A_salary_aed), '|', string(d.A_rest_days), '|', string(d.A_workload)); ...
            strcat(d.B_origin, '|', string(d.B_salary_aed), '|', string(d.B_rest_days), '|', string(d.B_workload))];
    if numel(unique(prof)) ~= 96, problems{end + 1} = sprintf('%s: %d distinct profiles', id, numel(unique(prof))); end %#ok<AGROW>
    if ~isequal(sort(d.trial_id), (1:48)'), problems{end + 1} = sprintf('%s: trial ids', id); end %#ok<AGROW>

    for r = 1:nRuns
        x = d(d.run == r, :);
        if height(x) ~= perRun || sum(x.is_catch) ~= 1 || sum(strcmp(x.trial_kind, 'identical_terms')) ~= 1
            problems{end + 1} = sprintf('%s run %d: composition', id, r); %#ok<AGROW>
        end
        if ismember(find(x.is_catch), P.catch_trials.excluded_positions)
            problems{end + 1} = sprintf('%s run %d: catch trial first or last', id, r); %#ok<AGROW>
        end
        if sum(x.swapped) ~= perRun / 2
            problems{end + 1} = sprintf('%s run %d: %d trials swapped', id, r, sum(x.swapped)); %#ok<AGROW>
        end
        if abs(x.run_duration(1) - d.run_duration(1)) > 1e-9 || abs(x.trial_end(end) + P.session.lead_out_fixation_s - x.run_duration(1)) > 1e-9
            problems{end + 1} = sprintf('%s run %d: run length', id, r); %#ok<AGROW>
        end
        if ~isequal(x.trial_in_run, (1:perRun)'), problems{end + 1} = sprintf('%s run %d: order', id, r); end %#ok<AGROW>
    end
    c = d(d.is_catch == 1, :);
    if sum(strcmp(c.dominant_side, 'A')) ~= 2 || sum(strcmp(c.dominant_side, 'B')) ~= 2
        problems{end + 1} = sprintf('%s: catch sides', id); %#ok<AGROW>
    end
    for k = 1:height(c)                                   % the dominant side really is the better offer
        if strcmp(c.dominant_side{k}, 'A'), good = 'A'; bad = 'B'; else, good = 'B'; bad = 'A'; end
        if ~(c.([good '_salary_aed'])(k) > c.([bad '_salary_aed'])(k) && c.([good '_rest_days'])(k) > c.([bad '_rest_days'])(k) && ...
                c.([good '_workload'])(k) < c.([bad '_workload'])(k) && strcmp(c.A_origin{k}, c.B_origin{k}))
            problems{end + 1} = sprintf('%s: catch trial %d is not dominant', id, c.trial_id(k)); %#ok<AGROW>
        end
    end
    if any(strcmp(d.A_face, d.B_face)), problems{end + 1} = sprintf('%s: same face twice in a trial', id); end %#ok<AGROW>
    for o = 1:numel(origins)
        if any(~contains(d.A_face(strcmp(d.A_origin, origins{o})), lower(origins{o}))) || any(~contains(d.B_face(strcmp(d.B_origin, origins{o})), lower(origins{o})))
            problems{end + 1} = sprintf('%s: face of the wrong origin', id); %#ok<AGROW>
        end
        leftCount(s, o) = sum(strcmp(d.A_origin, origins{o}));
    end
    [~, byId] = sort(d.trial_id); swapShare(s, :) = d.swapped(byId)'; firstTrial(s) = d.trial_id(1);
    runLen(s) = d.run_duration(1);
    [~, ~, j] = unique([d.A_face; d.B_face]); n = accumarray(j, 1); faceMax(s) = max(n); faceMin(s) = min(n);
    onsets = [d.onset_phase1, d.onset_gap1, d.onset_phase2, d.onset_gap2, d.onset_phase3, d.onset_iti, d.trial_end];
    if any(any(diff(onsets, 1, 2) <= 0)), problems{end + 1} = sprintf('%s: onsets not increasing', id); end %#ok<AGROW>
end

fprintf('\nNJM design check: %d participants\n', nSubjects);
fprintf('Run length: %.1f s for every run and participant: %d\n', runLen(1), all(abs(runLen - runLen(1)) < 1e-9));
fprintf('Each origin on the left (of 24 appearances): min %d, max %d\n', min(leftCount(:)), max(leftCount(:)));
fprintf('Share of participants with a given trial swapped: %.2f to %.2f (target 0.50)\n', min(mean(swapShare)), max(mean(swapShare)));
fprintf('Different first trials across participants: %d\n', numel(unique(firstTrial)));
fprintf('Times each face is shown per participant: %d to %d\n', min(faceMin), max(faceMax));
if isempty(problems)
    fprintf('All checks passed.\n');
else
    fprintf('%d PROBLEM(S):\n', numel(problems)); fprintf('  %s\n', problems{1:min(20, end)});
end
ok = isempty(problems);

end

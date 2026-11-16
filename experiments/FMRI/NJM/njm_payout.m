function result = njm_payout(subjectID, sessionID, opts)
% NJM_PAYOUT - Lottery and payment at the end of the scanning visit
%
% Protocol (payout / dual lottery): one of the participant's scanned choices
% is picked at random. If the answer on that trial was "Definitely Accept"
% (A or B), a second "market" draw decides whether the job is available. If
% it is, the participant gets the salary of the chosen offer divided by 64,
% rounded down (AED 1,800 -> 28, AED 2,500 -> 39, AED 3,200 -> 50). A
% "Probably" answer, no answer or an unsuccessful market draw pays no bonus.
% The online (behavioural) lottery that was locked on the first visit is
% drawn the same way, independently, if its choices are given.
%
%   njm_payout('0201', '01')
%   njm_payout('0201', '01', struct('onlineChoices', 'C:\...\0201_online.csv'))
%       the CSV needs the columns confidence (definitely/probably) and chosen_salary_aed,
%       one row per online trial
%
% The lottery is drawn ONCE: the result is saved as
% sub-.._ses-.._task-njm_payout.json and shown again if the function is
% called a second time (opts.redraw = true draws again and keeps the old file).
%
% Output: result struct (also printed as a receipt)

if nargin < 2 || isempty(sessionID), sessionID = '01'; end
if nargin < 3, opts = struct(); end
scriptDir = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(scriptDir, 'utils')));
subjectID = regexprep(char(subjectID), '^sub-', ''); sessionID = regexprep(char(sessionID), '^ses-', '');
dataDir = fullfile(scriptDir, 'data', 'exp', sprintf('sub-%s', subjectID), sprintf('ses-%s', sessionID));
outFile = fullfile(dataDir, sprintf('sub-%s_ses-%s_task-njm_payout.json', subjectID, sessionID));

if exist(outFile, 'file') && ~(isfield(opts, 'redraw') && opts.redraw)
    result = jsondecode(fileread(outFile));
    fprintf('The lottery for sub-%s was already drawn on %s. Showing the saved result.\n', subjectID, result.drawn_at);
    print_receipt(result);
    return;
end

cfg = njm_load_config(scriptDir, 'task');
PO = cfg.P.payout;

% scanned choices
files = dir(fullfile(dataDir, sprintf('sub-%s_ses-%s_task-njm_run-*.mat', subjectID, sessionID)));
files = files(cellfun(@isempty, strfind({files.name}, '_old-'))); %#ok<STRCLFH>
if isempty(files), error('njm_payout:noData', 'No saved runs in %s', dataDir); end
trials = struct('run', {}, 'trial', {}, 'confidence', {}, 'choice', {}, 'salary', {});
runs = [];
for i = 1:numel(files)
    S = load(fullfile(files(i).folder, files(i).name), 'pa'); pa = S.pa;
    runs(end + 1) = pa.bidsInfo.runNumber; %#ok<AGROW>
    for k = find(pa.data.completed)'
        t = struct('run', pa.bidsInfo.runNumber, 'trial', k, 'confidence', pa.data.confidence{k}, 'choice', pa.data.choice{k}, 'salary', NaN);
        if ismember(t.choice, {'A', 'B'}), t.salary = pa.design.([t.choice '_salary_aed'])(k); end
        trials(end + 1) = t; %#ok<AGROW>
    end
end
if numel(unique(runs)) < cfg.P.session.n_runs
    warning('njm_payout:runs', 'Only %d of %d runs found (runs %s): the lottery is drawn from the %d trials that were done.', ...
        numel(unique(runs)), cfg.P.session.n_runs, mat2str(sort(runs)), numel(trials));
end

rs = RandStream('mt19937ar', 'Seed', 'shuffle');
result = struct();
result.subject = subjectID; result.session = sessionID;
result.drawn_at = datestr(now, 'yyyy-mm-dd HH:MM:SS');
result.random_seed = double(rs.Seed);
result.market_success_probability = PO.market_lottery_success_prob_PLACEHOLDER;
result.scanner = draw_lottery(rs, trials, PO, 'scanner');

result.online = struct('drawn', false, 'note', 'online choices not given: draw the online lottery separately', 'bonus_aed', 0);
if isfield(opts, 'onlineChoices') && ~isempty(opts.onlineChoices)
    T = readtable(opts.onlineChoices, 'TextType', 'char');
    online = struct('run', {}, 'trial', {}, 'confidence', {}, 'choice', {}, 'salary', {});
    for k = 1:height(T)
        online(end + 1) = struct('run', 0, 'trial', k, 'confidence', lower(T.confidence{k}), 'choice', 'n/a', 'salary', T.chosen_salary_aed(k)); %#ok<AGROW>
    end
    result.online = draw_lottery(rs, online, PO, 'online');
end

result.fmri_session_fee_aed = PO.fmri_session_fee_aed;
result.travel_allowance_aed = PO.travel_allowance_aed;
result.total_aed = PO.fmri_session_fee_aed + PO.travel_allowance_aed + result.scanner.bonus_aed + result.online.bonus_aed;

if exist(outFile, 'file')
    movefile(outFile, strrep(outFile, '.json', sprintf('_old-%s.json', datestr(now, 'yyyymmddTHHMMSS'))));
end
fid = fopen(outFile, 'w');
try, txt = jsonencode(result, 'PrettyPrint', true); catch, txt = jsonencode(result); end
fprintf(fid, '%s', txt); fclose(fid);
print_receipt(result);
fprintf('Saved: %s\n', outFile);

end

%--------------------------------------------------------------------------
function L = draw_lottery(rs, trials, PO, name)
L = struct('drawn', true, 'lottery', name, 'n_trials', numel(trials), 'picked_run', NaN, 'picked_trial', NaN, ...
    'answer', '', 'chosen_salary_aed', NaN, 'eligible', false, 'market_success', false, 'bonus_aed', 0, 'note', '');
if isempty(trials), L.note = 'no trials'; return; end
t = trials(randi(rs, numel(trials)));
L.picked_run = t.run; L.picked_trial = t.trial; L.chosen_salary_aed = t.salary;
L.answer = t.confidence;
L.eligible = strcmp(t.confidence, PO.eligible_confidence) && ~isnan(t.salary);
if ~L.eligible
    L.note = 'no bonus: the answer on the picked trial was not "Definitely Accept"';
    return;
end
L.market_success = rand(rs) < PO.market_lottery_success_prob_PLACEHOLDER;
if ~L.market_success
    L.note = 'no bonus: the job was not available in the market draw';
    return;
end
i = find(PO.salary_levels_aed == t.salary, 1);
if isempty(i), L.bonus_aed = floor(t.salary / PO.salary_scale_divisor); else, L.bonus_aed = PO.bonus_aed(i); end
L.note = sprintf('bonus: AED %d / %d, rounded down', t.salary, PO.salary_scale_divisor);
end

%--------------------------------------------------------------------------
function print_receipt(r)
fprintf('\n================ NJM PAYMENT - sub-%s ses-%s ================\n', r.subject, r.session);
fprintf('Drawn on %s\n\n', r.drawn_at);
parts = {r.scanner, r.online};
for i = 1:2
    L = parts{i};
    if ~L.drawn
        fprintf('%-8s lottery: not drawn here (%s)\n', 'Online', L.note); continue;
    end
    fprintf('%-8s lottery: picked trial %d', [upper(L.lottery(1)) L.lottery(2:end)], L.picked_trial);
    if L.picked_run > 0, fprintf(' of run %d', L.picked_run); end
    fprintf(' (of %d trials)\n', L.n_trials);
    fprintf('          answer: %s', L.answer);
    if ~isnan(L.chosen_salary_aed), fprintf(', chosen offer AED %d / month', L.chosen_salary_aed); end
    fprintf('\n          %s\n          BONUS: AED %d\n', L.note, L.bonus_aed);
end
fprintf('\nfMRI session fee      AED %d\n', r.fmri_session_fee_aed);
fprintf('Travel allowance      AED %d\n', r.travel_allowance_aed);
fprintf('Scanner lottery bonus AED %d\n', r.scanner.bonus_aed);
fprintf('Online lottery bonus  AED %d\n', r.online.bonus_aed);
fprintf('TOTAL TO PAY          AED %d\n', r.total_aed);
fprintf('=================================================================\n');
end

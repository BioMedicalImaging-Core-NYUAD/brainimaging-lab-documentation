function process_subject_fingermap(subID, ses, dmNum, dmBaseDir, bidsDir, codeDir)
% Process one subject/session: fit GLM on fsaverage6 BOLD data,
% combine runs via inverse-variance weighting, save betas + t-stats + p-values.
%
% Key differences from the original pipeline:
%   - Loads fsaverage6 .gii from fMRIPrep directly (no fsnative -> resample step)
%   - Combines runs using inverse-variance weighted average (not simple mean)
%   - Saves proper t-stats (from weighted beta/SE) and p-values per finger
%
% Output: derivatives/Execution_fsavg6/subID/ses/ and derivatives/Imagery_fsavg6/

fprintf('--- Processing Subject: %s | Session: %s ---\n', subID, ses);

space = 'fsaverage6';

% fsaverage6: 40962 vertices per hemisphere
nVertsPerHemi = 40962;
leftidx  = 1:nVertsPerHemi;
rightidx = (nVertsPerHemi + 1):(2 * nVertsPerHemi);

% --- Build dataLog (5 Imagery + 3 Execution runs) ---
imageryRuns   = 1:5;
executionRuns = 1:3;
nImagery   = numel(imageryRuns);
nExecution = numel(executionRuns);
nRuns      = nImagery + nExecution;

subject  = repmat({subID}, nRuns, 1);
session  = repmat({ses},   nRuns, 1);
taskList = [repmat({'Imagery'},   nImagery,   1); ...
            repmat({'Execution'}, nExecution, 1)];
runNum   = [imageryRuns'; executionRuns'];

dataLog = table(subject, session, taskList, runNum, ...
    'VariableNames', {'subject', 'session', 'task', 'run'});

% --- Load fsaverage6 BOLD data from fMRIPrep ---
fprintf('Loading fsaverage6 functional data...\n');
datafiles = load_dataLog(dataLog, space, bidsDir);

% --- Load design matrices and noise regressors ---
fprintf('Loading design matrices...\n');
[dsm, myNoise] = load_dsm(dataLog, dmBaseDir, dmNum, bidsDir);

% --- GLM per run: returns betas, SEs, and df ---
fprintf('Computing GLM per run...\n');
[~, betas, SEs, dfs, ~] = get_beta(datafiles, dsm, myNoise);

% --- MGZ templates (one per hemisphere, from first run's converted .mgh) ---
% load_dataLog converts .gii -> .mgh; we use those as surface-format templates.
funcDir = fullfile(bidsDir, 'derivatives', 'fmriprep', subID, ses, 'func');
row1    = dataLog(1, :);

lhMghFile = fullfile(funcDir, sprintf('%s_%s_task-%s_run-%02d_hemi-L_space-fsaverage6_bold.func.mgh', ...
    subID, ses, row1.task{1}, row1.run(1)));
rhMghFile = fullfile(funcDir, sprintf('%s_%s_task-%s_run-%02d_hemi-R_space-fsaverage6_bold.func.mgh', ...
    subID, ses, row1.task{1}, row1.run(1)));

lhTemplate = MRIread(lhMghFile);
rhTemplate = MRIread(rhMghFile);

% Reduce to single frame so the template has the right surface dimensions
lhTemplate.vol     = lhTemplate.vol(:, :, :, 1);
lhTemplate.nframes = 1;
rhTemplate.vol     = rhTemplate.vol(:, :, :, 1);
rhTemplate.nframes = 1;

% --- Finger names per task ---
fingerNames_imagery   = {'thumb', 'index', 'middle', 'ring', 'pinky', 'sixth'};
fingerNames_execution = {'thumb', 'index', 'middle', 'ring', 'pinky'};

% --- Process each task ---
tasksToProcess = {'Imagery', 'Execution'};

for iTask = 1:numel(tasksToProcess)
    currentTask = tasksToProcess{iTask};
    taskIndices = find(strcmp(dataLog.task, currentTask));

    betas_for_task = betas(taskIndices);
    SEs_for_task   = SEs(taskIndices);
    df_total       = sum(dfs(taskIndices));

    if strcmp(currentTask, 'Imagery')
        fingerNames = fingerNames_imagery;
    else
        fingerNames = fingerNames_execution;
    end
    nFingers = numel(fingerNames);

    fprintf('Combining %d runs for %s (df_total=%d)...\n', numel(taskIndices), currentTask, df_total);

    fingerBetas  = cell(1, nFingers);
    fingerTstats = cell(1, nFingers);
    fingerPvals  = cell(1, nFingers);

    for iFinger = 1:nFingers
        % Stack across runs: [nVerts x nRuns]
        betas_runs = cell2mat(cellfun(@(x) x(:, iFinger), betas_for_task, 'UniformOutput', false));
        SEs_runs   = cell2mat(cellfun(@(x) x(:, iFinger), SEs_for_task,   'UniformOutput', false));

        % Inverse-variance weighted combination
        weights   = 1 ./ SEs_runs .^ 2;                              % [nVerts x nRuns]
        beta_comb = sum(betas_runs .* weights, 2) ./ sum(weights, 2);% [nVerts x 1]
        SE_comb   = 1 ./ sqrt(sum(weights, 2));                       % [nVerts x 1]
        t_comb    = beta_comb ./ SE_comb;                             % [nVerts x 1]
        p_comb    = 2 * (1 - tcdf(abs(t_comb), df_total));            % [nVerts x 1]

        fingerBetas{iFinger}  = beta_comb;
        fingerTstats{iFinger} = t_comb;
        fingerPvals{iFinger}  = p_comb;
    end

    % --- Save ---
    resultsDir = fullfile(bidsDir, 'derivatives', [currentTask '_fsavg6'], subID, ses);
    if ~exist(resultsDir, 'dir')
        mkdir(resultsDir);
    end

    for iFinger = 1:nFingers
        fn = fingerNames{iFinger};

        % Beta maps
        lhTemplate.vol = fingerBetas{iFinger}(leftidx);
        MRIwrite(lhTemplate, fullfile(resultsDir, ['lh.' fn '.mgz']));
        rhTemplate.vol = fingerBetas{iFinger}(rightidx);
        MRIwrite(rhTemplate, fullfile(resultsDir, ['rh.' fn '.mgz']));

        % T-stat maps
        lhTemplate.vol = fingerTstats{iFinger}(leftidx);
        MRIwrite(lhTemplate, fullfile(resultsDir, ['lh.' fn '_tstat.mgz']));
        rhTemplate.vol = fingerTstats{iFinger}(rightidx);
        MRIwrite(rhTemplate, fullfile(resultsDir, ['rh.' fn '_tstat.mgz']));

        % P-value maps
        lhTemplate.vol = fingerPvals{iFinger}(leftidx);
        MRIwrite(lhTemplate, fullfile(resultsDir, ['lh.' fn '_pval.mgz']));
        rhTemplate.vol = fingerPvals{iFinger}(rightidx);
        MRIwrite(rhTemplate, fullfile(resultsDir, ['rh.' fn '_pval.mgz']));

        fprintf('  Saved: %s %s\n', currentTask, fn);
    end
end

fprintf('--- Done: %s %s ---\n\n', subID, ses);

end

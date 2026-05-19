% =====================================================================
% run_glm_rsa.m  —  First-level GLM for RSA (Step 1)
%
% Loops over al subjects, sessions, and tasks. For each run, fits a
% GLM with per-finger condition regressors + temporal derivatives +
% nuisance regressors (motion, FD, aCompCor x5, scrubbing). Saves
% per-run raw betas, SEs, and residuals — all required for the
% crossnobis RDM step.
%
% Output per subject/session/task (in derivatives/RSA/<subID>/<ses>/):
%   Execution_betas.mat     {1x3} cell  [nROI x 5]  per run
%   Execution_residuals.mat {1x3} cell  [nROI x nTRs] per run
%   Execution_SEs.mat       {1x3} cell  [nROI x 5]  per run
%   Execution_combined.mat  beta_combined, se_combined, t_combined [nROI x 5]
%   Imagery_betas.mat       {1x5} cell  [nROI x 6]  per run
%   Imagery_residuals.mat   {1x5} cell  [nROI x nTRs] per run
%   Imagery_SEs.mat         {1x5} cell  [nROI x 6]  per run
%   Imagery_combined.mat    beta_combined, se_combined, t_combined [nROI x 6]
%
% ROI: Glasser M1 (Area 4) + S1 (Areas 3a, 3b, 1, 2) on left hemisphere.
%      Betas and residuals are masked — vertices outside the ROI are
%      set to zero. Hand-knob restriction is applied in a later step.
% =====================================================================
clear all; close all; clc;

% ---- Paths ----
[~, currentUser] = system('whoami');
currentUser = strtrim(currentUser);

if strcmp(currentUser, 'pw1246')
    bidsDir = '/Users/pw1246/Library/CloudStorage/Box-Box/sixthfinger-test';
    fsHome  = '/Applications/freesurfer/7.4.1';
else
    bidsDir = '/Users/hha243/Library/CloudStorage/Box-Box/sixthfinger-test';
    fsHome  = '/Applications/freesurfer/8.1.0';
end

codeDir = fullfile(bidsDir, 'code');
addpath(genpath(fullfile(codeDir, 'RSA', 'helpers')));
if exist(fullfile(fsHome, 'matlab'), 'dir')
    addpath(genpath(fullfile(fsHome, 'matlab')));
end
addpath(genpath(fullfile(codeDir, 'spm')));

% ---- Load subject / session map ----
mapFile      = fullfile(codeDir, 'map.json');
mapData      = jsondecode(fileread(mapFile));
subjects     = mapData.subjects;
sessionDirMap = mapData.sessionDirs;
sesNames     = {sessionDirMap.session};
dmDirNames   = {sessionDirMap.dmDir};

% ---- Task definitions ----
taskDefs(1).name         = 'Execution';
taskDefs(1).runs         = 1:3;
taskDefs(1).fingerNames  = {'thumb', 'index', 'middle', 'ring', 'pinky'};
taskDefs(1).resultsName  = 'Execution';

taskDefs(2).name         = 'Imagery';
taskDefs(2).runs         = 1:5;
taskDefs(2).fingerNames  = {'thumb', 'index', 'middle', 'ring', 'pinky', 'sixth'};
taskDefs(2).resultsName  = 'Imagery';

space    = 'fsnative';
roiNames = {'4', '3a', '3b', '1', '2'};

fprintf('=== run_glm_rsa: %d subjects ===\n\n', numel(subjects));

% ---- Subject loop ----
for iSub = 1:numel(subjects)
    subID    = subjects(iSub).subID;
    dmNum    = subjects(iSub).dmNum;
    sessions = subjects(iSub).sessions;

    fprintf('=== Subject: %s | dmNum: %d ===\n', subID, dmNum);

    % ---- Build Glasser M1/S1 mask (left hemisphere only) ----
    fsSubDir   = fullfile(bidsDir, 'derivatives', 'freesurfer', subID);
    glasserDir = fullfile(fsSubDir, 'label', 'Glasser2016');

    if ~exist(fsSubDir, 'dir')
        fprintf('  SKIPPING %s: FreeSurfer directory not found\n\n', subID);
        continue;
    end

    lcurv   = read_curv(fullfile(fsSubDir, 'surf', 'lh.curv'));
    rcurv   = read_curv(fullfile(fsSubDir, 'surf', 'rh.curv'));
    nVertsL = numel(lcurv);
    nVertsR = numel(rcurv);

    lh_mask = false(nVertsL, 1);
    rh_mask = false(nVertsR, 1);   % kept for concatenation; stays false (RSA = LH only)

    for i = 1:numel(roiNames)
        lfile = fullfile(glasserDir, ['lh.' roiNames{i} '.label']);
        if exist(lfile, 'file')
            ld = read_label('', lfile);
            lh_mask(ld(:, 1) + 1) = true;
        else
            warning('Label not found: %s', lfile);
        end
    end

    all_mask = [lh_mask; rh_mask];
    fprintf('  Mask: %d vertices in LH M1/S1\n', sum(lh_mask));

    % ---- Session loop ----
    for iSes = 1:numel(sessions)
        ses    = sessions{iSes};
        sesIdx = find(strcmp(sesNames, ses), 1);
        if isempty(sesIdx)
            fprintf('  SKIPPING session %s: not in map.json\n', ses);
            continue;
        end
        dmBaseDir = fullfile(codeDir, dmDirNames{sesIdx});

        % ---- Task loop ----
        for iTask = 1:numel(taskDefs)
            task        = taskDefs(iTask).name;
            taskRuns    = taskDefs(iTask).runs;
            nRuns       = numel(taskRuns);
            resultsName = taskDefs(iTask).resultsName;

            fprintf('  [%s | %s | %s]\n', subID, ses, task);

            % Build dataLog for this subject/session/task
            dataLog = table( ...
                repmat({subID}, nRuns, 1), ...
                repmat({ses},   nRuns, 1), ...
                repmat({task},  nRuns, 1), ...
                taskRuns', ...
                'VariableNames', {'subject', 'session', 'task', 'run'});

            % Load BOLD data and design matrices
            try
                datafiles                           = load_dataLog(dataLog, space, bidsDir);
                [dsm, myNoise]                      = load_dsm_rsa(dataLog, dmBaseDir, dmNum, bidsDir);
                [raw_betas, resid, raw_SEs, Finfo]  = get_beta_rsa(datafiles, dsm, myNoise);
            catch ME
                fprintf('  ERROR %s %s %s: %s\n', subID, ses, task, ME.message);
                continue;
            end

            % Extract only masked vertices (LH M1/S1) — avoids saving huge zero arrays
            roi_idx = find(all_mask);   % indices of non-zero vertices

            betas_allruns     = cell(1, nRuns);  %#ok<NASGU>
            residuals_allruns = cell(1, nRuns);  %#ok<NASGU>
            SEs_allruns       = cell(1, nRuns);  %#ok<NASGU>
            SS_model_allruns  = cell(1, nRuns);
            SS_resid_allruns  = cell(1, nRuns);
            for iRun = 1:nRuns
                betas_allruns{iRun}     = raw_betas{iRun}(roi_idx, :);       % [nROI x nFingers]
                residuals_allruns{iRun} = resid{iRun}(roi_idx, :);           % [nROI x nTRs]
                SEs_allruns{iRun}       = raw_SEs{iRun}(roi_idx, :);         % [nROI x nFingers]
                SS_model_allruns{iRun}  = Finfo.SS_model{iRun}(roi_idx, :);  % [nROI x 1]
                SS_resid_allruns{iRun}  = Finfo.SS_resid{iRun}(roi_idx, :);  % [nROI x 1]
            end

            % ---- Precision-weighted combination across runs ----
            nROI     = numel(roi_idx);
            nFingers = size(betas_allruns{1}, 2);
            prec_sum  = zeros(nROI, nFingers);
            wbeta_sum = zeros(nROI, nFingers);
            for iRun = 1:nRuns
                prec      = 1 ./ (SEs_allruns{iRun} .^ 2);  % [nROI x nFingers]
                prec_sum  = prec_sum  + prec;
                wbeta_sum = wbeta_sum + prec .* betas_allruns{iRun};
            end
            beta_combined = wbeta_sum ./ prec_sum;           % [nROI x nFingers]
            se_combined   = sqrt(1 ./ prec_sum);             % [nROI x nFingers]
            t_combined    = beta_combined ./ se_combined;    % [nROI x nFingers]

            % ---- Exact omnibus F pooled across runs ----
            % Pool SS across runs before dividing — never average F-stats directly
            SS_model_total = zeros(nROI, 1);
            SS_resid_total = zeros(nROI, 1);
            for iRun = 1:nRuns
                SS_model_total = SS_model_total + SS_model_allruns{iRun};
                SS_resid_total = SS_resid_total + SS_resid_allruns{iRun};
            end
            df_num_total   = Finfo.df_num * nRuns;           % scalar
            df_denom_total = sum(Finfo.df_denom);            % scalar
            F_combined     = (SS_model_total / df_num_total) ./ ...
                             (SS_resid_total / df_denom_total);   % [nROI x 1]
            p_combined     = 1 - fcdf(F_combined, df_num_total, df_denom_total); %#ok<NASGU>

            % Save
            outDir = fullfile(bidsDir, 'derivatives', 'RSA', subID, ses);
            if ~exist(outDir, 'dir')
                mkdir(outDir);
            end

            save(fullfile(outDir, [resultsName '_betas.mat']),     'betas_allruns', 'roi_idx', '-v7.3');
            save(fullfile(outDir, [resultsName '_residuals.mat']), 'residuals_allruns', 'roi_idx', '-v7.3');
            save(fullfile(outDir, [resultsName '_SEs.mat']),       'SEs_allruns', 'roi_idx', '-v7.3');
            save(fullfile(outDir, [resultsName '_combined.mat']), ...
                'beta_combined', 'se_combined', 't_combined', ...
                'F_combined', 'p_combined', 'df_num_total', 'df_denom_total', ...
                'SS_model_total', 'SS_resid_total', ...
                'roi_idx', '-v7.3');

            fprintf('  Saved %s betas + SEs + residuals + combined (with F) for %s %s\n', task, subID, ses);
        end % tasks
    end % sessions

    fprintf('\n');
end % subjects

fprintf('=== Done! ===\n');

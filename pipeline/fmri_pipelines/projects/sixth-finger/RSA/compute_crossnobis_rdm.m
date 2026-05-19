% =====================================================================
% compute_crossnobis_rdm.m  —  Crossnobis RDM per subject/session/task
%
% ROI modes (set roiMode below):
%   1 = WTA functional ROI defined from ses-01 Execution only
%   2 = WTA functional ROI defined from all sessions pooled  (default)
%   3 = Full anatomical M1/S1 (Glasser Areas 4, 3a, 3b, 1, 2) — no WTA
%
% For each subject × session × task:
%   1. Builds ROI mask according to roiMode
%   2. Prewhitens betas run-wise using Ledoit-Wolf regularised noise
%      covariance estimated from GLM residuals
%   3. Computes crossnobis RDM via rsa.distanceLDC (leave-one-run-out)
%   4. Saves RDM matrix and vectorised distances
%
% Output per subject/session/task (filename includes ROI tag):
%   derivatives/RSA/<subID>/<ses>/Execution_RDM_<roiTag>.mat  [5×5]
%   derivatives/RSA/<subID>/<ses>/Imagery_RDM_<roiTag>.mat    [6×6]
%
% roiTag values: ses01WTA | allsesWTA | anatROI
% =====================================================================
clear all; close all; clc;

% ---- USER SETTING ----
% 1 = WTA from ses-01 Execution only
% 2 = WTA from all sessions pooled (default)
% 3 = Full anatomical M1/S1, no WTA filtering
roiMode = 1;
% ----------------------

roiTags = {'ses01WTA', 'allsesWTA', 'anatROI'};
roiTag  = roiTags{roiMode};

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
addpath(genpath(fullfile(codeDir, 'RSAtoolbox')));

% ---- Task definitions ----
taskDefs(1).name        = 'Execution';
taskDefs(1).fingerNames = {'thumb','index','middle','ring','pinky'};
taskDefs(1).nRuns       = 3;

taskDefs(2).name        = 'Imagery';
taskDefs(2).fingerNames = {'thumb','index','middle','ring','pinky','sixth'};
taskDefs(2).nRuns       = 5;

% ---- Load subject list ----
mapData  = jsondecode(fileread(fullfile(codeDir, 'map.json')));
subjects = mapData.subjects;

fprintf('=== compute_crossnobis_rdm: %d subjects | roiMode=%d (%s) ===\n\n', ...
    numel(subjects), roiMode, roiTag);

% =====================================================================
% Subject loop
% =====================================================================
for iSub = 1:numel(subjects)
    subID    = subjects(iSub).subID;
    sessions = subjects(iSub).sessions;

    fprintf('=== %s ===\n', subID);

    % ==================================================================
    % Build ROI mask for this subject (mode-dependent)
    % roi_mask: [nROI × 1] logical, indexes into rows of betas_allruns
    %   (rows already correspond to Glasser M1/S1 vertices from run_glm_rsa)
    % ==================================================================
    switch roiMode

        case 1   % WTA derived from ses-01 Execution only
            wtaFile = fullfile(bidsDir, 'derivatives', 'RSA', subID, 'ROI', ...
                               'Execution_ses01_WTA.mat');
            if ~exist(wtaFile, 'file')
                fprintf('  SKIPPING: Execution_ses01_WTA.mat not found\n\n');
                continue;
            end
            load(wtaFile, 'wta_map', 'roi_idx');
            roi_mask = wta_map > 0;

            fprintf('  ROI (ses-01 WTA): %d / %d vertices\n', ...
                sum(roi_mask), numel(roi_mask));

        case 2   % WTA from all sessions pooled (original default)
            wtaFile = fullfile(bidsDir, 'derivatives', 'RSA', subID, 'ROI', ...
                               'Execution_allses_WTA.mat');
            if ~exist(wtaFile, 'file')
                fprintf('  SKIPPING: Execution_allses_WTA.mat not found\n\n');
                continue;
            end
            load(wtaFile, 'wta_map', 'roi_idx');
            roi_mask = wta_map > 0;

            fprintf('  ROI (all-ses WTA): %d / %d vertices\n', ...
                sum(roi_mask), numel(roi_mask));

        case 3   % Full anatomical M1/S1, no WTA filtering
            % roi_idx is the same for all modes — get it from WTA file if
            % available, otherwise from any saved betas/combined file
            wtaFile = fullfile(bidsDir, 'derivatives', 'RSA', subID, 'ROI', ...
                               'Execution_allses_WTA.mat');
            if exist(wtaFile, 'file')
                load(wtaFile, 'roi_idx');
            else
                % Fall back to first available Execution betas file
                fallbackFile = '';
                for iS = 1:numel(sessions)
                    candidate = fullfile(bidsDir, 'derivatives', 'RSA', subID, ...
                                         sessions{iS}, 'Execution_betas.mat');
                    if exist(candidate, 'file')
                        fallbackFile = candidate;
                        break;
                    end
                end
                if isempty(fallbackFile)
                    fprintf('  SKIPPING: cannot determine roi_idx\n\n');
                    continue;
                end
                load(fallbackFile, 'roi_idx');
            end
            roi_mask = true(numel(roi_idx), 1);   % use all M1/S1 vertices

            fprintf('  ROI (anatomical M1/S1): %d vertices\n', sum(roi_mask));
    end

    nROI = sum(roi_mask);

    % ==================================================================
    % Session loop
    % ==================================================================
    for iSes = 1:numel(sessions)
        ses = sessions{iSes};

        % ==============================================================
        % Task loop
        % ==============================================================
        for iTask = 1:numel(taskDefs)
            task        = taskDefs(iTask).name;
            fingerNames = taskDefs(iTask).fingerNames;
            nFingers    = numel(fingerNames);
            nRuns       = taskDefs(iTask).nRuns;

            fprintf('  [%s | %s] ', ses, task);

            % ---- Load betas and residuals ----
            rsaDir    = fullfile(bidsDir, 'derivatives', 'RSA', subID, ses);
            betaFile  = fullfile(rsaDir, [task '_betas.mat']);
            residFile = fullfile(rsaDir, [task '_residuals.mat']);

            if ~exist(betaFile,'file') || ~exist(residFile,'file')
                fprintf('SKIPPING: files not found\n');
                continue;
            end

            load(betaFile,  'betas_allruns');
            load(residFile, 'residuals_allruns');

            % ---- Prewhiten betas run-wise and stack ----
            B_all        = zeros(nRuns * nFingers, nROI);
            partition    = zeros(nRuns * nFingers, 1);
            conditionVec = zeros(nRuns * nFingers, 1);

            for iRun = 1:nRuns
                % Restrict to ROI vertices
                B_run = betas_allruns{iRun}(roi_mask, :)';   % [nFingers × nROI]
                R_run = residuals_allruns{iRun}(roi_mask, :); % [nROI × nTRs]

                % Run-wise noise covariance with Ledoit-Wolf regularisation
                Sigma = lw_cov(R_run);   % [nROI × nROI]

                % Sigma^(-1/2) via eigendecomposition
                [V, D]         = eig(Sigma);
                d_eig          = max(diag(D), eps);
                Sigma_inv_sqrt = V * diag(1 ./ sqrt(d_eig)) * V';

                % Prewhiten: B_white = B × Sigma^(-1/2)
                B_white = B_run * Sigma_inv_sqrt;   % [nFingers × nROI]

                % Insert into stacked matrix
                rows = (iRun-1)*nFingers + (1:nFingers);
                B_all(rows, :)     = B_white;
                partition(rows)    = iRun;
                conditionVec(rows) = 1:nFingers;
            end

            % ---- Crossnobis RDM via distanceLDC ----
            d_vec = rsa.distanceLDC(B_all, partition, conditionVec);
            % d_vec: [1 × nFingers*(nFingers-1)/2] upper triangle, can be negative

            % ---- Build symmetric RDM matrix ----
            RDM = vec_to_rdm(d_vec, nFingers);

            % ---- Save ----
            outFile = fullfile(rsaDir, [task '_RDM_' roiTag '.mat']);
            save(outFile, 'RDM', 'd_vec', 'fingerNames', 'nFingers', ...
                'roi_mask', 'nROI', 'roi_idx', 'roiMode', 'roiTag', '-v7.3');

            fprintf('RDM saved [%dx%d] -> %s\n', nFingers, nFingers, outFile);

        end % tasks
    end % sessions

    fprintf('\n');
end % subjects

fprintf('=== Done! ===\n');


% =====================================================================
% Helper: Ledoit-Wolf regularised covariance
% Shrinks sample covariance toward scaled identity matrix.
% Input:  X [nVerts × nTRs] residuals
% Output: S [nVerts × nVerts] regularised covariance
% =====================================================================
function S = lw_cov(X)
    [p, n] = size(X);
    X      = X - mean(X, 2);          % de-mean (should already be ~0)
    S_raw  = (X * X') / (n - 1);      % sample covariance [p × p]

    % Ledoit-Wolf analytical shrinkage toward scaled identity
    mu      = trace(S_raw) / p;
    S_dev   = S_raw - mu * eye(p);
    rho_num = (1/n) * (norm(S_raw,'fro')^2 + trace(S_raw)^2);
    rho_den = (n+2)  * (norm(S_dev,'fro')^2);

    if rho_den == 0
        lambda = 1;
    else
        lambda = min(1, rho_num / rho_den);
    end

    S = (1 - lambda) * S_raw + lambda * mu * eye(p);
end


% =====================================================================
% Helper: vectorised upper triangle → symmetric RDM matrix
% Handles negative crossnobis values (unlike squareform)
% =====================================================================
function RDM = vec_to_rdm(d_vec, n)
    RDM = zeros(n);
    idx = 1;
    for i = 1:n-1
        for j = i+1:n
            RDM(i,j) = d_vec(idx);
            RDM(j,i) = d_vec(idx);
            idx = idx + 1;
        end
    end
end

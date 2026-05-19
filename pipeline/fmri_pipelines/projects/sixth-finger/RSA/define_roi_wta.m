% =====================================================================
% define_roi_wta.m  —  ROI Definition via F-contrast + Winner-Takes-All
%
% Loops over all subjects. For each subject, defines a functional ROI
% by pooling Execution data across ALL available sessions:
%
%   F-test (which vertices respond to any finger?):
%     Pool SS_model and SS_resid across all sessions before dividing.
%     This is the statistically correct way to combine evidence — same
%     logic as pooling runs within a session, extended across sessions.
%     Subjects with 2 sessions use 2; subjects with 3 use 3.
%
%   Winner-Takes-All (which finger does each vertex prefer?):
%     Precision-weight beta_combined and se_combined across sessions
%     to get a single t-stat per vertex per finger. Argmax assigns
%     each active vertex to its dominant finger.
%
% Threshold: p < 1e-8 (uncorrected)
%
% Output: derivatives/RSA/<subID>/ROI/Execution_allses_WTA.mat
% =====================================================================
clc;
p_thresh    = 1e-8;
task        = 'Execution';
fingerNames = {'thumb', 'index', 'middle', 'ring', 'pinky'};
nFingers    = numel(fingerNames);

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

mapData  = jsondecode(fileread(fullfile(codeDir, 'map.json')));
subjects = mapData.subjects;

fprintf('=== define_roi_wta: %d subjects | %s | all sessions | p < %.0e ===\n\n', ...
    numel(subjects), task, p_thresh);

% ---- Subject loop ----
for iSub = 1:numel(subjects)
    subID    = subjects(iSub).subID;
    sessions = subjects(iSub).sessions;

    fprintf('[%s]\n', subID);

    % ---- Load and pool across all available sessions ----
    SS_model_allses  = [];   % [nROI × 1] accumulated
    SS_resid_allses  = [];
    df_num_allses    = 0;
    df_denom_allses  = 0;

    prec_sum_allses  = [];   % [nROI × nFingers] for precision-weighted t
    wbeta_sum_allses = [];
    roi_idx          = [];

    nSesUsed = 0;

    for iSes = 1:numel(sessions)
        ses     = sessions{iSes};
        matFile = fullfile(bidsDir, 'derivatives', 'RSA', subID, ses, ...
                           [task '_combined.mat']);

        if ~exist(matFile, 'file')
            fprintf('  ses-%02d: file not found, skipping\n', iSes);
            continue;
        end

        load(matFile, 'SS_model_total', 'SS_resid_total', ...
                      'df_num_total', 'df_denom_total', ...
                      'beta_combined', 'se_combined', 'roi_idx');

        % Initialise accumulator on first valid session
        if isempty(SS_model_allses)
            SS_model_allses  = zeros(size(SS_model_total));
            SS_resid_allses  = zeros(size(SS_resid_total));
            prec_sum_allses  = zeros(size(se_combined));
            wbeta_sum_allses = zeros(size(beta_combined));
        end

        % Pool SS for F-test
        SS_model_allses = SS_model_allses + SS_model_total;
        SS_resid_allses = SS_resid_allses + SS_resid_total;
        df_num_allses   = df_num_allses   + df_num_total;
        df_denom_allses = df_denom_allses + df_denom_total;

        % Precision-weight betas for t-stat
        prec             = 1 ./ (se_combined .^ 2);   % [nROI × nFingers]
        prec_sum_allses  = prec_sum_allses  + prec;
        wbeta_sum_allses = wbeta_sum_allses + prec .* beta_combined;

        nSesUsed = nSesUsed + 1;
        fprintf('  %s: df = (%d, %d)\n', ses, df_num_total, df_denom_total);
    end

    if nSesUsed == 0
        fprintf('  SKIPPING: no data found\n\n');
        continue;
    end

    % ---- Combined F and p across all sessions ----
    F_combined = (SS_model_allses / df_num_allses) ./ ...
                 (SS_resid_allses / df_denom_allses);           % [nROI × 1]
    p_combined = 1 - fcdf(F_combined, df_num_allses, df_denom_allses);

    fprintf('  Pooled df = (%d, %d) across %d sessions\n', ...
        df_num_allses, df_denom_allses, nSesUsed);

    % ---- Combined t across all sessions (precision-weighted) ----
    beta_combined_allses = wbeta_sum_allses ./ prec_sum_allses;  % [nROI × nFingers]
    se_combined_allses   = sqrt(1 ./ prec_sum_allses);
    t_combined_allses    = beta_combined_allses ./ se_combined_allses;

    % ---- F-threshold ----
    active_mask = p_combined < p_thresh;
    fprintf('  Surviving p < %.0e: %d / %d (%.1f%%)\n', ...
        p_thresh, sum(active_mask), numel(active_mask), 100*mean(active_mask));

    % ---- Winner-Takes-All ----
    [max_t, wta_idx] = max(t_combined_allses, [], 2);   % [nROI × 1]

    wta_map = zeros(size(wta_idx));
    wta_map(active_mask & max_t > 0) = wta_idx(active_mask & max_t > 0);

    for iFing = 1:nFingers
        fprintf('  %s: %d vertices\n', fingerNames{iFing}, sum(wta_map == iFing));
    end

    % ---- Save ROI ----
    outDir = fullfile(bidsDir, 'derivatives', 'RSA', subID, 'ROI');
    if ~exist(outDir, 'dir'), mkdir(outDir); end

    roiFile = fullfile(outDir, 'Execution_allses_WTA.mat');
    save(roiFile, 'wta_map', 'active_mask', 'roi_idx', ...
        'F_combined', 'p_combined', 'df_num_allses', 'df_denom_allses', ...
        'p_thresh', 'nSesUsed', '-v7.3');

    % ---- Save .mgh overlays for Freeview ----
    fsSubDir = fullfile(bidsDir, 'derivatives', 'freesurfer', subID);
    lcurv    = read_curv(fullfile(fsSubDir, 'surf', 'lh.curv'));
    nVertsL  = numel(lcurv);
    lh_roi   = roi_idx(roi_idx <= nVertsL);

    vol_F   = zeros(nVertsL, 1, 1);
    vol_p   = zeros(nVertsL, 1, 1);
    vol_wta = zeros(nVertsL, 1, 1);

    vol_F(lh_roi)   = F_combined;
    vol_p(lh_roi)   = -log10(max(p_combined, 1e-20));
    vol_wta(lh_roi) = wta_map;

    save_mgh(vol_F,   fullfile(outDir, 'lh.Execution_allses_Fmap.mgh'),      eye(4));
    save_mgh(vol_p,   fullfile(outDir, 'lh.Execution_allses_neglog10p.mgh'), eye(4));
    save_mgh(vol_wta, fullfile(outDir, 'lh.Execution_allses_WTA.mgh'),       eye(4));

    fprintf('  Saved -> %s\n\n', outDir);
end

fprintf('=== Done! ===\n');

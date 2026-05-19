% =====================================================================
% check_timeseries.m
% Goal: assess whether BA9/46/7/40 vertices "learned" to respond to the
% 6th finger between ses-01 and ses-02 (Imagery task, sub-0457).
%
% Fingers shown: thumb, index, sixth
%
% Per finger, 3 subplots:
%   1. Top 50 BA9/46/7/40 by ses-01 beta  -> ses-01 STA (blue) vs ses-02 STA (red)
%   2. Top 50 BA9/46/7/40 by ses-02 beta  -> ses-01 STA (blue) vs ses-02 STA (red)
%   3. Overlay: top-50-ses01 in ses-01 (blue) vs top-50-ses02 in ses-02 (red)
%      ("best of each session")
%
% BOLD preloading: one batch per session (2 sessions x 5 runs = 10 reads),
% filtered to BA9/46/7/40 vertices immediately after loading.
% STAs for all fingers are computed in the same pass.
% =====================================================================
clear all; close all; clc;

% --- Configuration ---
subID       = 'sub-0457';
dmNum       = 102;
topN        = 500;      % 500 is ~2.3% of ~21,983 BA9/46/7/40 vertices
preStim     = 12;       % seconds before stimulus onset (pre-stim rest)
postStim    = 24;       % seconds after stimulus onset (12s stim + 12s rest)
epochLen    = preStim + postStim;  % 36 total
TR          = 1;        % seconds
smoothWin   = 3;        % gaussian smoothing window (TRs), set 0 to disable
mi_nums     = [1, 3, 5, 7, 8];

fingers     = {'sixth'};
fingerCols  = [6];      % DM column: sixth=6
nFingers    = numel(fingers);

% --- Paths ---
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
addpath(genpath(pwd));
addpath(fullfile(fileparts(mfilename('fullpath')), 'helpers'));
if exist(fullfile(fsHome, 'matlab'), 'dir')
    addpath(genpath(fullfile(fsHome, 'matlab')));
end

mapData    = jsondecode(fileread(fullfile(codeDir, 'map.json')));
sesNames   = {mapData.sessionDirs.session};
dmDirNames = {mapData.sessionDirs.dmDir};

% --- BA9/46/7/40 mask (Glasser 2016) ---
fsSubDir  = fullfile(bidsDir, 'derivatives', 'freesurfer', subID);
lcurv     = read_curv(fullfile(fsSubDir, 'surf', 'lh.curv'));
rcurv     = read_curv(fullfile(fsSubDir, 'surf', 'rh.curv'));
nVertsL   = numel(lcurv);
nVertsR   = numel(rcurv);
totalVerts = nVertsL + nVertsR;
leftidx   = 1:nVertsL;
rightidx  = (1:nVertsR) + nVertsL;

glasserDir = fullfile(fsSubDir, 'label', 'Glasser2016');
roiNames   = {'9a', '9p', '9m', '46', '9-46d', ...
              '7AL', '7Am', '7PC', '7PL', '7Pm', '7m', ...
              'PF', 'PFcm', 'PFm', 'PFop', 'PFt'};
lh_mask    = false(nVertsL, 1);
rh_mask    = false(nVertsR, 1);
for i = 1:length(roiNames)
    lfile = fullfile(glasserDir, ['lh.' roiNames{i} '.label']);
    if exist(lfile, 'file')
        ld = read_label('', lfile); lh_mask(ld(:,1)+1) = true;
    end
    rfile = fullfile(glasserDir, ['rh.' roiNames{i} '.label']);
    if exist(rfile, 'file')
        rd = read_label('', rfile); rh_mask(rd(:,1)+1) = true;
    end
end
all_mask  = [lh_mask; rh_mask];
maskIdx   = find(all_mask);
nM1S1     = numel(maskIdx);
fprintf('BA9/46/7/40 mask: %d vertices\n\n', nM1S1);

% --- Load 6th-finger betas for difference map, all finger betas for ranking ---
imgDir = fullfile(bidsDir, 'derivatives', 'Imagery_native_BA9-46-7-40', subID);

% beta_m1s1: [nM1S1 x nFingers x 2 sessions]
beta_m1s1 = zeros(nM1S1, nFingers, 2);

for iSes = 1:2
    ses = sprintf('ses-%02d', iSes);
    for iF = 1:nFingers
        lhB = MRIread(fullfile(imgDir, ses, ['lh.' fingers{iF} '.mgz']));
        rhB = MRIread(fullfile(imgDir, ses, ['rh.' fingers{iF} '.mgz']));
        b   = [squeeze(lhB.vol); squeeze(rhB.vol)];
        beta_m1s1(:, iF, iSes) = b(maskIdx);
    end
    fprintf('Loaded betas: %s\n', ses);
end

% --- Save ses-02 minus ses-01 sixth-finger beta difference map ---
lhB1 = MRIread(fullfile(imgDir, 'ses-01', 'lh.sixth.mgz'));
rhB1 = MRIread(fullfile(imgDir, 'ses-01', 'rh.sixth.mgz'));
lhB2 = MRIread(fullfile(imgDir, 'ses-02', 'lh.sixth.mgz'));
rhB2 = MRIread(fullfile(imgDir, 'ses-02', 'rh.sixth.mgz'));

fullDiff = [squeeze(lhB2.vol); squeeze(rhB2.vol)] - [squeeze(lhB1.vol); squeeze(rhB1.vol)];
diffBeta = zeros(totalVerts, 1);
diffBeta(maskIdx) = fullDiff(maskIdx);

resultsDir = fullfile(bidsDir, 'derivatives', 'timeseries', subID);
if ~exist(resultsDir, 'dir'), mkdir(resultsDir); end

mgz_L = MRIread(fullfile(fsSubDir, 'mri', 'orig.mgz'));
mgz_R = mgz_L;
mgz_L.vol = diffBeta(leftidx);
MRIwrite(mgz_L, fullfile(resultsDir, 'lh.sixth_beta_diff_ses02_minus_ses01.mgz'));
mgz_R.vol = diffBeta(rightidx);
MRIwrite(mgz_R, fullfile(resultsDir, 'rh.sixth_beta_diff_ses02_minus_ses01.mgz'));
fprintf('Saved beta difference maps.\n\n');

% =====================================================================
% Preload BOLD per session, filter to BA9/46/7/40, compute STA for all fingers
% sta: [nROI x epochLen x nFingers x 2 sessions]
% =====================================================================
sta = zeros(nM1S1, epochLen, nFingers, 2);

for iSes = 1:2
    ses    = sprintf('ses-%02d', iSes);
    sesIdx = find(strcmp(sesNames, ses), 1);
    dmBaseDir = fullfile(codeDir, dmDirNames{sesIdx});

    fprintf('=== Session: %s — preloading runs ===\n', ses);

    % Accumulators for each finger
    sumEpoch = zeros(nM1S1, epochLen, nFingers);
    nEpochs  = zeros(1, nFingers);

    for iRun = 1:5
        fprintf('  Run %d/5: loading... ', iRun);

        funcDir = fullfile(bidsDir, 'derivatives', 'fmriprep', subID, ses, 'func');
        lhFile  = fullfile(funcDir, sprintf('%s_%s_task-Imagery_run-%02d_hemi-L_space-fsnative_bold.func.mgh', subID, ses, iRun));
        rhFile  = fullfile(funcDir, sprintf('%s_%s_task-Imagery_run-%02d_hemi-R_space-fsnative_bold.func.mgh', subID, ses, iRun));

        if ~exist(lhFile, 'file') || ~exist(rhFile, 'file')
            fprintf('not found, skipping.\n'); continue;
        end

        lhMGZ = MRIread(lhFile);
        rhMGZ = MRIread(rhFile);
        boldAll = [squeeze(lhMGZ.vol); squeeze(rhMGZ.vol)];  % [totalVerts x nTRs]
        bold    = boldAll(maskIdx, :);                        % [nM1S1 x nTRs]
        nTRs    = size(bold, 2);

        % Convert to PSC (run mean per vertex)
        runMean = mean(bold, 2);
        runMean(abs(runMean) < 1e-6) = 1e-6;
        psc = ((bold ./ runMean) - 1) * 100;                 % [nM1S1 x nTRs]

        % --- Noise regression (same confounds as GLM) ---
        % Removes motion, physiological noise, and drift before epoch extraction
        confFile = fullfile(bidsDir, 'derivatives', 'fmriprep', subID, ses, 'func', ...
            sprintf('%s_%s_task-Imagery_run-%02d_desc-confounds_timeseries.tsv', subID, ses, iRun));
        if exist(confFile, 'file')
            conf = readtable(confFile, 'FileType', 'text', 'Delimiter', '\t');
            confCols = {'trans_x','trans_y','trans_z','rot_x','rot_y','rot_z', ...
                        'global_signal','white_matter','csf'};
            confData = table2array(conf(:, confCols));
            confData(isnan(confData)) = 0;
            % Add constant + linear drift
            X_noise = [ones(nTRs,1), (1:nTRs)', confData];
            % Regress out: residual = Y - X*(X\Y)
            psc = psc - (X_noise * (X_noise \ psc'))';      % [nM1S1 x nTRs]
        else
            warning('Confounds file not found for run %d, skipping noise regression.', iRun);
        end

        % Load DM once per run, extract onsets for all fingers
        logDir    = fullfile(dmBaseDir, num2str(dmNum), 'Results');
        dmFileNum = mi_nums(iRun);
        dmFiles   = dir(fullfile(logDir, sprintf('sixFingers1_MI_%d_%d_*_dm.csv', dmNum, dmFileNum)));
        if isempty(dmFiles)
            fprintf('DM not found, skipping.\n'); continue;
        end
        dm = readmatrix(fullfile(logDir, dmFiles(1).name));
        if isnan(dm(1,1)), dm = dm(2:end, :); end

        fprintf('loaded. ');
        for iF = 1:nFingers
            onsets = find(diff([0; dm(:, fingerCols(iF))]) == 1);
            for iOnset = 1:numel(onsets)
                onset      = onsets(iOnset);
                epochStart = onset - preStim;           % 12s before stimulus
                epochEnd   = onset + postStim - 1;      % 24s after stimulus onset
                if epochStart < 1 || epochEnd > nTRs, continue; end

                % Baseline = mean of the 12s pre-stimulus rest
                baseline = mean(psc(:, epochStart:onset-1), 2);
                epoch    = psc(:, epochStart:epochEnd) - baseline;  % [nM1S1 x 36]

                sumEpoch(:,:,iF) = sumEpoch(:,:,iF) + epoch;
                nEpochs(iF)      = nEpochs(iF) + 1;
            end
        end
        fprintf('epochs so far: sixth=%d\n', nEpochs(1));
    end

    for iF = 1:nFingers
        if nEpochs(iF) > 0
            sta(:,:,iF,iSes) = sumEpoch(:,:,iF) / nEpochs(iF);
        end
    end
    fprintf('  Done: %d total sixth-finger epochs.\n\n', nEpochs(1));
end

% =====================================================================
% Rank sixth-finger vertices and compute STAs
% =====================================================================
iF = 1;  % only sixth finger
fprintf('BA9/46/7/40 total: %d vertices. topN=%d = %.1f%%\n\n', nM1S1, topN, 100*topN/nM1S1);

[~, rank1] = sort(beta_m1s1(:, iF, 1), 'descend');
[~, rank2] = sort(beta_m1s1(:, iF, 2), 'descend');
top1 = rank1(1:topN);   % top-N by ses-01 beta (indices into BA9/46/7/40)
top2 = rank2(1:topN);   % top-N by ses-02 beta (indices into BA9/46/7/40)

% Three timeseries to plot
ts_t1_s1 = mean(sta(top1, :, iF, 1), 1);  % top ses-01 @ ses-01 (blue solid)
ts_t2_s2 = mean(sta(top2, :, iF, 2), 1);  % top ses-02 @ ses-02 (red solid)
ts_t2_s1 = mean(sta(top2, :, iF, 1), 1);  % top ses-02 @ ses-01 (red dashed)

if smoothWin > 0
    ts_t1_s1 = smoothdata(ts_t1_s1, 'gaussian', smoothWin);
    ts_t2_s2 = smoothdata(ts_t2_s2, 'gaussian', smoothWin);
    ts_t2_s1 = smoothdata(ts_t2_s1, 'gaussian', smoothWin);
end

% =====================================================================
% Save top-N ses-02 vertex mask as mgz (for freeview inspection)
% =====================================================================
% Map BA9/46/7/40 local indices back to full surface space
globalTop2 = maskIdx(top2);   % indices into [lh; rh] concatenated

top2_mask = zeros(totalVerts, 1);
top2_mask(globalTop2) = 1;

mgz_L.vol = top2_mask(leftidx);
MRIwrite(mgz_L, fullfile(resultsDir, 'lh.sixth_top_ses02.mgz'));
mgz_R.vol = top2_mask(rightidx);
MRIwrite(mgz_R, fullfile(resultsDir, 'rh.sixth_top_ses02.mgz'));
fprintf('Saved top-%d ses-02 vertex mask: lh/rh.sixth_top_ses02.mgz\n\n', topN);

% =====================================================================
% Plot: single figure, 3 lines
% =====================================================================
tAxis  = (-preStim : TR : postStim-1);   % -12 to +23, 0 = stimulus onset
cBlue  = [0.2 0.4 0.8];
cRed   = [0.85 0.2 0.2];

allVals = [ts_t1_s1 ts_t2_s2 ts_t2_s1];
ypad    = 0.2 * (max(allVals) - min(allVals) + 0.01);
ylims   = [min(allVals)-ypad, max(allVals)+ypad];

figure('Position', [100 100 800 500]);
hold on;
mark_stim(tAxis, ylims);
plot(tAxis, ts_t1_s1, '-',  'Color', cBlue, 'LineWidth', 2.5, ...
     'DisplayName', sprintf('top%d ses-01  @ ses-01', topN));
plot(tAxis, ts_t2_s2, '-',  'Color', cRed,  'LineWidth', 2.5, ...
     'DisplayName', sprintf('top%d ses-02  @ ses-02', topN));
plot(tAxis, ts_t2_s1, '--', 'Color', cRed,  'LineWidth', 2, ...
     'DisplayName', sprintf('top%d ses-02  @ ses-01', topN));
yline(0, '--k', 'Alpha', 0.25, 'HandleVisibility', 'off');
xlim([tAxis(1) tAxis(end)]); ylim(ylims);
xlabel('Time from stimulus onset (s)'); ylabel('% Signal Change');
title(sprintf('%s — Imagery STA: sixth finger | BA9/46/7/40 (Glasser)', subID));
legend('Location', 'northeast'); grid on; box on;
hold off;

fprintf('=== Done! ===\n');

% =====================================================================
% Local function: shade stimulus period on current axes
% =====================================================================
function mark_stim(tAxis, ylims)
    fill([0 12 12 0], [ylims(1) ylims(1) ylims(2) ylims(2)], ...
         [1 0.95 0.8], 'EdgeColor', 'none', 'HandleVisibility', 'off');
    xline(0,  '-k', 'Alpha', 0.4, 'HandleVisibility', 'off');
    xline(12, '-k', 'Alpha', 0.4, 'HandleVisibility', 'off');
end

set(findall(gcf, '-property', 'FontSize'), 'FontSize', 15)
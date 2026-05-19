% =====================================================================
% group_timeseries_subrois.m
% Same STA pipeline as group_timeseries.m but computed separately for
% each BA1-4 sub-ROI: M1 (area 4), 3a, 3b, 1, 2.
%
% BOLD is loaded once per run and shared across sub-ROIs for efficiency.
%
% Block 1: compute + save one .mat per sub-ROI
% Block 2: load all saved .mats, plot group average in subplots (one per sub-ROI)
% =====================================================================

% =====================================================================
% BLOCK 1: Computation — run once, takes a while
% =====================================================================
clear all; close all; clc;

% --- Configuration ---
topN      = 500;
preStim   = 12;
postStim  = 24;
epochLen  = preStim + postStim;
TR        = 1;
smoothWin = 3;
nSessions = 3;
nRuns     = 5;
finger    = 'sixth';
fingerCol = 6;

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
addpath(fullfile(fileparts(mfilename('fullpath')), 'helpers'));
if exist(fullfile(fsHome, 'matlab'), 'dir')
    addpath(genpath(fullfile(fsHome, 'matlab')));
end

mapData    = jsondecode(fileread(fullfile(codeDir, 'map.json')));
subjects   = mapData.subjects;
sesNames   = {mapData.sessionDirs.session};
dmDirNames = {mapData.sessionDirs.dmDir};
nSubjects  = numel(subjects);

imgBaseDir = fullfile(bidsDir, 'derivatives', 'Imagery_native');
fsSubBase  = fullfile(bidsDir, 'derivatives', 'freesurfer');
saveDir    = fullfile(bidsDir, 'derivatives', 'timeseries');
if ~exist(saveDir, 'dir'), mkdir(saveDir); end

% --- Sub-ROI definitions ---
roiDefs(1).name   = 'M1 (area 4)';   roiDefs(1).labels = {'4'};
roiDefs(2).name   = 'S1-3a';         roiDefs(2).labels = {'3a'};
roiDefs(3).name   = 'S1-3b';         roiDefs(3).labels = {'3b'};
roiDefs(4).name   = 'S1-1';          roiDefs(4).labels = {'1'};
roiDefs(5).name   = 'S1-2';          roiDefs(5).labels = {'2'};
nROIdefs = numel(roiDefs);

% --- Plot settings (shared) ---
cBlue  = [0.2  0.4  0.8];
cRed   = [0.85 0.2  0.2];
cGreen = [0.1  0.65 0.3];
lineColors = {cBlue, cRed, cRed, cGreen, cGreen};
lineStyles = {'-', '-', '--', '-', '--'};

% =====================================================================
% Main loop: subjects → sessions → runs (BOLD loaded once per run)
% =====================================================================
% Pre-allocate groupLines for all sub-ROIs
allGroupLines = cell(nROIdefs, 1);
for iROI = 1:nROIdefs
    allGroupLines{iROI} = NaN(nSubjects, 5, epochLen);
end

for iSub = 1:nSubjects

    subID    = subjects(iSub).subID;
    dmNum    = subjects(iSub).dmNum;
    sessions = subjects(iSub).sessions;

    fprintf('\nSubject: %s\n', subID);

    fsSubDir   = fullfile(fsSubBase, subID);
    glasserDir = fullfile(fsSubDir, 'label', 'Glasser2016');
    imgDir     = fullfile(imgBaseDir, subID);

    if ~exist(fsSubDir, 'dir') || ~exist(glasserDir, 'dir')
        fprintf('  SKIPPING: FreeSurfer dir not found\n');
        continue;
    end

    % --- Build mask index for each sub-ROI ---
    lcurv   = read_curv(fullfile(fsSubDir, 'surf', 'lh.curv'));
    rcurv   = read_curv(fullfile(fsSubDir, 'surf', 'rh.curv'));
    nVertsL = numel(lcurv);
    nVertsR = numel(rcurv);

    maskIdxAll = cell(nROIdefs, 1);
    for iROI = 1:nROIdefs
        lh_mask = false(nVertsL, 1);
        rh_mask = false(nVertsR, 1);
        for lb = roiDefs(iROI).labels
            lf = fullfile(glasserDir, ['lh.' lb{1} '.label']);
            if exist(lf, 'file')
                ld = read_label('', lf); lh_mask(ld(:,1)+1) = true;
            end
            rf = fullfile(glasserDir, ['rh.' lb{1} '.label']);
            if exist(rf, 'file')
                rd = read_label('', rf); rh_mask(rd(:,1)+1) = true;
            end
        end
        maskIdxAll{iROI} = find([lh_mask; rh_mask]);
        fprintf('  %s: %d vertices\n', roiDefs(iROI).name, numel(maskIdxAll{iROI}));
    end

    % --- Load betas for all sub-ROIs ---
    beta_all = cell(nROIdefs, 1);
    for iROI = 1:nROIdefs
        beta_all{iROI} = NaN(numel(maskIdxAll{iROI}), nSessions);
    end
    for iSes = 1:nSessions
        ses   = sprintf('ses-%02d', iSes);
        lhBet = fullfile(imgDir, ses, sprintf('lh.%s_%d.mgz', finger, iSes));
        rhBet = fullfile(imgDir, ses, sprintf('rh.%s_%d.mgz', finger, iSes));
        lhBetInfo = dir(lhBet); rhBetInfo = dir(rhBet);
        if ~isempty(lhBetInfo) && ~isempty(rhBetInfo) && lhBetInfo.bytes > 1e4 && rhBetInfo.bytes > 1e4
            lhB = MRIread(lhBet); rhB = MRIread(rhBet);
            b   = [squeeze(lhB.vol); squeeze(rhB.vol)];
            for iROI = 1:nROIdefs
                beta_all{iROI}(:, iSes) = b(maskIdxAll{iROI});
            end
        end
    end

    % --- Accumulate epochs per sub-ROI per session ---
    sumEpochAll = cell(nROIdefs, nSessions);
    nEpochsAll  = zeros(nROIdefs, nSessions);
    for iROI = 1:nROIdefs
        for iSes = 1:nSessions
            sumEpochAll{iROI, iSes} = zeros(numel(maskIdxAll{iROI}), epochLen);
        end
    end

    for iSes = 1:nSessions
        ses    = sprintf('ses-%02d', iSes);
        sesIdx = find(strcmp(sesNames, ses), 1);
        if isempty(sesIdx) || ~ismember(ses, sessions), continue; end

        dmBaseDir = fullfile(codeDir, dmDirNames{sesIdx});
        logDir    = fullfile(dmBaseDir, num2str(dmNum), 'Results');

        allDmFiles = dir(fullfile(logDir, sprintf('sixFingers1_MI_%d_*_dm.csv', dmNum)));
        if isempty(allDmFiles)
            fprintf('  No DM files for %s %s\n', subID, ses);
            continue;
        end
        [~, sortIdx] = sort({allDmFiles.name});
        allDmFiles   = allDmFiles(sortIdx);

        for iRun = 1:min(nRuns, numel(allDmFiles))

            funcDir = fullfile(bidsDir, 'derivatives', 'fmriprep', subID, ses, 'func');
            lhFile  = fullfile(funcDir, sprintf('%s_%s_task-Imagery_run-%02d_hemi-L_space-fsnative_bold.func.mgh', subID, ses, iRun));
            rhFile  = fullfile(funcDir, sprintf('%s_%s_task-Imagery_run-%02d_hemi-R_space-fsnative_bold.func.mgh', subID, ses, iRun));

            lhInfo = dir(lhFile); rhInfo = dir(rhFile);
            if isempty(lhInfo) || isempty(rhInfo) || lhInfo.bytes < 1e6 || rhInfo.bytes < 1e6
                fprintf('  Skipping run %d %s: file missing or not downloaded\n', iRun, ses);
                continue;
            end

            % Load BOLD once — shared across all sub-ROIs
            lhMGZ   = MRIread(lhFile);
            rhMGZ   = MRIread(rhFile);
            boldAll = [squeeze(lhMGZ.vol); squeeze(rhMGZ.vol)];
            nTRs    = size(boldAll, 2);
            clear lhMGZ rhMGZ;

            % Load confounds once
            confFile = fullfile(bidsDir, 'derivatives', 'fmriprep', subID, ses, 'func', ...
                sprintf('%s_%s_task-Imagery_run-%02d_desc-confounds_timeseries.tsv', subID, ses, iRun));
            X_noise = [];
            if exist(confFile, 'file')
                conf     = readtable(confFile, 'FileType', 'text', 'Delimiter', '\t');
                confCols = {'trans_x','trans_y','trans_z','rot_x','rot_y','rot_z', ...
                            'global_signal','white_matter','csf'};
                available = confCols(ismember(confCols, conf.Properties.VariableNames));
                if ~isempty(available)
                    confData = table2array(conf(:, available));
                    confData(isnan(confData)) = 0;
                    X_noise = [ones(nTRs,1), (1:nTRs)', confData];
                end
            end

            % Load DM for epoch onsets
            dm = readmatrix(fullfile(logDir, allDmFiles(iRun).name));
            if isnan(dm(1,1)), dm = dm(2:end,:); end
            onsets = find(diff([0; dm(:, fingerCol)]) == 1);

            % Per sub-ROI: extract vertices, PSC, regress, epoch
            for iROI = 1:nROIdefs
                maskIdx = maskIdxAll{iROI};
                bold    = boldAll(maskIdx, :);
                runMean = mean(bold, 2);
                runMean(abs(runMean) < 1e-6) = 1e-6;
                psc = ((bold ./ runMean) - 1) * 100;

                if ~isempty(X_noise)
                    psc = psc - (X_noise * (X_noise \ psc'))';
                end

                for iOnset = 1:numel(onsets)
                    onset      = onsets(iOnset);
                    epochStart = onset - preStim;
                    epochEnd   = onset + postStim - 1;
                    if epochStart < 1 || epochEnd > nTRs, continue; end
                    baseline = mean(psc(:, epochStart:onset-1), 2);
                    epoch    = psc(:, epochStart:epochEnd) - baseline;
                    sumEpochAll{iROI, iSes} = sumEpochAll{iROI, iSes} + epoch;
                    nEpochsAll(iROI, iSes)  = nEpochsAll(iROI, iSes) + 1;
                end
            end

        end % runs

        fprintf('  %s: %d epochs\n', ses, nEpochsAll(1, iSes));

    end % sessions

    % --- Compute STA and 5 lines per sub-ROI ---
    for iROI = 1:nROIdefs
        maskIdx = maskIdxAll{iROI};
        nV      = numel(maskIdx);
        topNsub = min(topN, nV);

        sta   = NaN(nV, epochLen, nSessions);
        sesOK = false(1, nSessions);
        for iSes = 1:nSessions
            if nEpochsAll(iROI, iSes) > 0
                sta(:, :, iSes) = sumEpochAll{iROI, iSes} / nEpochsAll(iROI, iSes);
                sesOK(iSes)     = true;
            end
        end

        tops = cell(nSessions, 1);
        for iSes = 1:nSessions
            betas = beta_all{iROI}(:, iSes);
            if ~any(isnan(betas))
                [~, r]     = sort(betas, 'descend');
                tops{iSes} = r(1:topNsub);
            end
        end

        lines = NaN(5, epochLen);
        if sesOK(1) && ~isempty(tops{1}),                     lines(1,:) = mean(sta(tops{1},:,1), 1); end
        if sesOK(2) && ~isempty(tops{2}),                     lines(2,:) = mean(sta(tops{2},:,2), 1); end
        if sesOK(1) && sesOK(2) && ~isempty(tops{2}),         lines(3,:) = mean(sta(tops{2},:,1), 1); end
        if sesOK(3) && ~isempty(tops{3}),                     lines(4,:) = mean(sta(tops{3},:,3), 1); end
        if sesOK(2) && sesOK(3) && ~isempty(tops{2}),         lines(5,:) = mean(sta(tops{2},:,3), 1); end

        allGroupLines{iROI}(iSub, :, :) = lines;
    end

end % subjects

% --- Save one .mat per sub-ROI ---
for iROI = 1:nROIdefs
    roiName    = roiDefs(iROI).name;
    groupLines = allGroupLines{iROI};
    groupMean  = squeeze(nanmean(groupLines, 1));
    nContrib   = squeeze(sum(~isnan(groupLines(:,:,1)), 1));

    lineNames = { ...
        sprintf('top%d ses-01 @ ses-01  (baseline)',           topN), ...
        sprintf('top%d ses-02 @ ses-02  (new representation)', topN), ...
        sprintf('top%d ses-02 @ ses-01  (already there?)',     topN), ...
        sprintf('top%d ses-03 @ ses-03  (consolidation?)',     topN), ...
        sprintf('top%d ses-02 @ ses-03  (persisted/grew?)',    topN)};

    matFile = fullfile(saveDir, sprintf('group_timeseries_%s.mat', strrep(roiName, ' ', '_')));
    save(matFile, 'groupLines', 'groupMean', 'nContrib', 'subjects', 'roiName', ...
        'topN', 'preStim', 'postStim', 'TR', 'smoothWin', ...
        'lineNames', 'lineColors', 'lineStyles');
    fprintf('Saved: %s\n', matFile);
end

fprintf('\n=== Done! ===\n');
%%
% =====================================================================
% BLOCK 2: Group subplot figure — one panel per sub-ROI
% Run independently with F9 after Block 1 has completed.
% =====================================================================
[~, currentUser] = system('whoami');
currentUser = strtrim(currentUser);
if strcmp(currentUser, 'pw1246')
    bidsDir = '/Users/pw1246/Library/CloudStorage/Box-Box/sixthfinger-test';
else
    bidsDir = '/Users/hha243/Library/CloudStorage/Box-Box/sixthfinger-test';
end

saveDir  = fullfile(bidsDir, 'derivatives', 'timeseries');
roiNames = {'M1_(area_4)', 'S1-3a', 'S1-3b', 'S1-1', 'S1-2'};
roiTitles = {'M1 (area 4)', 'S1 — 3a', 'S1 — 3b', 'S1 — 1', 'S1 — 2'};
nROIdefs = numel(roiNames);

cBlue  = [0.2  0.4  0.8];
cRed   = [0.85 0.2  0.2];
cGreen = [0.1  0.65 0.3];
lineColors = {cBlue, cRed, cRed, cGreen, cGreen};
lineStyles = {'-', '-', '--', '-', '--'};

figure('Position', [50 100 1800 420]);

for iROI = 1:nROIdefs
    matFile = fullfile(saveDir, sprintf('group_timeseries_%s.mat', roiNames{iROI}));
    if ~exist(matFile, 'file')
        fprintf('Missing: %s — run Block 1 first\n', matFile);
        continue;
    end
    load(matFile);  % groupMean, nContrib, preStim, postStim, TR, smoothWin

    if smoothWin > 0
        for iLine = 1:5
            if ~all(isnan(groupMean(iLine,:)))
                groupMean(iLine,:) = smoothdata(groupMean(iLine,:), 'gaussian', smoothWin);
            end
        end
    end

    tAxis   = (-preStim : TR : postStim-1);
    allVals = groupMean(~isnan(groupMean));

    subplot(2,3, iROI);
    hold on;

    if isempty(allVals)
        title(roiTitles{iROI}); hold off; continue;
    end

    ypad  = 0.2 * (max(allVals) - min(allVals) + 0.01);
    ylims = [min(allVals)-ypad, max(allVals)+ypad];

    fill([0 12 12 0], [ylims(1) ylims(1) ylims(2) ylims(2)], ...
         [1 0.95 0.8], 'EdgeColor', 'none', 'HandleVisibility', 'off');
    xline(0,  '-k', 'Alpha', 0.4, 'HandleVisibility', 'off');
    xline(12, '-k', 'Alpha', 0.4, 'HandleVisibility', 'off');
    yline(0,  '--k', 'Alpha', 0.25, 'HandleVisibility', 'off');

    for iLine = 1:5
        if ~all(isnan(groupMean(iLine,:)))
            plot(tAxis, groupMean(iLine,:), lineStyles{iLine}, ...
                'Color', lineColors{iLine}, 'LineWidth', 2, ...
                'DisplayName', sprintf('line %d  (n=%d)', iLine, nContrib(iLine)));
        end
    end

    xlim([tAxis(1) tAxis(end)]); ylim(ylims);
    title(roiTitles{iROI}, 'FontSize', 13);
    xlabel('Time (s)');
    if iROI == 1, ylabel('% Signal Change'); end
    grid on; box on;
    hold off;
end

sgtitle('Group STA — sixth finger imagery | BA1-4 sub-ROIs', 'FontSize', 15, 'FontWeight', 'bold');
set(findall(gcf, '-property', 'FontSize'), 'FontSize', 12);

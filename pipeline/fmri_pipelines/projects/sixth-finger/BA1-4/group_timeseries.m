% =====================================================================
% group_timeseries.m
% Group-level STA for sixth finger across ses-01, ses-02, ses-03.
% ROI: BA1-4 (Glasser2016 labels: 4, 3a, 3b, 1, 2), native space.
% Data loaded from: derivatives/Imagery_native
%
% Lines plotted:
%   1. top ses-01 @ ses-01  — baseline
%   2. top ses-02 @ ses-02  — new representation at ses-02
%   3. top ses-02 @ ses-01  — were those vertices already responding at ses-01?
%   4. top ses-03 @ ses-03  — consolidation by ses-03?
%   5. top ses-02 @ ses-03  — did the ses-02 representation persist/grow?
%
% Sessions 1-3 averaged across subjects; subjects missing a session
% are excluded from that session's lines via nanmean.
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
nRuns     = 5;       % Imagery runs per session
finger    = 'sixth';
fingerCol = 6;       % DM column for sixth finger

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

% --- ROI definition ---
roiDefs(1).name   = 'BA1-4';
roiDefs(1).labels = {'4', '3a', '3b', '1', '2'};

% --- Plot settings ---
lineNames = { ...
    sprintf('top%d ses-01 @ ses-01  (baseline)',           topN), ...
    sprintf('top%d ses-02 @ ses-02  (new representation)', topN), ...
    sprintf('top%d ses-02 @ ses-01  (already there?)',     topN), ...
    sprintf('top%d ses-03 @ ses-03  (consolidation?)',     topN), ...
    sprintf('top%d ses-02 @ ses-03  (persisted/grew?)',    topN)};

cBlue  = [0.2  0.4  0.8];
cRed   = [0.85 0.2  0.2];
cGreen = [0.1  0.65 0.3];
lineColors = {cBlue, cRed, cRed, cGreen, cGreen};
lineStyles = {'-', '-', '--', '-', '--'};

% =====================================================================
% Main loop over ROIs
% =====================================================================
for iROI = 1:numel(roiDefs)

    roiName   = roiDefs(iROI).name;
    roiLabels = roiDefs(iROI).labels;

    fprintf('\n=== ROI: %s ===\n', roiName);

    % groupLines: [nSubjects x 5lines x epochLen], NaN = missing/failed
    groupLines = NaN(nSubjects, 5, epochLen);

    % ------------------------------------------------------------------
    for iSub = 1:nSubjects

        subID    = subjects(iSub).subID;
        dmNum    = subjects(iSub).dmNum;
        sessions = subjects(iSub).sessions;

        fprintf('  Subject: %s\n', subID);

        fsSubDir   = fullfile(fsSubBase, subID);
        glasserDir = fullfile(fsSubDir, 'label', 'Glasser2016');
        imgDir     = fullfile(imgBaseDir, subID);

        if ~exist(fsSubDir, 'dir') || ~exist(glasserDir, 'dir')
            fprintf('    SKIPPING: FreeSurfer dir not found\n');
            continue;
        end

        % --- Build native-space ROI mask ---
        lcurv   = read_curv(fullfile(fsSubDir, 'surf', 'lh.curv'));
        rcurv   = read_curv(fullfile(fsSubDir, 'surf', 'rh.curv'));
        nVertsL = numel(lcurv);
        nVertsR = numel(rcurv);
        leftidx  = 1:nVertsL;
        rightidx = (1:nVertsR) + nVertsL;

        lh_mask = false(nVertsL, 1);
        rh_mask = false(nVertsR, 1);
        for i = 1:numel(roiLabels)
            lfile = fullfile(glasserDir, ['lh.' roiLabels{i} '.label']);
            if exist(lfile, 'file')
                ld = read_label('', lfile);
                lh_mask(ld(:,1)+1) = true;
            end
            rfile = fullfile(glasserDir, ['rh.' roiLabels{i} '.label']);
            if exist(rfile, 'file')
                rd = read_label('', rfile);
                rh_mask(rd(:,1)+1) = true;
            end
        end
        all_mask = [lh_mask; rh_mask];
        maskIdx  = find(all_mask);
        nROI     = numel(maskIdx);

        if nROI < 10
            fprintf('    SKIPPING: too few ROI vertices (%d)\n', nROI);
            continue;
        end

        topNsub = min(topN, nROI);
        fprintf('    ROI vertices: %d  |  topN used: %d\n', nROI, topNsub);

        % --- Load betas for ranking (ses-01, ses-02, ses-03) ---
        beta_roi = NaN(nROI, nSessions);
        for iSes = 1:nSessions
            ses   = sprintf('ses-%02d', iSes);
            lhBet = fullfile(imgDir, ses, sprintf('lh.%s_%d.mgz', finger, iSes));
            rhBet = fullfile(imgDir, ses, sprintf('rh.%s_%d.mgz', finger, iSes));
            if exist(lhBet, 'file') && exist(rhBet, 'file')
                lhB = MRIread(lhBet);
                rhB = MRIread(rhBet);
                b   = [squeeze(lhB.vol); squeeze(rhB.vol)];
                beta_roi(:, iSes) = b(maskIdx);
            end
        end

        % --- Load BOLD and compute STA per session ---
        sta    = NaN(nROI, epochLen, nSessions);
        sesOK  = false(1, nSessions);   % true if >= 1 epoch found

        for iSes = 1:nSessions
            ses    = sprintf('ses-%02d', iSes);
            sesIdx = find(strcmp(sesNames, ses), 1);
            if isempty(sesIdx) || ~ismember(ses, sessions)
                continue;
            end
            dmBaseDir = fullfile(codeDir, dmDirNames{sesIdx});
            logDir    = fullfile(dmBaseDir, num2str(dmNum), 'Results');

            sumEpoch = zeros(nROI, epochLen);
            nEpochs  = 0;

            % Find and sort DM files for this subject/session
            allDmFiles = dir(fullfile(logDir, sprintf('sixFingers1_MI_%d_*_dm.csv', dmNum)));
            if isempty(allDmFiles)
                fprintf('    No DM files found for %s %s\n', subID, ses);
                continue;
            end
            [~, sortIdx] = sort({allDmFiles.name});
            allDmFiles   = allDmFiles(sortIdx);

            for iRun = 1:min(nRuns, numel(allDmFiles))

                funcDir = fullfile(bidsDir, 'derivatives', 'fmriprep', subID, ses, 'func');
                lhFile  = fullfile(funcDir, sprintf('%s_%s_task-Imagery_run-%02d_hemi-L_space-fsnative_bold.func.mgh', subID, ses, iRun));
                rhFile  = fullfile(funcDir, sprintf('%s_%s_task-Imagery_run-%02d_hemi-R_space-fsnative_bold.func.mgh', subID, ses, iRun));

                if ~exist(lhFile, 'file') || ~exist(rhFile, 'file')
                    continue;
                end

                lhMGZ   = MRIread(lhFile);
                rhMGZ   = MRIread(rhFile);
                boldAll = [squeeze(lhMGZ.vol); squeeze(rhMGZ.vol)];
                bold    = boldAll(maskIdx, :);
                nTRs    = size(bold, 2);

                % Convert to PSC
                runMean = mean(bold, 2);
                runMean(abs(runMean) < 1e-6) = 1e-6;
                psc = ((bold ./ runMean) - 1) * 100;

                % Noise regression
                confFile = fullfile(bidsDir, 'derivatives', 'fmriprep', subID, ses, 'func', ...
                    sprintf('%s_%s_task-Imagery_run-%02d_desc-confounds_timeseries.tsv', subID, ses, iRun));
                if exist(confFile, 'file')
                    conf     = readtable(confFile, 'FileType', 'text', 'Delimiter', '\t');
                    confCols = {'trans_x','trans_y','trans_z','rot_x','rot_y','rot_z', ...
                                'global_signal','white_matter','csf'};
                    % Only use columns that exist
                    available = confCols(ismember(confCols, conf.Properties.VariableNames));
                    if ~isempty(available)
                        confData = table2array(conf(:, available));
                        confData(isnan(confData)) = 0;
                        X_noise = [ones(nTRs,1), (1:nTRs)', confData];
                        psc = psc - (X_noise * (X_noise \ psc'))';
                    end
                end

                % Load DM and extract sixth-finger epochs
                dm = readmatrix(fullfile(logDir, allDmFiles(iRun).name));
                if isnan(dm(1,1)), dm = dm(2:end,:); end

                onsets = find(diff([0; dm(:, fingerCol)]) == 1);
                for iOnset = 1:numel(onsets)
                    onset      = onsets(iOnset);
                    epochStart = onset - preStim;
                    epochEnd   = onset + postStim - 1;
                    if epochStart < 1 || epochEnd > nTRs, continue; end
                    baseline = mean(psc(:, epochStart:onset-1), 2);
                    epoch    = psc(:, epochStart:epochEnd) - baseline;
                    sumEpoch = sumEpoch + epoch;
                    nEpochs  = nEpochs + 1;
                end

            end % runs

            if nEpochs > 0
                sta(:, :, iSes) = sumEpoch / nEpochs;
                sesOK(iSes)     = true;
            end
            fprintf('    %s: %d epochs\n', ses, nEpochs);

        end % sessions

        % --- Rank top-N vertices per session (using betas) ---
        tops = cell(nSessions, 1);
        for iSes = 1:nSessions
            if ~any(isnan(beta_roi(:, iSes)))
                [~, r]     = sort(beta_roi(:, iSes), 'descend');
                tops{iSes} = r(1:topNsub);
            end
        end

        % --- Compute 5 mean timeseries for this subject ---
        lines = NaN(5, epochLen);

        % 1: top ses-01 @ ses-01
        if sesOK(1) && ~isempty(tops{1})
            lines(1,:) = mean(sta(tops{1}, :, 1), 1);
        end
        % 2: top ses-02 @ ses-02
        if sesOK(2) && ~isempty(tops{2})
            lines(2,:) = mean(sta(tops{2}, :, 2), 1);
        end
        % 3: top ses-02 @ ses-01
        if sesOK(1) && sesOK(2) && ~isempty(tops{2})
            lines(3,:) = mean(sta(tops{2}, :, 1), 1);
        end
        % 4: top ses-03 @ ses-03
        if sesOK(3) && ~isempty(tops{3})
            lines(4,:) = mean(sta(tops{3}, :, 3), 1);
        end
        % 5: top ses-02 @ ses-03
        if sesOK(2) && sesOK(3) && ~isempty(tops{2})
            lines(5,:) = mean(sta(tops{2}, :, 3), 1);
        end

        groupLines(iSub, :, :) = lines;

    end % subjects

    % ------------------------------------------------------------------
    % Group average (nanmean ignores missing subjects per line/timepoint)
    % ------------------------------------------------------------------
    groupMean = squeeze(nanmean(groupLines, 1));  % [5 x epochLen]
    nContrib  = squeeze(sum(~isnan(groupLines(:,:,1)), 1));  % [5 x 1]

    if smoothWin > 0
        for iLine = 1:5
            if ~all(isnan(groupMean(iLine,:)))
                groupMean(iLine,:) = smoothdata(groupMean(iLine,:), 'gaussian', smoothWin);
            end
        end
    end

    % ------------------------------------------------------------------
    % Save all data for offline plotting (Blocks 2 and 3)
    % ------------------------------------------------------------------
    saveDir = fullfile(bidsDir, 'derivatives', 'timeseries');
    if ~exist(saveDir, 'dir'), mkdir(saveDir); end
    matFile = fullfile(saveDir, sprintf('group_timeseries_%s.mat', roiName));
    save(matFile, 'groupLines', 'groupMean', 'nContrib', 'subjects', 'roiName', ...
        'topN', 'preStim', 'postStim', 'TR', 'smoothWin', ...
        'lineNames', 'lineColors', 'lineStyles');
    fprintf('  Saved data: %s\n', matFile);

    % ------------------------------------------------------------------
    % Plot
    % ------------------------------------------------------------------
    tAxis   = (-preStim : TR : postStim-1);
    allVals = groupMean(~isnan(groupMean));

    if isempty(allVals)
        fprintf('  No data to plot for %s\n', roiName);
        continue;
    end

    ypad  = 0.2 * (max(allVals) - min(allVals) + 0.01);
    ylims = [min(allVals)-ypad, max(allVals)+ypad];

    figure('Position', [100 100 900 550]);
    hold on;

    % Shade stimulus window
    fill([0 12 12 0], [ylims(1) ylims(1) ylims(2) ylims(2)], ...
         [1 0.95 0.8], 'EdgeColor', 'none', 'HandleVisibility', 'off');
    xline(0,  '-k', 'Alpha', 0.4, 'HandleVisibility', 'off');
    xline(12, '-k', 'Alpha', 0.4, 'HandleVisibility', 'off');

    for iLine = 1:5
        if ~all(isnan(groupMean(iLine,:)))
            plot(tAxis, groupMean(iLine,:), lineStyles{iLine}, ...
                'Color', lineColors{iLine}, 'LineWidth', 2.5, ...
                'DisplayName', sprintf('%s  (n=%d)', lineNames{iLine}, nContrib(iLine)));
        end
    end

    yline(0, '--k', 'Alpha', 0.25, 'HandleVisibility', 'off');
    xlim([tAxis(1) tAxis(end)]); ylim(ylims);
    xlabel('Time from stimulus onset (s)'); ylabel('% Signal Change');
    title(sprintf('Group — Imagery STA: sixth finger | %s (Glasser2016)', roiName));
    legend('Location', 'northeast'); grid on; box on;
    hold off;
    set(findall(gcf, '-property', 'FontSize'), 'FontSize', 15);

    fprintf('  %s: subjects contributing per line: %s\n', roiName, num2str(nContrib'));

end % ROIs

fprintf('\n=== Done! ===\n');
%%
% =====================================================================
% BLOCK 3: Re-plot group average — run independently with F9
% Loads pre-saved .mat and re-plots the group figure without recomputing.
% =====================================================================
roiName = 'BA1-4';

[~, currentUser] = system('whoami');
currentUser = strtrim(currentUser);
if strcmp(currentUser, 'pw1246')
    bidsDir = '/Users/pw1246/Library/CloudStorage/Box-Box/sixthfinger-test';
else
    bidsDir = '/Users/hha243/Library/CloudStorage/Box-Box/sixthfinger-test';
end

matFile = fullfile(bidsDir, 'derivatives', 'timeseries', ...
    sprintf('group_timeseries_%s.mat', roiName));
load(matFile);  % loads: groupMean, nContrib, lineNames, lineColors, lineStyles,
                %        preStim, postStim, TR

tAxis   = (-preStim : TR : postStim-1);
allVals = groupMean(~isnan(groupMean));

if isempty(allVals)
    fprintf('  No data to plot for %s\n', roiName);
else

ypad  = 0.2 * (max(allVals) - min(allVals) + 0.01);
ylims = [min(allVals)-ypad, max(allVals)+ypad];

figure('Position', [100 100 900 550]);
hold on;
fill([0 12 12 0], [ylims(1) ylims(1) ylims(2) ylims(2)], ...
     [1 0.95 0.8], 'EdgeColor', 'none', 'HandleVisibility', 'off');
xline(0,  '-k', 'Alpha', 0.4, 'HandleVisibility', 'off');
xline(12, '-k', 'Alpha', 0.4, 'HandleVisibility', 'off');

for iLine = 1:5
    if ~all(isnan(groupMean(iLine,:)))
        plot(tAxis, groupMean(iLine,:), lineStyles{iLine}, ...
            'Color', lineColors{iLine}, 'LineWidth', 2.5, ...
            'DisplayName', sprintf('%s  (n=%d)', lineNames{iLine}, nContrib(iLine)));
    end
end

yline(0, '--k', 'Alpha', 0.25, 'HandleVisibility', 'off');
xlim([tAxis(1) tAxis(end)]); ylim(ylims);
xlabel('Time from stimulus onset (s)'); ylabel('% Signal Change');
title(sprintf('Group — Imagery STA: sixth finger | %s (Glasser2016)', roiName));
legend('Location', 'northeast'); grid on; box on;
hold off;
set(findall(gcf, '-property', 'FontSize'), 'FontSize', 15);

end % isempty(allVals)
%% 
% =====================================================================
% BLOCK 2: Plot individual subject — run independently with F9
% Loads pre-saved .mat (produced by Block 1 above) and plots one
% subject's 5 timeseries. Change subjectToPlot as needed.
% =====================================================================
subjectToPlot = 'sub-0457';
roiName       = 'BA1-4';

[~, currentUser] = system('whoami');
currentUser = strtrim(currentUser);
if strcmp(currentUser, 'pw1246')
    bidsDir = '/Users/pw1246/Library/CloudStorage/Box-Box/sixthfinger-test';
else
    bidsDir = '/Users/hha243/Library/CloudStorage/Box-Box/sixthfinger-test';
end

matFile = fullfile(bidsDir, 'derivatives', 'timeseries', ...
    sprintf('group_timeseries_%s.mat', roiName));
load(matFile);  % loads: groupLines, subjects, roiName, topN, preStim,
                %        postStim, TR, smoothWin, lineNames, lineColors, lineStyles

iSub = find(strcmp({subjects.subID}, subjectToPlot));
if isempty(iSub)
    error('Subject %s not found in saved data.', subjectToPlot);
end

subLines = squeeze(groupLines(iSub, :, :));  % [5 x epochLen]

if smoothWin > 0
    for iLine = 1:5
        if ~all(isnan(subLines(iLine,:)))
            subLines(iLine,:) = smoothdata(subLines(iLine,:), 'gaussian', smoothWin);
        end
    end
end

tAxis   = (-preStim : TR : postStim-1);
allVals = subLines(~isnan(subLines));

if isempty(allVals)
    fprintf('No data for subject %s\n', subjectToPlot);
else
    ypad  = 0.2 * (max(allVals) - min(allVals) + 0.01);
    ylims = [min(allVals)-ypad, max(allVals)+ypad];

    figure('Position', [100 100 900 550]);
    hold on;
    fill([0 12 12 0], [ylims(1) ylims(1) ylims(2) ylims(2)], ...
         [1 0.95 0.8], 'EdgeColor', 'none', 'HandleVisibility', 'off');
    xline(0,  '-k', 'Alpha', 0.4, 'HandleVisibility', 'off');
    xline(12, '-k', 'Alpha', 0.4, 'HandleVisibility', 'off');

    for iLine = 1:5
        if ~all(isnan(subLines(iLine,:)))
            plot(tAxis, subLines(iLine,:), lineStyles{iLine}, ...
                'Color', lineColors{iLine}, 'LineWidth', 2.5, ...
                'DisplayName', lineNames{iLine});
        end
    end

    yline(0, '--k', 'Alpha', 0.25, 'HandleVisibility', 'off');
    xlim([tAxis(1) tAxis(end)]); ylim(ylims);
    xlabel('Time from stimulus onset (s)'); ylabel('% Signal Change');
    title(sprintf('%s — Imagery STA: sixth finger | %s (Glasser2016)', subjectToPlot, roiName));
    legend('Location', 'northeast'); grid on; box on;
    hold off;
    set(findall(gcf, '-property', 'FontSize'), 'FontSize', 15);
end
%% 
% =====================================================================
% BLOCK 4: Before vs after training — all subjects + group mean
% Single plot: ses-01@ses-01 (blue), ses-02@ses-02 (red), ses-03@ses-03 (green),
% thin lines per subject, thick lines for group mean.
% Run independently with F9.
% =====================================================================
roiName = 'BA1-4';

[~, currentUser] = system('whoami');
currentUser = strtrim(currentUser);
if strcmp(currentUser, 'pw1246')
    bidsDir = '/Users/pw1246/Library/CloudStorage/Box-Box/sixthfinger-test';
else
    bidsDir = '/Users/hha243/Library/CloudStorage/Box-Box/sixthfinger-test';
end

matFile = fullfile(bidsDir, 'derivatives', 'timeseries', ...
    sprintf('group_timeseries_%s.mat', roiName));
load(matFile);

tAxis = (-preStim : TR : postStim-1);

cBlue  = [0.2  0.4  0.8];
cRed   = [0.85 0.2  0.2];
cGreen = [0.1  0.65 0.3];

% groupLines: [nSubjects x 5 x epochLen]
% line 1 = ses-01@ses-01, line 2 = ses-02@ses-02, line 4 = ses-03@ses-03
pre   = squeeze(groupLines(:, 1, :));
post  = squeeze(groupLines(:, 2, :));
post2 = squeeze(groupLines(:, 4, :));

if smoothWin > 0
    for iS = 1:size(pre, 1)
        if ~all(isnan(pre(iS,:))),   pre(iS,:)   = smoothdata(pre(iS,:),   'gaussian', smoothWin); end
        if ~all(isnan(post(iS,:))),  post(iS,:)  = smoothdata(post(iS,:),  'gaussian', smoothWin); end
        if ~all(isnan(post2(iS,:))), post2(iS,:) = smoothdata(post2(iS,:), 'gaussian', smoothWin); end
    end
end

meanPre   = nanmean(pre,   1);
meanPost  = nanmean(post,  1);
meanPost2 = nanmean(post2, 1);

allVals = [pre(~isnan(pre)); post(~isnan(post)); post2(~isnan(post2))];
if isempty(allVals)
    fprintf('  No data to plot for Block 4\n');
else
    ypad  = 0.2 * (max(allVals) - min(allVals) + 0.01);
    ylims = [min(allVals)-ypad, max(allVals)+ypad];

    figure('Position', [100 100 900 550]);
    hold on;

    fill([0 12 12 0], [ylims(1) ylims(1) ylims(2) ylims(2)], ...
         [1 0.95 0.8], 'EdgeColor', 'none', 'HandleVisibility', 'off');
    xline(0,  '-k', 'Alpha', 0.4, 'HandleVisibility', 'off');
    xline(12, '-k', 'Alpha', 0.4, 'HandleVisibility', 'off');

    for iS = 1:size(pre, 1)
        if ~all(isnan(pre(iS,:)))
            plot(tAxis, pre(iS,:),   '-', 'Color', [cBlue  0.25], 'LineWidth', 0.8, 'HandleVisibility', 'off');
        end
        if ~all(isnan(post(iS,:)))
            plot(tAxis, post(iS,:),  '-', 'Color', [cRed   0.25], 'LineWidth', 0.8, 'HandleVisibility', 'off');
        end
        if ~all(isnan(post2(iS,:)))
            plot(tAxis, post2(iS,:), '-', 'Color', [cGreen 0.25], 'LineWidth', 0.8, 'HandleVisibility', 'off');
        end
    end

    nPre   = sum(~all(isnan(pre),   2));
    nPost  = sum(~all(isnan(post),  2));
    nPost2 = sum(~all(isnan(post2), 2));
    plot(tAxis, meanPre,   '-', 'Color', cBlue,  'LineWidth', 3, ...
         'DisplayName', sprintf('ses-01 @ ses-01  (n=%d)', nPre));
    plot(tAxis, meanPost,  '-', 'Color', cRed,   'LineWidth', 3, ...
         'DisplayName', sprintf('ses-02 @ ses-02  (n=%d)', nPost));
    plot(tAxis, meanPost2, '-', 'Color', cGreen, 'LineWidth', 3, ...
         'DisplayName', sprintf('ses-03 @ ses-03  (n=%d)', nPost2));

    yline(0, '--k', 'Alpha', 0.25, 'HandleVisibility', 'off');
    xlim([tAxis(1) tAxis(end)]); ylim(ylims);
    xlabel('Time from stimulus onset (s)'); ylabel('% Signal Change');
    title(sprintf('Group — Before vs After Training: sixth finger | %s (Glasser2016)', roiName));
    legend('Location', 'northeast'); grid on; box on;
    hold off;
    set(findall(gcf, '-property', 'FontSize'), 'FontSize', 15);
end

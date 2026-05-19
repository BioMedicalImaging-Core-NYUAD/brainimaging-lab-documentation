% =====================================================================
% plot_mds.m  —  Group MDS of finger representations
%
% For each session × task combination (up to 6 panels):
%   1. Shift each subject's RDM so all off-diagonal values are positive,
%      then normalize (mean off-diagonal = 1) — includes all subjects
%   2. Classical MDS per subject → 2D finger coordinates
%      (cmdscale handles negative eigenvalues; take first 2 dims)
%   3. Within-session Procrustes: align all subjects to subject 1
%      (rotation/reflection only, no scaling)
%   4. Cross-session Procrustes: align ses-02 and ses-03 group means
%      to ses-01 group mean, apply same transform to all individual
%      subject coordinates so sessions are comparable
%   5. Group mean + SEM ellipses
%
% Layout: rows = tasks (Execution, Imagery)
%         cols = sessions (Pre, Post, Post-gap)
% =====================================================================
clear all; close all; clc;

% ---- USER SETTING ----
% ses01WTA | allsesWTA | anatROI
roiTag = 'ses01WTA';
% ----------------------

% ---- Paths ----
[~, currentUser] = system('whoami');
currentUser = strtrim(currentUser);

if strcmp(currentUser, 'pw1246')
    bidsDir = '/Users/pw1246/Library/CloudStorage/Box-Box/sixthfinger-test';
else
    bidsDir = '/Users/hha243/Library/CloudStorage/Box-Box/sixthfinger-test';
end
codeDir = fullfile(bidsDir, 'code');

% ---- Load subjects ----
mapData  = jsondecode(fileread(fullfile(codeDir, 'map.json')));
subjects = mapData.subjects;

% ---- Task definitions ----
tasks(1).name        = 'Execution';
tasks(1).fingerNames = {'Thumb','Index','Middle','Ring','Pinky'};

tasks(2).name        = 'Imagery';
tasks(2).fingerNames = {'Thumb','Index','Middle','Ring','Pinky','Sixth'};

allSessions = {'ses-01','ses-02','ses-03'};
sesLabels   = {'Pre','Post','Post-gap'};
nTasks = numel(tasks);
nSes   = numel(allSessions);

% ---- Finger colors ----
fingerColors = [0.00  0.45  0.74;   % thumb   - blue
                0.17  0.63  0.17;   % index   - green
                0.84  0.71  0.10;   % middle  - gold
                0.85  0.33  0.10;   % ring    - orange
                0.64  0.08  0.18;   % pinky   - red
                0.75  0.00  0.75];  % sixth   - magenta

% =====================================================================
% Step 1–3: MDS + within-session Procrustes for every panel
% =====================================================================
coords_aligned = cell(nTasks, nSes);   % [nF × 2 × nSub] per panel

for iTask = 1:nTasks
    fingerNames = tasks(iTask).fingerNames;
    nF          = numel(fingerNames);

    for iSes = 1:nSes
        ses         = allSessions{iSes};
        coords_list = {};

        for iSub = 1:numel(subjects)
            subID = subjects(iSub).subID;

            if ~any(strcmp(subjects(iSub).sessions, ses)), continue; end

            rdmFile = fullfile(bidsDir, 'derivatives', 'RSA', subID, ses, ...
                               [tasks(iTask).name '_RDM_' roiTag '.mat']);
            if ~exist(rdmFile, 'file'), continue; end

            tmp = load(rdmFile, 'RDM');
            D   = tmp.RDM;

            % ---- Shift off-diagonal to make all values positive ----
            % Add minimum constant so min(off-diagonal) = eps
            offdiag_mask = ~eye(nF);
            minOff = min(D(offdiag_mask));
            if minOff < 0
                D(offdiag_mask) = D(offdiag_mask) + abs(minOff) + 1e-6;
            end

            % ---- Normalize: mean off-diagonal = 1 ----
            D = D / mean(D(offdiag_mask));

            % ---- Classical MDS (cmdscale handles negative eigenvalues) ----
            try
                Y = cmdscale(D);
            catch
                continue;
            end
            if size(Y, 2) < 2, continue; end

            coords_list{end+1} = Y(:, 1:2);   %#ok<AGROW>
        end

        nSub_panel = numel(coords_list);
        if nSub_panel < 2
            fprintf('  Not enough subjects for %s %s\n', tasks(iTask).name, ses);
            coords_aligned{iTask, iSes} = [];
            continue;
        end

        % ---- Within-session Procrustes: align all subjects to subject 1 ----
        ref     = coords_list{1};
        aligned = zeros(nF, 2, nSub_panel);
        aligned(:,:,1) = ref;
        for k = 2:nSub_panel
            [~, aligned(:,:,k)] = procrustes(ref, coords_list{k}, 'Scaling', false);
        end

        coords_aligned{iTask, iSes} = aligned;
        fprintf('  %s | %s: %d subjects\n', tasks(iTask).name, ses, nSub_panel);
    end
end

% =====================================================================
% Step 4: Cross-session Procrustes — align ses-02 and ses-03 to ses-01
%
% For each task:
%   - Use ses-01 group mean as the cross-session reference
%   - Find rotation/reflection that maps ses-02 mean → ses-01 mean
%   - Apply that SAME transform to every individual subject in ses-02
%   - Repeat for ses-03
%
% This removes arbitrary orientation differences across sessions while
% preserving true changes in inter-finger geometry.
% =====================================================================
for iTask = 1:nTasks
    if isempty(coords_aligned{iTask, 1}), continue; end

    mu_ses1 = mean(coords_aligned{iTask, 1}, 3);   % [nF × 2] ses-01 group mean

    for iSes = 2:nSes
        C = coords_aligned{iTask, iSes};
        if isempty(C), continue; end

        mu_ses = mean(C, 3);   % [nF × 2] this session's group mean

        % Find transform: align this session's mean to ses-01 mean
        [~, ~, T] = procrustes(mu_ses1, mu_ses, 'Scaling', false);

        % Apply same transform to every individual subject's coordinates
        nSub_panel = size(C, 3);
        for k = 1:nSub_panel
            C(:,:,k) = T.b * C(:,:,k) * T.T + T.c(1,:);
        end

        coords_aligned{iTask, iSes} = C;
    end
end

% ---- Consistent axis range across all panels ----
allCoords = [];
for iTask = 1:nTasks
    for iSes = 1:nSes
        C = coords_aligned{iTask, iSes};
        if ~isempty(C)
            allCoords = [allCoords; mean(C, 3)]; %#ok<AGROW>
        end
    end
end
if ~isempty(allCoords)
    pad     = 0.35;
    axRange = [min(allCoords(:)) - pad, max(allCoords(:)) + pad];
else
    axRange = [-2, 2];
end

% =====================================================================
% Plotting
% =====================================================================
figure('Name', 'Group MDS — Finger Representations', ...
       'Color', 'w', ...
       'Position', [50, 50, 380*nSes, 360*nTasks]);

for iTask = 1:nTasks
    fingerNames = tasks(iTask).fingerNames;
    nF          = numel(fingerNames);

    for iSes = 1:nSes
        spIdx = (iTask - 1) * nSes + iSes;
        ax    = subplot(nTasks, nSes, spIdx);
        hold on;

        C = coords_aligned{iTask, iSes};

        if isempty(C)
            axis off;
            text(0.5, 0.5, 'no data', 'Units', 'normalized', ...
                'HorizontalAlignment', 'center', 'FontSize', 11, ...
                'Color', [0.5 0.5 0.5]);
            title(sprintf('%s  |  %s', tasks(iTask).name, sesLabels{iSes}), ...
                'FontSize', 11, 'FontWeight', 'bold');
            continue;
        end

        nSub_panel = size(C, 3);
        mu_all     = mean(C, 3);   % [nF × 2] group mean

        % ---- SEM ellipses ----
        for f = 1:nF
            coords_f = squeeze(C(f, :, :))';   % [nSub × 2]

            C_sem = cov(coords_f) / nSub_panel;

            [V, D_eig] = eig(C_sem);
            [~, order] = sort(diag(D_eig), 'descend');
            V     = V(:, order);
            D_eig = D_eig(order, order);

            t   = linspace(0, 2*pi, 200);
            ell = V * sqrt(abs(diag(D_eig))) .* [cos(t); sin(t)];
            ell = ell + mu_all(f,:)';

            fill(ell(1,:), ell(2,:), fingerColors(f,:), ...
                'FaceAlpha', 0.15, 'EdgeColor', fingerColors(f,:), ...
                'LineWidth', 1.2);
        end

        % ---- Group mean dots and labels ----
        for f = 1:nF
            plot(mu_all(f,1), mu_all(f,2), 'o', ...
                'MarkerFaceColor', fingerColors(f,:), ...
                'MarkerEdgeColor', 'k', ...
                'MarkerSize', 10, 'LineWidth', 1);

            text(mu_all(f,1), mu_all(f,2) + 0.07, fingerNames{f}, ...
                'HorizontalAlignment', 'center', ...
                'FontSize', 8, 'FontWeight', 'bold', ...
                'Color', fingerColors(f,:));
        end

        % ---- Formatting ----
        xlim(axRange); ylim(axRange);
        axis square; box on;
        xlabel('MDS dim 1', 'FontSize', 9);
        ylabel('MDS dim 2', 'FontSize', 9);
        title(sprintf('%s  |  %s  (n=%d)', ...
            tasks(iTask).name, sesLabels{iSes}, nSub_panel), ...
            'FontSize', 11, 'FontWeight', 'bold');

        plot([0 0], axRange, '-', 'Color', [0.85 0.85 0.85], 'LineWidth', 0.8);
        plot(axRange, [0 0], '-', 'Color', [0.85 0.85 0.85], 'LineWidth', 0.8);
        hold off;
    end
end

sgtitle('Group MDS — Finger Representations (mean ± 1 SEM ellipse)', ...
    'FontSize', 13, 'FontWeight', 'bold');

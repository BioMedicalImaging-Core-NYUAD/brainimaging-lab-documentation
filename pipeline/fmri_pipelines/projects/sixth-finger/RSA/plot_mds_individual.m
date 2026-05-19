% =====================================================================
% plot_mds_individual.m  —  Per-subject MDS plots for outlier inspection
%
% For each subject, produces one figure with:
%   rows    = tasks     (Execution, Imagery)
%   columns = sessions  (Pre, Post, Post-gap where available)
%
% Each panel shows 2D MDS coordinates for that subject's RDM.
% Figures are saved as PNGs to derivatives/RSA/QC/MDS_individual/.
%
% Also prints a summary table of 2D variance explained per subject/
% session/task — low values flag poor MDS representations.
% =====================================================================
%0872, 0457, 0861, 0879, 0624, 0881, 0688, 0883, 0884
clear all; close all; clc;

% ---- USER SETTING ----
% ses01WTA | allsesWTA | anatROI
roiTag = 'allsesWTA';
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

% ---- Output folder for saved figures ----
qcDir = fullfile(bidsDir, 'derivatives', 'RSA', 'QC', 'MDS_individual');
if ~exist(qcDir, 'dir'), mkdir(qcDir); end

% ---- Load subjects ----
mapData  = jsondecode(fileread(fullfile(codeDir, 'map.json')));
subjects = mapData.subjects;

% ---- Task definitions ----
tasks(1).name        = 'Execution';
tasks(1).fingerNames = {'Thumb','Index','Middle','Ring','Pinky'};

tasks(2).name        = 'Imagery';
tasks(2).fingerNames = {'Thumb','Index','Middle','Ring','Pinky','Sixth'};

sesLabels = {'Pre','Post','Post-gap'};
nTasks    = numel(tasks);

% ---- Finger colors ----
fingerColors = [0.00  0.45  0.74;   % thumb   - blue
                0.17  0.63  0.17;   % index   - green
                0.84  0.71  0.10;   % middle  - gold
                0.85  0.33  0.10;   % ring    - orange
                0.64  0.08  0.18;   % pinky   - red
                0.75  0.00  0.75];  % sixth   - magenta

% ---- Summary table (variance explained) ----
fprintf('\n%-12s %-8s %-12s %-10s %-10s\n', ...
    'Subject', 'Session', 'Task', 'Var2D(%)', 'nWTA');
fprintf('%s\n', repmat('-', 1, 56));

% =====================================================================
% Subject loop
% =====================================================================
for iSub = 1:numel(subjects)
    subID    = subjects(iSub).subID;
    sessions = subjects(iSub).sessions;
    nSes     = numel(sessions);

    fig = figure('Name', subID, 'Color', 'w', ...
                 'Position', [50, 50, 340*nSes, 320*nTasks], ...
                 'Visible', 'off');

    % First pass: compute MDS for all panels
    mdsCells = cell(nTasks, nSes);   % mdsCells{iTask,iSes} = struct with coords, varExp, nWTA

    for iTask = 1:nTasks
        fingerNames = tasks(iTask).fingerNames;
        nF          = numel(fingerNames);

        for iSes = 1:nSes
            ses     = sessions{iSes};
            rdmFile = fullfile(bidsDir, 'derivatives', 'RSA', subID, ses, ...
                               [tasks(iTask).name '_RDM_' roiTag '.mat']);

            if ~exist(rdmFile, 'file')
                continue;
            end

            tmp  = load(rdmFile, 'RDM', 'nWTA');
            D    = tmp.RDM;
            nWTA = tmp.nWTA;

            % Shift off-diagonal so all values are positive, then normalize
            offdiag_mask = ~eye(nF);
            minOff = min(D(offdiag_mask));
            if minOff < 0
                D(offdiag_mask) = D(offdiag_mask) + abs(minOff) + 1e-6;
            end
            meanOff = mean(D(offdiag_mask));
            if meanOff <= 0, continue; end
            D = D / meanOff;

            % Classical MDS
            try
                [Y, eigvals] = cmdscale(D);
            catch
                continue;
            end
            if size(Y, 2) < 2, continue; end

            % Variance explained by first 2 dimensions
            pos_eig = eigvals(eigvals > 0);
            varExp  = 100 * sum(eigvals(1:2)) / sum(pos_eig);

            s.coords = Y(:, 1:2);   % [nF × 2]
            s.varExp = varExp;
            s.nWTA   = nWTA;
            mdsCells{iTask, iSes} = s;

            fprintf('%-12s %-8s %-12s %8.1f%%  %6d\n', ...
                subID, ses, tasks(iTask).name, varExp, nWTA);
        end
    end

    % Cross-session Procrustes: align ses-02 and ses-03 to ses-01 per task
    for iTask = 1:nTasks
        % Find which column index corresponds to ses-01 for this subject
        iRef = find(strcmp(sessions, 'ses-01'), 1);
        if isempty(iRef) || isempty(mdsCells{iTask, iRef}), continue; end
        ref_coords = mdsCells{iTask, iRef}.coords;   % [nF × 2]

        for iSes = 1:nSes
            if iSes == iRef || isempty(mdsCells{iTask, iSes}), continue; end
            [~, aligned, T] = procrustes(ref_coords, mdsCells{iTask, iSes}.coords, ...
                                         'Scaling', false);
            mdsCells{iTask, iSes}.coords = aligned;
        end
    end

    % Recompute allCoords after alignment
    allCoords = [];
    for iTask = 1:nTasks
        for iSes = 1:nSes
            if ~isempty(mdsCells{iTask, iSes})
                allCoords = [allCoords; mdsCells{iTask, iSes}.coords]; %#ok<AGROW>
            end
        end
    end

    % Consistent axis range across all panels for this subject
    if ~isempty(allCoords)
        pad     = 0.35;
        axRange = [min(allCoords(:)) - pad, max(allCoords(:)) + pad];
    else
        axRange = [-2, 2];
    end

    % Second pass: plot
    for iTask = 1:nTasks
        fingerNames = tasks(iTask).fingerNames;
        nF          = numel(fingerNames);

        for iSes = 1:nSes
            spIdx = (iTask - 1) * nSes + iSes;
            ax    = subplot(nTasks, nSes, spIdx);
            hold on;

            s = mdsCells{iTask, iSes};

            if isempty(s)
                axis off;
                text(0.5, 0.5, 'no data', 'Units', 'normalized', ...
                    'HorizontalAlignment', 'center', 'FontSize', 10, ...
                    'Color', [0.5 0.5 0.5]);
                title(sprintf('%s | %s', tasks(iTask).name, sesLabels{iSes}), ...
                    'FontSize', 10, 'FontWeight', 'bold');
                continue;
            end

            % Light grid lines
            plot([0 0], axRange, '-', 'Color', [0.85 0.85 0.85], 'LineWidth', 0.8);
            plot(axRange, [0 0], '-', 'Color', [0.85 0.85 0.85], 'LineWidth', 0.8);

            % Plot finger positions
            for f = 1:nF
                plot(s.coords(f,1), s.coords(f,2), 'o', ...
                    'MarkerFaceColor', fingerColors(f,:), ...
                    'MarkerEdgeColor', 'k', ...
                    'MarkerSize', 11, 'LineWidth', 1);

                text(s.coords(f,1), s.coords(f,2) + 0.08, fingerNames{f}, ...
                    'HorizontalAlignment', 'center', ...
                    'FontSize', 8, 'FontWeight', 'bold', ...
                    'Color', fingerColors(f,:));
            end

            xlim(axRange); ylim(axRange);
            axis square; box on;
            xlabel('Dim 1', 'FontSize', 8);
            ylabel('Dim 2', 'FontSize', 8);
            title(sprintf('%s | %s\n(%.0f%% var, n=%d verts)', ...
                tasks(iTask).name, sesLabels{iSes}, s.varExp, s.nWTA), ...
                'FontSize', 9, 'FontWeight', 'bold');

            hold off;
        end
    end

    sgtitle(subID, 'FontSize', 13, 'FontWeight', 'bold');

    % Save figure
    outFile = fullfile(qcDir, [subID '_MDS.png']);
    exportgraphics(fig, outFile, 'Resolution', 150);
    close(fig);
    fprintf('  Saved: %s\n', outFile);
end

fprintf('\nAll figures saved to:\n  %s\n', qcDir);

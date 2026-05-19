% =====================================================================
% plot_rdm.m  —  Visualise crossnobis RDMs as heatmaps
%
% Plots RDMs for a chosen subject across all available sessions and
% both tasks. Layout:
%   rows    = tasks     (Execution, Imagery)
%   columns = sessions  (ses-01, ses-02, [ses-03 if available])
%
% Each heatmap uses a shared colour scale within each task (row) so
% distances are comparable across sessions.
% =====================================================================
clc;
% ---- USER SETTING ----
subNum = '0872';   % subject number only, e.g. '0457'
% ses01WTA | allsesWTA | anatROI
roiTag = 'allsesWTA';
% ----------------------

subID = ['sub-' subNum];

% ---- Paths ----
[~, currentUser] = system('whoami');
currentUser = strtrim(currentUser);

if strcmp(currentUser, 'pw1246')
    bidsDir = '/Users/pw1246/Library/CloudStorage/Box-Box/sixthfinger-test';
else
    bidsDir = '/Users/hha243/Library/CloudStorage/Box-Box/sixthfinger-test';
end

codeDir = fullfile(bidsDir, 'code');

% ---- Get sessions for this subject from map.json ----
mapData  = jsondecode(fileread(fullfile(codeDir, 'map.json')));
subjects = mapData.subjects;
subIDs   = {subjects.subID};
idx      = find(strcmp(subIDs, subID), 1);

if isempty(idx)
    error('Subject %s not found in map.json', subID);
end
sessions = subjects(idx).sessions;   % e.g. {'ses-01','ses-02','ses-03'}
nSes     = numel(sessions);

% ---- Task definitions ----
tasks(1).name        = 'Execution';
tasks(1).fingerNames = {'Thumb','Index','Middle','Ring','Pinky'};

tasks(2).name        = 'Imagery';
tasks(2).fingerNames = {'Thumb','Index','Middle','Ring','Pinky','Sixth'};

nTasks = numel(tasks);

% ---- Load all RDMs ----
RDMs = cell(nTasks, nSes);   % RDMs{iTask, iSes} = matrix or []

for iTask = 1:nTasks
    for iSes = 1:nSes
        ses     = sessions{iSes};
        rdmFile = fullfile(bidsDir, 'derivatives', 'RSA', subID, ses, ...
                           [tasks(iTask).name '_RDM_' roiTag '.mat']);
        if exist(rdmFile, 'file')
            tmp = load(rdmFile, 'RDM');
            RDMs{iTask, iSes} = tmp.RDM;
        else
            RDMs{iTask, iSes} = [];
            fprintf('Missing: %s\n', rdmFile);
        end
    end
end

% ---- Shared colour limits per task (row) ----
% Use symmetric limits around 0 so the colourmap is centred at 0
clims = zeros(nTasks, 2);
for iTask = 1:nTasks
    allVals = [];
    for iSes = 1:nSes
        if ~isempty(RDMs{iTask, iSes})
            M = RDMs{iTask, iSes};
            % Off-diagonal values only (diagonal is always 0)
            mask = ~eye(size(M,1));
            allVals = [allVals; M(mask)]; %#ok<AGROW>
        end
    end
    if ~isempty(allVals)
        maxAbs = max(abs(allVals));
        clims(iTask, :) = [-maxAbs, maxAbs];
    end
end

% ---- Session labels ----
sesLabels = {'Pre','Post','Post-gap'};   % friendly names for ses-01/02/03

% ---- Blue-white-red diverging colormap (replaces RdBu) ----
n    = 128;
half = n / 2;
cmap_bwr = [ linspace(0,1,half)', linspace(0,1,half)', ones(half,1); ...
             ones(half,1), linspace(1,0,half)', linspace(1,0,half)' ];

% ---- Plot ----
figure('Name', sprintf('RDMs — %s', subID), ...
       'Color', 'w', ...
       'Position', [100, 100, 320*nSes, 300*nTasks]);

for iTask = 1:nTasks
    fingerNames = tasks(iTask).fingerNames;
    nF          = numel(fingerNames);

    for iSes = 1:nSes
        spIdx = (iTask - 1) * nSes + iSes;
        ax    = subplot(nTasks, nSes, spIdx);

        if isempty(RDMs{iTask, iSes})
            axis off;
            text(0.5, 0.5, 'no data', 'HorizontalAlignment', 'center', ...
                'Units', 'normalized', 'FontSize', 11, 'Color', [0.5 0.5 0.5]);
            title(sprintf('%s  |  %s', tasks(iTask).name, sesLabels{iSes}), ...
                'FontSize', 11, 'FontWeight', 'bold');
            continue;
        end

        M = RDMs{iTask, iSes};

        imagesc(M, clims(iTask, :));
        colormap(ax, cmap_bwr);   % diverging: blue = similar, red = dissimilar
        colorbar;

        % Axis labels
        set(ax, 'XTick', 1:nF, 'XTickLabel', fingerNames, 'FontSize', 9, ...
                'YTick', 1:nF, 'YTickLabel', fingerNames, 'FontSize', 9);
        xtickangle(45);

        % Overlay distance values in each cell
        for i = 1:nF
            for j = 1:nF
                if i ~= j
                    text(j, i, sprintf('%.2f', M(i,j)), ...
                        'HorizontalAlignment', 'center', ...
                        'VerticalAlignment',   'middle', ...
                        'FontSize', 7, 'Color', 'k');
                end
            end
        end

        title(sprintf('%s  |  %s', tasks(iTask).name, sesLabels{iSes}), ...
            'FontSize', 11, 'FontWeight', 'bold');
        axis square;
    end
end

sgtitle(sprintf('Crossnobis RDMs — %s', subID), 'FontSize', 13, 'FontWeight', 'bold');

% =====================================================================
% xxx_native.m - Batch GLM in fsnative space
% Loops over all subjects from map.json, all sessions, and both tasks
% (Execution + Imagery). Uses Glasser2016 labels for BA9/46/7/40 masking.
% =====================================================================
clear all; close all; clc;

% --- 1. Dynamic User Paths ---
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
addpath(genpath(fullfile(codeDir, 'spm')));

% --- 2. Load subjects and session/DM mapping from map.json ---
mapFile = fullfile(codeDir, 'map.json');
mapData = jsondecode(fileread(mapFile));
subjects      = mapData.subjects;
sessionDirMap = mapData.sessionDirs;
sesNames      = {sessionDirMap.session};
dmDirNames    = {sessionDirMap.dmDir};

% --- Task definitions ---
taskDefs = struct();
taskDefs(1).name         = 'Execution';
taskDefs(1).runs         = 1:3;
taskDefs(1).fingerNames  = {'thumb', 'index', 'middle', 'ring', 'pinky'};
taskDefs(1).fingerLabels = 1:5;
taskDefs(1).resultsBase  = 'Execution_native_BA9-46-7-40';

taskDefs(2).name         = 'Imagery';
taskDefs(2).runs         = 1:5;
taskDefs(2).fingerNames  = {'thumb', 'index', 'middle', 'ring', 'pinky', 'sixth'};
taskDefs(2).fingerLabels = 1:6;
taskDefs(2).resultsBase  = 'Imagery_native_BA9-46-7-40';

space      = 'fsnative';
tThreshold = 1.96;
% BA9/46/7/40 Glasser2016 label names
% BA9:  9a, 9p, 9m  (DLPFC medial/lateral)
% BA46: 46, 9-46d   (DLPFC lateral)
% BA7:  7AL, 7Am, 7PC, 7PL, 7Pm, 7m  (Superior Parietal Lobule)
% BA40: PF, PFcm, PFm, PFop, PFt     (Inferior Parietal Lobule / supramarginal)
roiNames   = {'9a', '9p', '9m', '46', '9-46d', ...
              '7AL', '7Am', '7PC', '7PL', '7Pm', '7m', ...
              'PF', 'PFcm', 'PFm', 'PFop', 'PFt'};

fprintf('=== xxx_native: %d subjects ===\n\n', numel(subjects));

% --- 3. Main Subject Loop ---
for iSub = 1:numel(subjects)
    subID    = subjects(iSub).subID;
    dmNum    = subjects(iSub).dmNum;
    sessions = subjects(iSub).sessions;

    fprintf('=== Subject: %s | dmNum: %d ===\n', subID, dmNum);

    % --- Load native-space BA9/46/7/40 mask (Glasser2016) ---
    fsSubDir  = fullfile(bidsDir, 'derivatives', 'freesurfer', subID);
    glasserDir = fullfile(fsSubDir, 'label', 'Glasser2016');

    if ~exist(fsSubDir, 'dir')
        fprintf('  SKIPPING %s: FreeSurfer directory not found\n\n', subID);
        continue;
    end

    lcurv = read_curv(fullfile(fsSubDir, 'surf', 'lh.curv'));
    rcurv = read_curv(fullfile(fsSubDir, 'surf', 'rh.curv'));
    nVertsL  = numel(lcurv);
    nVertsR  = numel(rcurv);
    leftidx  = 1:nVertsL;
    rightidx = (1:nVertsR) + nVertsL;

    lh_mask = false(nVertsL, 1);
    rh_mask = false(nVertsR, 1);

    for i = 1:length(roiNames)
        lfile = fullfile(glasserDir, ['lh.' roiNames{i} '.label']);
        if exist(lfile, 'file')
            ld = read_label('', lfile);
            lh_mask(ld(:,1) + 1) = true;
        else
            warning('Label not found: %s', lfile);
        end
        rfile = fullfile(glasserDir, ['rh.' roiNames{i} '.label']);
        if exist(rfile, 'file')
            rd = read_label('', rfile);
            rh_mask(rd(:,1) + 1) = true;
        else
            warning('Label not found: %s', rfile);
        end
    end
    all_mask = [lh_mask; rh_mask];
    fprintf('  Mask: %d vertices in BA9/46/7/40\n', sum(all_mask));

    % MGZ templates for saving
    mgz_L = MRIread(fullfile(fsSubDir, 'mri', 'orig.mgz'));
    mgz_R = mgz_L;

    % --- Session loop ---
    for iSes = 1:numel(sessions)
        ses    = sessions{iSes};
        sesIdx = find(strcmp(sesNames, ses), 1);
        if isempty(sesIdx)
            fprintf('  SKIPPING %s: unknown session\n', ses);
            continue;
        end
        dmBaseDir = fullfile(codeDir, dmDirNames{sesIdx});

        % --- Task loop ---
        for iTask = 1:numel(taskDefs)
            task         = taskDefs(iTask).name;
            taskRuns     = taskDefs(iTask).runs;
            fingerNames  = taskDefs(iTask).fingerNames;
            fingerLabels = taskDefs(iTask).fingerLabels;
            resultsBase  = taskDefs(iTask).resultsBase;
            nRuns        = numel(taskRuns);
            nFingers     = numel(fingerNames);

            fprintf('  --- %s | %s | dmNum: %d ---\n', subID, ses, dmNum);

            % Build dataLog
            dataLog = table( ...
                repmat({subID}, nRuns, 1), ...
                repmat({ses},   nRuns, 1), ...
                repmat({task},  nRuns, 1), ...
                taskRuns', ...
                'VariableNames', {'subject', 'session', 'task', 'run'});

            % GLM
            try
                datafiles          = load_dataLog(dataLog, space, bidsDir);
                [dsm, myNoise]     = load_dsm(dataLog, dmBaseDir, dmNum, bidsDir);
                [~, c_betas, c_SEs, ~] = get_beta(datafiles, dsm, myNoise);
            catch ME
                fprintf('  ERROR %s %s %s: %s\n', subID, ses, task, ME.message);
                continue;
            end

            % Precision-weighted combination across runs
            all_betas = cat(3, c_betas{:});
            all_SEs   = cat(3, c_SEs{:});
            W         = 1 ./ (all_SEs .^ 2);

            beta_combined   = sum(all_betas .* W, 3) ./ sum(W, 3);
            se_combined     = 1 ./ sqrt(sum(W, 3));
            t_stat_combined = beta_combined ./ se_combined;

            % Apply BA9/46/7/40 mask
            beta_combined(~all_mask, :)   = 0;
            t_stat_combined(~all_mask, :) = 0;

            % Save beta and t-stat maps
            resultsDir = fullfile(bidsDir, 'derivatives', resultsBase, subID, ses);
            if ~exist(resultsDir, 'dir')
                mkdir(resultsDir);
            end

            for iFing = 1:nFingers
                fn = fingerNames{iFing};
                mgz_L.vol = beta_combined(leftidx, iFing);
                MRIwrite(mgz_L, fullfile(resultsDir, ['lh.' fn '.mgz']));
                mgz_R.vol = beta_combined(rightidx, iFing);
                MRIwrite(mgz_R, fullfile(resultsDir, ['rh.' fn '.mgz']));
                mgz_L.vol = t_stat_combined(leftidx, iFing);
                MRIwrite(mgz_L, fullfile(resultsDir, ['lh.' fn '_tstat.mgz']));
                mgz_R.vol = t_stat_combined(rightidx, iFing);
                MRIwrite(mgz_R, fullfile(resultsDir, ['rh.' fn '_tstat.mgz']));
            end

            % CoG fingermap
            lh_fingmap = compute_cog_local(t_stat_combined(leftidx,  :), fingerLabels, tThreshold);
            rh_fingmap = compute_cog_local(t_stat_combined(rightidx, :), fingerLabels, tThreshold);

            mgz_L.vol = lh_fingmap;
            MRIwrite(mgz_L, fullfile(resultsDir, 'lh.fingermap.mgz'));
            mgz_R.vol = rh_fingmap;
            MRIwrite(mgz_R, fullfile(resultsDir, 'rh.fingermap.mgz'));

            fprintf('  Saved %s maps for %s %s\n', task, subID, ses);
        end % tasks
    end % sessions

    fprintf('\n');
end % subjects

fprintf('=== Done! ===\n');

% =====================================================================
function fingmap = compute_cog_local(tdata, fingerLabels, tThreshold)
    nVerts = size(tdata, 1);
    fingmap = zeros(nVerts, 1);
    maxT = max(tdata, [], 2);
    selective = maxT > tThreshold;
    tRect = max(tdata, 0);
    weights = tRect(selective, :);
    sumW = sum(weights, 2);
    valid = sumW > 0;
    cog = zeros(sum(selective), 1);
    cog(valid) = (weights(valid, :) * fingerLabels(:)) ./ sumW(valid);
    fingmap(selective) = cog;
end

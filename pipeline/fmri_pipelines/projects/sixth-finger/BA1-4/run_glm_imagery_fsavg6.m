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

% --- 2. Load map.json to get subjects and sessions ---
mapFile = fullfile(codeDir, 'map.json');
mapData = jsondecode(fileread(mapFile));
subjects = mapData.subjects;
sessionDirMap = mapData.sessionDirs;

sesNames = {sessionDirMap.session};
dmDirNames = {sessionDirMap.dmDir};

% --- 3. Pre-load masking information (M1 + S1) from fsaverage6 ---
space = 'fsaverage6';
fsSubDir = fullfile(bidsDir, 'derivatives', 'freesurfer');
fspth = fullfile(fsSubDir, space);

if ~exist(fspth, 'dir')
    error('Could not find FreeSurfer space directory: %s', fspth);
end

% Curvature size calculation
lcurv = read_curv(fullfile(fspth, 'surf', 'lh.curv'));
rcurv = read_curv(fullfile(fspth, 'surf', 'rh.curv'));
leftidx = 1:numel(lcurv);
rightidx = (1:numel(rcurv)) + numel(lcurv);
totalVerts = numel(lcurv) + numel(rcurv);
nVertsPerHemi = numel(lcurv); % usually 40962 for fsaverage6

% Load M1 and S1 ROI labels
labelDir = fullfile(fspth, 'label', 'HCP-MMP1');
lh_labels = {'lh.L_4_ROI.label', 'lh.L_1_ROI.label', 'lh.L_2_ROI.label', 'lh.L_3a_ROI.label', 'lh.L_3b_ROI.label'};
rh_labels = {'rh.R_4_ROI.label', 'rh.R_1_ROI.label', 'rh.R_2_ROI.label', 'rh.R_3a_ROI.label', 'rh.R_3b_ROI.label'};

lh_mask = false(nVertsPerHemi, 1);
rh_mask = false(nVertsPerHemi, 1);

fprintf('Loading M1 and S1 ROI Masks...\n');
for i = 1:length(lh_labels)
    lfile = fullfile(labelDir, lh_labels{i});
    if exist(lfile, 'file')
        ld = read_label('', lfile);
        lh_mask(ld(:,1) + 1) = true; % read_label is 0-indexed
    else
        warning('Label not found: %s', lfile);
    end
    
    rfile = fullfile(labelDir, rh_labels{i});
    if exist(rfile, 'file')
        rd = read_label('', rfile);
        rh_mask(rd(:,1) + 1) = true;
    else
        warning('Label not found: %s', rfile);
    end
end
all_mask = [lh_mask; rh_mask];
fprintf('Mask created: %d vertices in M1/S1 out of %d total.\n\n', sum(all_mask), totalVerts);

% Use a template management .mgz
mgz = MRIread(fullfile(fspth, 'mri', 'orig.mgz'));
nFingers = 6;
fingerNames = {'thumb', 'index', 'middle', 'ring', 'pinky', 'sixth'};

% --- 4. Main Subject Loop ---
for iSub = 1:length(subjects)
    subID = subjects(iSub).subID;
    dmNum = subjects(iSub).dmNum;
    sessions = subjects(iSub).sessions;
    
    for iSes = 1:length(sessions)
        ses = sessions{iSes};
        sesIdx = find(strcmp(sesNames, ses), 1);
        if isempty(sesIdx), continue; end
        dmBaseDir = fullfile(codeDir, dmDirNames{sesIdx});
        
        fprintf('--- Processing Subject: %s | Session: %s | dmNum: %d ---\n', subID, ses, dmNum);
        
        % DataLog setup — 5 Imagery runs
        imageryRuns = 1:5;
        nRuns = length(imageryRuns);
        subjectLog = repmat({subID}, nRuns, 1);
        sessionLog = repmat({ses}, nRuns, 1);
        taskList = repmat({'Imagery'}, nRuns, 1);
        runNum = imageryRuns'; 
        dataLog = table(subjectLog, sessionLog, taskList, runNum, 'VariableNames', {'subject', 'session', 'task', 'run'});

        % Imagery GLM
        try
            datafiles = load_dataLog(dataLog, space, bidsDir);
            [dsm, myNoise] = load_dsm(dataLog, dmBaseDir, dmNum, bidsDir);
            [~, c_betas, c_SEs, ~] = get_beta(datafiles, dsm, myNoise);
        catch ME
            fprintf('ERROR processing %s %s: %s\n', subID, ses, ME.message);
            continue;
        end
        
        % --- 5. Precision-Weighted combination across runs ---
        all_betas = cat(3, c_betas{:}); % [nVerts x nFingers x nRuns]
        all_SEs = cat(3, c_SEs{:});     % [nVerts x nFingers x nRuns]
        W = 1 ./ (all_SEs .^ 2);        % Inverse variance weights
        
        beta_combined = sum(all_betas .* W, 3) ./ sum(W, 3); % [nVerts x nFingers]
        se_combined = 1 ./ sqrt(sum(W, 3));                  % [nVerts x nFingers]
        t_stat_combined = beta_combined ./ se_combined;
        
        % --- 6. Apply M1/S1 mask (exclude everything else) ---
        beta_combined(~all_mask, :) = 0;
        t_stat_combined(~all_mask, :) = 0;

        % --- 7. Save outputs ---
        resultsDir = fullfile(bidsDir, 'derivatives', 'Imagery6', subID, ses);
        if ~exist(resultsDir, 'dir')
            mkdir(resultsDir);
        end
        
        for iFing = 1:nFingers
            fingerName = fingerNames{iFing};
            mgz.vol = beta_combined(leftidx, iFing);
            MRIwrite(mgz, fullfile(resultsDir, ['lh.' fingerName '.mgz']));
            mgz.vol = beta_combined(rightidx, iFing);
            MRIwrite(mgz, fullfile(resultsDir, ['rh.' fingerName '.mgz']));
            
            mgz.vol = t_stat_combined(leftidx, iFing);
            MRIwrite(mgz, fullfile(resultsDir, ['lh.' fingerName '_tstat.mgz']));
            mgz.vol = t_stat_combined(rightidx, iFing);
            MRIwrite(mgz, fullfile(resultsDir, ['rh.' fingerName '_tstat.mgz']));
        end
        fprintf('Saved M1/S1-masked combined maps for %s %s.\n\n', subID, ses);
    end
end
fprintf('--- Imagery Batch Processing Completed Successfully! ---\n');

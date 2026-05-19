% run_grouplevel.m (code-test version)
%
% Group-level finger preference map pipeline.
% No resampling needed — per-subject betas are already in fsaverage6 space
% (written by code-test/process_subject_fingermap.m).
%
% Steps:
%   1. Average betas and t-stats across subjects per session
%   2. Compute continuous finger preference map (demeaned weighted average)
%   3. Mask to ROI (M1 for Execution, 3b for Imagery) using HCP-MMP1 on fsaverage6
%   4. Save to derivatives/group_fsavg6/Task/ses-XX/

clear all; close all; clc;

% =========================================================================
% PATHS
% =========================================================================
bidsDir = '/Users/hha243/Library/CloudStorage/Box-Box/sixthfinger-test';
fsHome  = '/Applications/freesurfer/8.1.0';
codeDir = fullfile(bidsDir, 'code');

addpath(fullfile(codeDir, 'code-test', 'helper'));
addpath(fullfile(fsHome, 'matlab'));

% =========================================================================
% CONFIG
% =========================================================================
tasks       = {'Execution', 'Imagery'};
hemis       = {'lh', 'rh'};
allSessions = {'ses-01', 'ses-02', 'ses-03'};

fingerNames.Execution = {'thumb', 'index', 'middle', 'ring', 'pinky'};
fingerNames.Imagery   = {'thumb', 'index', 'middle', 'ring', 'pinky', 'sixth'};

% =========================================================================
% READ map.json
% =========================================================================
mapFile = fullfile(codeDir, 'map.json');
mapData = jsondecode(fileread(mapFile));
subjects = mapData.subjects;

fprintf('Loaded %d subjects from map.json\n', numel(subjects));

% =========================================================================
% MAIN LOOP — Average across subjects, compute fingermap, save
% =========================================================================
fprintf('\n=== Group averaging + fingermap ===\n');

for iTask = 1:numel(tasks)
    task    = tasks{iTask};
    fingers = fingerNames.(task);
    nF      = numel(fingers);

    for iSes = 1:numel(allSessions)
        ses = allSessions{iSes};

        % Find subjects with this session
        subsThisSes = {};
        for iSub = 1:numel(subjects)
            if any(strcmp(subjects(iSub).sessions, ses))
                subsThisSes{end+1} = subjects(iSub).subID; %#ok<SAGROW>
            end
        end

        if isempty(subsThisSes)
            continue
        end

        fprintf('\n[%s | %s] — %d subjects\n', task, ses, numel(subsThisSes));

        templateMgz = [];

        for iH = 1:numel(hemis)
            hemi = hemis{iH};

            % --- Load betas across subjects ---
            % betaStack: [nVerts x nFingers x nSubs]
            betaStack = [];

            for iSub = 1:numel(subsThisSes)
                subID  = subsThisSes{iSub};
                subDir = fullfile(bidsDir, 'derivatives', [task '_fsavg6'], subID, ses);

                subBetas = [];
                allFound = true;

                for iF = 1:nF
                    betaFile = fullfile(subDir, [hemi '.' fingers{iF} '.mgz']);

                    if ~exist(betaFile, 'file')
                        warning('Missing beta file for %s %s %s %s — skipping subject', subID, ses, task, hemi);
                        allFound = false;
                        break
                    end

                    tmp = MRIread(betaFile);
                    if isempty(templateMgz)
                        templateMgz = tmp;
                    end
                    subBetas(:, iF) = squeeze(tmp.vol); %#ok<AGROW>
                end

                if allFound
                    betaStack = cat(3, betaStack, subBetas);
                end
            end

            if isempty(betaStack)
                warning('No valid subjects for %s %s %s — skipping', task, ses, hemi);
                continue
            end

            % --- Average betas across subjects ---
            betaAvg = mean(betaStack, 3);  % [nVerts x nFingers]

            % --- Continuous fingermap (demeaned weighted average + ROI mask) ---
            fingermap = compute_fingermap(betaAvg, task, hemi, bidsDir);

            % --- Save ---
            outDir = fullfile(bidsDir, 'derivatives', 'group_fsavg6', task, ses);
            if ~exist(outDir, 'dir')
                mkdir(outDir);
            end

            % Group betas per finger
            for iF = 1:nF
                templateMgz.vol = betaAvg(:, iF);
                MRIwrite(templateMgz, fullfile(outDir, [hemi '.' fingers{iF} '.mgz']));
            end

            % Fingermap
            templateMgz.vol = fingermap;
            MRIwrite(templateMgz, fullfile(outDir, [hemi '.fingermap.mgz']));
            fprintf('  Saved: %s %s %s (%d fingers)\n', task, ses, hemi, nF);

        end % hemis
    end % sessions
end % tasks

fprintf('\n=== Done. ===\n');

% run_grouplevel.m
% Group-level finger preference map pipeline.
%
% Steps:
%   1. Resample each subject's beta maps (fsnative -> fsaverage)
%   2. Average betas across subjects per session (sessions kept separate)
%   3. Compute continuous finger preference map (weighted average of finger IDs)
%   4. Mask to ROI (M1 for Execution, SMA proper for Imagery)
%   5. Save to derivatives/group/Task/ses-XX/

clear all; close all; clc;

% =========================================================================
% PATHS — update if needed
% =========================================================================
bidsDir = '/Users/hha243/Library/CloudStorage/Box-Box/sixthfinger-test';
fsHome  = '/Applications/freesurfer/8.1.0';
codeDir = fullfile(bidsDir, 'code');

addpath(fullfile(codeDir, 'helper'));
addpath(fullfile(fsHome, 'matlab'));  % for MRIread, MRIwrite, read_annotation

% =========================================================================
% CONFIG
% =========================================================================
tasks      = {'Execution', 'Imagery'};
hemis      = {'lh', 'rh'};
allSessions = {'ses-01', 'ses-02', 'ses-03'};

fingerNames.Execution = {'thumb', 'index', 'middle', 'ring', 'pinky'};
fingerNames.Imagery   = {'thumb', 'index', 'middle', 'ring', 'pinky', 'sixth'};

% =========================================================================
% READ map.json — subjects and their sessions
% =========================================================================
mapFile = fullfile(codeDir, 'map.json');
mapData = jsondecode(fileread(mapFile));
subjects = mapData.subjects;  % array of structs with .subID and .sessions

fprintf('Loaded %d subjects from map.json\n', numel(subjects));

% =========================================================================
% STEP 1 — Resample beta maps: fsnative -> fsaverage
% =========================================================================
fprintf('\n=== STEP 1: Resampling to fsaverage ===\n');

for iSub = 1:numel(subjects)
    subID    = subjects(iSub).subID;
    sessions = subjects(iSub).sessions;

    for iSes = 1:numel(sessions)
        ses = sessions{iSes};

        for iTask = 1:numel(tasks)
            task = tasks{iTask};
            fprintf('\n[%s | %s | %s]\n', subID, ses, task);
            resample_to_fsavg(subID, ses, task, bidsDir, fsHome);
        end
    end
end

% =========================================================================
% STEP 2-4 — Average across subjects, compute fingermap, mask, save
% =========================================================================
fprintf('\n=== STEPS 2-4: Average -> Fingermap -> Mask -> Save ===\n');

% templateMgz is set per hemi/task/ses from the first resampled file we load
templateMgz = [];

for iTask = 1:numel(tasks)
    task    = tasks{iTask};
    fingers = fingerNames.(task);
    nF      = numel(fingers);

    for iSes = 1:numel(allSessions)
        ses = allSessions{iSes};

        % Find which subjects have this session
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

        for iH = 1:numel(hemis)
            hemi = hemis{iH};

            % --- STEP 2: Load and average betas and t-stats across subjects ---
            % betaStack/tstatStack: [nVerts x nFingers x nSubs]
            betaStack  = [];
            tstatStack = [];

            for iSub = 1:numel(subsThisSes)
                subID  = subsThisSes{iSub};
                subDir = fullfile(bidsDir, 'derivatives', [task '_fsavg'], subID, ses);

                subBetas  = [];  % [nVerts x nFingers] for this subject
                subTstats = [];
                allFound  = true;

                for iF = 1:nF
                    betaFile  = fullfile(subDir, [hemi '.' fingers{iF} '.mgz']);
                    tstatFile = fullfile(subDir, [hemi '.' fingers{iF} '_tstat.mgz']);

                    if ~exist(betaFile, 'file') || ~exist(tstatFile, 'file')
                        warning('Missing files for %s %s %s %s — skipping subject', subID, ses, task, hemi);
                        allFound = false;
                        break
                    end

                    tmp = MRIread(betaFile);
                    if isempty(templateMgz)
                        templateMgz = tmp;
                    end
                    subBetas(:, iF)  = squeeze(tmp.vol); %#ok<AGROW>

                    tmp = MRIread(tstatFile);
                    subTstats(:, iF) = squeeze(tmp.vol); %#ok<AGROW>
                end

                if allFound
                    betaStack  = cat(3, betaStack,  subBetas);
                    tstatStack = cat(3, tstatStack, subTstats);
                end
            end

            if isempty(betaStack)
                warning('No valid subjects found for %s %s %s — skipping', task, ses, hemi);
                continue
            end

            % Average across subjects (dim 3)
            betaAvg  = mean(betaStack,  3);  % [nVerts x nFingers]
            tstatAvg = mean(tstatStack, 3);  % [nVerts x nFingers]

            % --- STEP 3 & 4: Compute continuous fingermap + mask to ROI ---
            fingermap = compute_fingermap(betaAvg, task, hemi, bidsDir);

            % --- STEP 5: Save ---
            outDir = fullfile(bidsDir, 'derivatives', 'group', task, ses);
            if ~exist(outDir, 'dir')
                mkdir(outDir);
            end

            % Save group-averaged betas and t-stats per finger
            for iF = 1:nF
                templateMgz.vol = betaAvg(:, iF);
                MRIwrite(templateMgz, fullfile(outDir, [hemi '.' fingers{iF} '.mgz']));
                templateMgz.vol = tstatAvg(:, iF);
                MRIwrite(templateMgz, fullfile(outDir, [hemi '.' fingers{iF} '_tstat.mgz']));
            end
            fprintf('  Saved group betas + t-stats (%d fingers) for %s %s %s\n', nF, task, ses, hemi);

            % Save fingermap (weighted average, based on betas)
            outFile = fullfile(outDir, [hemi '.fingermap.mgz']);
            templateMgz.vol = fingermap;
            MRIwrite(templateMgz, outFile);
            fprintf('  Saved: %s\n', outFile);

        end % hemis
    end % sessions
end % tasks

fprintf('\n=== Done. ===\n');

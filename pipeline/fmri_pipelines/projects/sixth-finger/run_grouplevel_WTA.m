% run_grouplevel_WTA.m
% Winner-takes-all group-level finger preference map.
%
% Loads group-averaged t-statistics from derivatives/group/ (computed by
% run_grouplevel.m) and applies winner-takes-all: each vertex is assigned
% the finger with the highest average t-stat. This follows the approach
% in Kikkert et al. (2021, HBM). No resampling needed.
%
% Output: derivatives/group_WTA/Task/ses-XX/lh.fingermap.mgz
%         values: 1=thumb, 2=index, 3=middle, 4=ring, 5=pinky (6=sixth for Imagery)
%         0 = outside ROI

clear all; close all; clc;

% =========================================================================
% PATHS
% =========================================================================
bidsDir = '/Users/hha243/Library/CloudStorage/Box-Box/sixthfinger-test';
fsHome  = '/Applications/freesurfer/8.1.0';
codeDir = fullfile(bidsDir, 'code');

addpath(fullfile(codeDir, 'helper'));
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
% MAIN LOOP — Load group betas, apply WTA, mask, save
% =========================================================================
fprintf('=== Winner-Takes-All Finger Map ===\n');

for iTask = 1:numel(tasks)
    task    = tasks{iTask};
    fingers = fingerNames.(task);
    nF      = numel(fingers);

    for iSes = 1:numel(allSessions)
        ses    = allSessions{iSes};
        srcDir = fullfile(bidsDir, 'derivatives', 'group', task, ses);

        if ~exist(srcDir, 'dir')
            fprintf('Skipping %s %s — group betas not found\n', task, ses);
            continue
        end

        fprintf('\n[%s | %s]\n', task, ses);

        for iH = 1:numel(hemis)
            hemi = hemis{iH};

            % --- Load group-averaged t-stats ---
            tstatAvg = [];
            allFound = true;

            for iF = 1:nF
                mgzFile = fullfile(srcDir, [hemi '.' fingers{iF} '_tstat.mgz']);
                if ~exist(mgzFile, 'file')
                    warning('Missing group t-stat: %s — skipping', mgzFile);
                    allFound = false;
                    break
                end
                tmp = MRIread(mgzFile);
                tstatAvg(:, iF) = squeeze(tmp.vol); %#ok<AGROW>
            end

            if ~allFound
                continue
            end

            % --- Winner-takes-all + ROI mask ---
            fingermap = compute_fingermap_WTA(tstatAvg, task, hemi, bidsDir);

            % --- Save ---
            outDir = fullfile(bidsDir, 'derivatives', 'group_WTA', task, ses);
            if ~exist(outDir, 'dir')
                mkdir(outDir);
            end

            outFile = fullfile(outDir, [hemi '.fingermap.mgz']);
            tmp.vol = fingermap;
            MRIwrite(tmp, outFile);
            fprintf('  Saved: %s\n', outFile);

        end % hemis
    end % sessions
end % tasks

fprintf('\n=== Done. ===\n');

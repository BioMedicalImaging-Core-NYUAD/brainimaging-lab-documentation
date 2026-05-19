% run_grouplevel_WTA.m (code-test version)
%
% Winner-takes-all group-level finger preference map.
% Reads group-averaged t-stats from derivatives/group_fsavg6/ and assigns
% each vertex the finger with the highest t-stat.
%
% Output: derivatives/group_WTA_fsavg6/Task/ses-XX/
%   values: 1=thumb, 2=index, 3=middle, 4=ring, 5=pinky (6=sixth for Imagery)
%   0 = outside ROI

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
% MAIN LOOP
% =========================================================================
fprintf('=== Winner-Takes-All Finger Map (fsaverage6) ===\n');

for iTask = 1:numel(tasks)
    task    = tasks{iTask};
    fingers = fingerNames.(task);
    nF      = numel(fingers);

    for iSes = 1:numel(allSessions)
        ses    = allSessions{iSes};
        srcDir = fullfile(bidsDir, 'derivatives', 'group_fsavg6', task, ses);

        if ~exist(srcDir, 'dir')
            fprintf('Skipping %s %s — group t-stats not found\n', task, ses);
            continue
        end

        fprintf('\n[%s | %s]\n', task, ses);

        for iH = 1:numel(hemis)
            hemi = hemis{iH};

            % --- Load group-averaged betas ---
            % T-stat averaging across subjects is statistically invalid.
            % WTA uses group betas instead — all subjects' betas are in PSC
            % (percent signal change), putting them on a comparable scale.
            betaAvg  = [];
            allFound = true;

            for iF = 1:nF
                mgzFile = fullfile(srcDir, [hemi '.' fingers{iF} '.mgz']);
                if ~exist(mgzFile, 'file')
                    warning('Missing group beta: %s — skipping', mgzFile);
                    allFound = false;
                    break
                end
                tmp = MRIread(mgzFile);
                betaAvg(:, iF) = squeeze(tmp.vol); %#ok<AGROW>
            end

            if ~allFound
                continue
            end

            % --- Winner-takes-all + ROI mask ---
            fingermap = compute_fingermap_WTA(betaAvg, task, hemi, bidsDir);

            % --- Save ---
            outDir = fullfile(bidsDir, 'derivatives', 'group_WTA_fsavg6', task, ses);
            if ~exist(outDir, 'dir')
                mkdir(outDir);
            end

            tmp.vol = fingermap;
            MRIwrite(tmp, fullfile(outDir, [hemi '.fingermap.mgz']));
            fprintf('  Saved: %s\n', fullfile(outDir, [hemi '.fingermap.mgz']));

        end % hemis
    end % sessions
end % tasks

fprintf('\n=== Done. ===\n');

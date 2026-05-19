clear all; close all; clc;


bidsDir = fullfile(getenv('HOME'), 'Library', 'CloudStorage', 'Box-Box', 'sixthfinger-test');

% Add FreeSurfer MATLAB functions (needed for MRIread/MRIwrite)
fsDir = '/Applications/freesurfer/7.4.1';
if exist(fullfile(fsDir, 'matlab'), 'dir')
    addpath(genpath(fullfile(fsDir, 'matlab')));
else
    error('FreeSurfer MATLAB toolbox not found at %s', fsDir);
end

% --- Config ---
tasks = {'Execution', 'Imagery'};
fingerNames.Execution = {'thumb', 'index', 'middle', 'ring', 'pinky'};
fingerNames.Imagery   = {'thumb', 'index', 'middle', 'ring', 'pinky', 'sixth'};
hemis = {'lh', 'rh'};

maskPrctile = 99;

for iTask = 1:numel(tasks)
    task     = tasks{iTask};
    fingers  = fingerNames.(task);
    nFingers = numel(fingers);
    fingerNums = 1:nFingers; 

    taskDir = fullfile(bidsDir, 'derivatives', task);
    subDirs = dir(fullfile(taskDir, 'sub-*'));

    for iSub = 1:numel(subDirs)
        subID   = subDirs(iSub).name;
        sesDirs = dir(fullfile(taskDir, subID, 'ses-*'));

        for iSes = 1:numel(sesDirs)
            ses    = sesDirs(iSes).name;
            sesDir = fullfile(taskDir, subID, ses);
            fprintf('Computing fingermap: %s | %s | %s\n', task, subID, ses);

            for iHemi = 1:numel(hemis)
                hemi = hemis{iHemi};

                betas = [];
                for iFinger = 1:nFingers
                    mgz = MRIread(fullfile(sesDir, [hemi '.' fingers{iFinger} '.mgz']));
                    betas = [betas, mgz.vol(:)];
                end

                betas = max(betas, 0);

                totalBeta  = sum(betas, 2);
                prefFinger = (betas * fingerNums') ./ totalBeta;

                % Mask unresponsive vertices: NaN = transparent in FreeView
                threshold = prctile(totalBeta, maskPrctile);
                prefFinger(totalBeta < threshold) = NaN;

                mgz.vol = prefFinger;
                MRIwrite(mgz, fullfile(sesDir, [hemi '.fingermap.mgz']));
            end

            fprintf('  Done: lh/rh.fingermap.mgz saved to %s\n', sesDir);
        end
    end
end


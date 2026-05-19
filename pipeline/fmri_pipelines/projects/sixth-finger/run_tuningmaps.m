clear all; close all; clc;

bidsDir = fullfile(getenv('HOME'), 'Library', 'CloudStorage', 'Box-Box', 'sixthfinger-test');

fsDir = '/Applications/freesurfer/7.4.1';
if exist(fullfile(fsDir, 'matlab'), 'dir')
    addpath(genpath(fullfile(fsDir, 'matlab')));
else
    error('FreeSurfer MATLAB toolbox not found at %s', fsDir);
end

tasks = {'Execution', 'Imagery'};
fingerNames.Execution = {'thumb', 'index', 'middle', 'ring', 'pinky'};
fingerNames.Imagery   = {'thumb', 'index', 'middle', 'ring', 'pinky', 'sixth'};
hemis = {'lh', 'rh'};

chunkSize   = 10000;
maskPrctile = 99;

for iTask = 1:numel(tasks)
    task      = tasks{iTask};
    fingers   = fingerNames.(task);
    nFingers  = numel(fingers);
    fingerPos = 1:nFingers;

    % --- Build Gaussian template library ---
    % For each (mu, sigma) pair, compute what the beta profile *should* look like
    muGrid    = linspace(1, nFingers, 100); % 100 candidate preferred fingers
    sigmaGrid = linspace(0.3, 3, 20);       % 20 candidate widths (in finger units)

    [muMesh, sigMesh] = meshgrid(muGrid, sigmaGrid);
    muVec  = muMesh(:);   % nTemplates x 1
    sigVec = sigMesh(:);  % nTemplates x 1

    % templates: nTemplates x nFingers
    templates = exp(-0.5 * ((fingerPos - muVec).^2 ./ sigVec.^2));

    % Normalize to unit vectors so dot product = cosine similarity
    templateNorm = sqrt(sum(templates.^2, 2));
    templates    = templates ./ templateNorm;

    nTemplates = size(templates, 1);

    taskDir = fullfile(bidsDir, 'derivatives', task);
    subDirs = dir(fullfile(taskDir, 'sub-*'));

    for iSub = 1:numel(subDirs)
        subID   = subDirs(iSub).name;
        sesDirs = dir(fullfile(taskDir, subID, 'ses-*'));

        for iSes = 1:numel(sesDirs)
            ses    = sesDirs(iSes).name;
            sesDir = fullfile(taskDir, subID, ses);
            fprintf('Fitting tuning curves: %s | %s | %s\n', task, subID, ses);

            for iHemi = 1:numel(hemis)
                hemi = hemis{iHemi};

                % --- Load betas: nVertices x nFingers ---
                betas = [];
                for iFinger = 1:nFingers
                    mgz = MRIread(fullfile(sesDir, [hemi '.' fingers{iFinger} '.mgz']));
                    betas = [betas, mgz.vol(:)];
                end

                % Zero out negative betas (suppression doesn't reflect preference)
                betas = max(betas, 0);

                % Normalize each vertex's beta profile to unit vector
                betaNorm      = sqrt(sum(betas.^2, 2));
                threshold       = prctile(betaNorm, maskPrctile);
                responsiveVerts = betaNorm >= threshold;
                betasNorm     = zeros(size(betas));
                betasNorm(responsiveVerts,:) = betas(responsiveVerts,:) ./ betaNorm(responsiveVerts);

                % --- Grid search in chunks (avoids large memory allocation) ---
                nVerts   = size(betasNorm, 1);
                muMap    = zeros(nVerts, 1);
                sigmaMap = zeros(nVerts, 1);

                for iChunk = 1:chunkSize:nVerts
                    idx = iChunk : min(iChunk + chunkSize - 1, nVerts);

                    % Cosine similarity: chunk x nTemplates
                    sim = betasNorm(idx, :) * templates';

                    % Best-matching template
                    [~, bestIdx] = max(sim, [], 2);

                    muMap(idx)    = muVec(bestIdx);
                    sigmaMap(idx) = sigVec(bestIdx);
                end

                % Unresponsive vertices → 0
                muMap(~responsiveVerts)    = NaN;
                sigmaMap(~responsiveVerts) = NaN;

                % --- Save ---
                mgz.vol = muMap;
                MRIwrite(mgz, fullfile(sesDir, [hemi '.tuning_mu.mgz']));

                mgz.vol = sigmaMap;
                MRIwrite(mgz, fullfile(sesDir, [hemi '.tuning_sigma.mgz']));
            end

            fprintf('  Done: lh/rh.tuning_mu.mgz + tuning_sigma.mgz saved\n');
        end
    end
end

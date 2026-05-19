% =====================================================================
% average_subjects.m
% Averages per-finger maps across subjects with individual-level 
% thresholding, then computes center-of-gravity fingermaps.
%
% Produces:
%   - Per-subject CoG fingermaps (per session)
%   - Thresholded group-averaged beta and t-stat maps (per session)
%   - Group-level CoG fingermaps (per session)
% =====================================================================
clear all; close all; clc;

% --- Configuration ---
taskType = 'Imagery';  % 'Execution' Change to 'Imagery' for imagery maps
tThreshold = 1.96;       % Individual-level selectivity threshold (p < 0.05)

% Task-specific settings
if strcmp(taskType, 'Execution')
    resultsFolder = 'Execution6_BA9-46-7-40';
    fingerNames = {'thumb', 'index', 'middle', 'ring', 'pinky'};
    fingerLabels = 1:5;
elseif strcmp(taskType, 'Imagery')
    resultsFolder = 'Imagery6_BA9-46-7-40';
    fingerNames = {'thumb', 'index', 'middle', 'ring', 'pinky', 'sixth'};
    fingerLabels = 1:6;
end
nFingers = numel(fingerNames);

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
if exist(fullfile(fsHome, 'matlab'), 'dir')
    addpath(genpath(fullfile(fsHome, 'matlab')));
end

resultsBaseDir = fullfile(bidsDir, 'derivatives', resultsFolder);

% --- 2. Load template mgz and subjects ---
space = 'fsaverage6';
fspth = fullfile(bidsDir, 'derivatives', 'freesurfer', space);
mgz = MRIread(fullfile(fspth, 'mri', 'orig.mgz'));

mapFile = fullfile(codeDir, 'map.json');
mapData = jsondecode(fileread(mapFile));
subjects = mapData.subjects;

sesList = {'ses-01', 'ses-02', 'ses-03'};
hemis = {'lh', 'rh'};
fileTypes = {'.mgz', '_tstat.mgz'};  % beta and t-stat maps

fprintf('=== %s Pipeline: Averaging + Fingermap (threshold: t > %.2f at subject level) ===\n\n', taskType, tThreshold);

% =====================================================================
% PART 1: Per-subject CoG fingermaps
% =====================================================================
fprintf('--- PART 1: Per-subject CoG fingermaps ---\n');

for iSub = 1:length(subjects)
    subID = subjects(iSub).subID;
    sessions = subjects(iSub).sessions;
    
    for iSes = 1:length(sessions)
        ses = sessions{iSes};
        subDir = fullfile(resultsBaseDir, subID, ses);
        
        if ~exist(subDir, 'dir'), continue; end
        
        for iHemi = 1:2
            hemi = hemis{iHemi};
            
            % Load all finger t-stat maps
            tdata = [];
            allExist = true;
            for iFing = 1:nFingers
                fpath = fullfile(subDir, sprintf('%s.%s_tstat.mgz', hemi, fingerNames{iFing}));
                if ~exist(fpath, 'file')
                    allExist = false;
                    break;
                end
                tmp = MRIread(fpath);
                tdata(:, iFing) = tmp.vol(:);
            end
            
            if ~allExist, continue; end
            
            % Compute and save CoG fingermap
            fingmap = compute_cog(tdata, fingerLabels, tThreshold);
            mgz.vol = fingmap;
            MRIwrite(mgz, fullfile(subDir, sprintf('%s.fingermap.mgz', hemi)));
        end
        fprintf('  Saved fingermap: %s %s\n', subID, ses);
    end
end

% =====================================================================
% PART 2: Thresholded group averaging + group CoG fingermaps
% =====================================================================
fprintf('\n--- PART 2: Thresholded group averaging + group fingermaps ---\n');

for iSes = 1:length(sesList)
    ses = sesList{iSes};
    
    outDir = fullfile(resultsBaseDir, 'fsaverage6', ses);
    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end
    
    fprintf('\n  Session: %s\n', ses);
    
    for iHemi = 1:2
        hemi = hemis{iHemi};
        
        % ----------------------------------------------------------
        % Step A: Collect t-stats from all subjects for this session
        %         Apply per-subject threshold before accumulating
        % ----------------------------------------------------------
        sumBeta = zeros([], nFingers);
        sumTstat = zeros([], nFingers);
        countMap = zeros([], 1);  % how many subjects contributed per vertex
        initialized = false;
        
        for iSub = 1:length(subjects)
            subID = subjects(iSub).subID;
            sessions = subjects(iSub).sessions;
            
            if ~ismember(ses, sessions), continue; end
            
            subDir = fullfile(resultsBaseDir, subID, ses);
            if ~exist(subDir, 'dir'), continue; end
            
            % Load all finger t-stat and beta maps for this subject
            allExist = true;
            tdata = [];
            bdata = [];
            
            for iFing = 1:nFingers
                tpath = fullfile(subDir, sprintf('%s.%s_tstat.mgz', hemi, fingerNames{iFing}));
                bpath = fullfile(subDir, sprintf('%s.%s.mgz', hemi, fingerNames{iFing}));
                
                if ~exist(tpath, 'file') || ~exist(bpath, 'file')
                    allExist = false;
                    break;
                end
                
                tmgz = MRIread(tpath);
                bmgz = MRIread(bpath);
                
                if isempty(tdata)
                    nV = numel(tmgz.vol);
                    tdata = zeros(nV, nFingers);
                    bdata = zeros(nV, nFingers);
                end
                
                tdata(:, iFing) = tmgz.vol(:);
                bdata(:, iFing) = bmgz.vol(:);
            end
            
            if ~allExist, continue; end
            
            % Initialize accumulators on first valid subject
            if ~initialized
                nVerts = size(tdata, 1);
                sumBeta = zeros(nVerts, nFingers);
                sumTstat = zeros(nVerts, nFingers);
                countMap = zeros(nVerts, 1);
                initialized = true;
            end
            
            % Threshold: only include vertices where at least one finger > tThreshold
            maxT = max(tdata, [], 2);       % [nVerts x 1]
            selective = maxT > tThreshold;   % logical mask
            
            % Accumulate only selective vertices
            sumTstat(selective, :) = sumTstat(selective, :) + tdata(selective, :);
            sumBeta(selective, :)  = sumBeta(selective, :)  + bdata(selective, :);
            countMap(selective)    = countMap(selective) + 1;
        end
        
        if ~initialized
            fprintf('    %s: no valid subjects, skipping\n', hemi);
            continue;
        end
        
        % ----------------------------------------------------------
        % Step B: Compute mean (dividing by per-vertex subject count)
        % ----------------------------------------------------------
        hasData = countMap > 0;
        meanTstat = zeros(nVerts, nFingers);
        meanBeta  = zeros(nVerts, nFingers);
        
        for iFing = 1:nFingers
            meanTstat(hasData, iFing) = sumTstat(hasData, iFing) ./ countMap(hasData);
            meanBeta(hasData, iFing)  = sumBeta(hasData, iFing)  ./ countMap(hasData);
        end
        
        % Save averaged maps
        for iFing = 1:nFingers
            fingerName = fingerNames{iFing};
            
            % Save averaged beta
            mgz.vol = meanBeta(:, iFing);
            MRIwrite(mgz, fullfile(outDir, sprintf('%s.%s.mgz', hemi, fingerName)));
            
            % Save averaged t-stat
            mgz.vol = meanTstat(:, iFing);
            MRIwrite(mgz, fullfile(outDir, sprintf('%s.%s_tstat.mgz', hemi, fingerName)));
        end
        
        % Save the subject count map (useful for QC)
        mgz.vol = countMap;
        MRIwrite(mgz, fullfile(outDir, sprintf('%s.nsubjects.mgz', hemi)));
        
        % ----------------------------------------------------------
        % Step C: Compute group-level CoG fingermap
        %         No additional threshold needed — already thresholded
        % ----------------------------------------------------------
        fingmap = compute_cog(meanTstat, fingerLabels, tThreshold);
        mgz.vol = fingmap;
        MRIwrite(mgz, fullfile(outDir, sprintf('%s.fingermap.mgz', hemi)));
        
        fprintf('    %s: averaged %d fingers, max %d subjects contributed\n', ...
            hemi, nFingers, max(countMap));
    end
    fprintf('  Saved group maps for %s\n', ses);
end

fprintf('\n=== All done! ===\n');

% =====================================================================
% Local function: Center-of-Gravity computation
% =====================================================================
function fingmap = compute_cog(tdata, fingerLabels, tThreshold)
    % tdata:        [nVerts x nFingers] contrast t-stats
    % fingerLabels: [1 2 3 4 5] or [1 2 3 4 5 6]
    % tThreshold:   scalar, minimum max-t for inclusion
    %
    % Returns: fingmap [nVerts x 1], CoG values (0 = excluded)
    
    nVerts = size(tdata, 1);
    fingmap = zeros(nVerts, 1);
    
    % Only include vertices where at least one finger > threshold
    maxT = max(tdata, [], 2);
    selective = maxT > tThreshold;
    
    % Rectify (negative t-stats don't contribute)
    tRect = max(tdata, 0);
    
    % Weighted average (if at least one finger is significant, include the
    % vertex before weighted average)
    weights = tRect(selective, :);
    sumW = sum(weights, 2);
    valid = sumW > 0;
    
    cog = zeros(sum(selective), 1);
    cog(valid) = (weights(valid, :) * fingerLabels(:)) ./ sumW(valid);
    
    fingmap(selective) = cog;
end

clear all; close all; clc;

% =========================================================================
% run_main.m (code-test version)
% Batch processing: fsaverage6 BOLD from fMRIPrep + weighted run combination
% =========================================================================

% --- Paths ---
bidsDir = '/Users/hha243/Library/CloudStorage/Box-Box/sixthfinger-test';
codeDir = fullfile(bidsDir, 'code');

% Shared helpers first (load_dataLog, load_dsm)
addpath(fullfile(codeDir, 'helper'));

% code-test helpers added last -> front of path -> override get_beta
addpath(fullfile(codeDir, 'code-test', 'helper'));

% FreeSurfer MATLAB functions
fsDir = '/Applications/freesurfer/8.1.0';
if exist(fullfile(fsDir, 'matlab'), 'dir')
    addpath(fullfile(fsDir, 'matlab'));
end

% SPM (for HRF)
addpath(genpath(fullfile(codeDir, 'spm')));

% --- Read subject/session mapping ---
mapFile = fullfile(codeDir, 'map.json');
mapData = jsondecode(fileread(mapFile));
subjects      = mapData.subjects;
sessionDirMap = mapData.sessionDirs;

sesNames   = {sessionDirMap.session};
dmDirNames = {sessionDirMap.dmDir};

% --- Process all subjects ---
nSubjects = numel(subjects);
fprintf('=== Starting batch processing: %d subjects ===\n\n', nSubjects);

for iSub = 1:nSubjects
    subID    = subjects(iSub).subID;
    dmNum    = subjects(iSub).dmNum;
    sessions = subjects(iSub).sessions;

    for iSes = 1:numel(sessions)
        ses    = sessions{iSes};
        sesIdx = find(strcmp(sesNames, ses), 1);

        if isempty(sesIdx)
            fprintf('SKIPPING %s %s: unknown session\n', subID, ses);
            continue;
        end

        dmBaseDir = fullfile(codeDir, dmDirNames{sesIdx});

        if ~exist(fullfile(dmBaseDir, num2str(dmNum), 'Results'), 'dir')
            fprintf('SKIPPING %s %s: design matrix folder not found\n', subID, ses);
            continue;
        end

        try
            process_subject_fingermap(subID, ses, dmNum, dmBaseDir, bidsDir, codeDir);
        catch ME
            fprintf('ERROR %s %s: %s\n', subID, ses, ME.message);
            fprintf('  In: %s (line %d)\n', ME.stack(1).file, ME.stack(1).line);
            continue;
        end
    end
end

fprintf('\n=== Batch processing complete ===\n');

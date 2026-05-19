clear all; close all; clc;

% =====================================================================
% run_main.m - Batch processing for all subjects and sessions
% Reads map.json and calls process_subject_fingermap for each
% =====================================================================

% --- Setup paths ---
addpath(genpath(pwd));
bidsDir = '/Users/hha243/Library/CloudStorage/Box-Box/sixthfinger-test';
codeDir = fullfile(bidsDir, 'code');

% Add FreeSurfer MATLAB functions
fsDir = '/Applications/freesurfer/8.1.0';
if exist(fullfile(fsDir, 'matlab'), 'dir')
    addpath(genpath(fullfile(fsDir, 'matlab')));
end

% Add SPM (for HRF)
addpath(genpath(fullfile(codeDir, 'spm')));

% --- Read subject/session mapping ---
mapFile = fullfile(codeDir, 'map.json');
mapData = jsondecode(fileread(mapFile));
subjects = mapData.subjects;
sessionDirMap = mapData.sessionDirs;

% Build a lookup: session name -> dm directory name
sesNames = {sessionDirMap.session};
dmDirNames = {sessionDirMap.dmDir};

% --- Process all subjects ---
nSubjects = numel(subjects);
fprintf('=== Starting batch processing: %d subjects ===\n\n', nSubjects);

for iSub = 1:nSubjects
    subID = subjects(iSub).subID;
    dmNum = subjects(iSub).dmNum;
    sessions = subjects(iSub).sessions;

    for iSes = 1:numel(sessions)
        ses = sessions{iSes};

        % Get the dm directory for this session
        sesIdx = find(strcmp(sesNames, ses), 1);
        if isempty(sesIdx)
            fprintf('SKIPPING %s %s: Unknown session in sessionDirs mapping\n', subID, ses);
            continue;
        end
        dmBaseDir = fullfile(codeDir, dmDirNames{sesIdx});

        % Check that the dm folder exists for this subject/session
        if ~exist(fullfile(dmBaseDir, num2str(dmNum), 'Results'), 'dir')
            fprintf('SKIPPING %s %s: No design matrix folder found at %s/%d/Results\n', ...
                subID, ses, dmBaseDir, dmNum);
            continue;
        end

        % Run the pipeline
        try
            process_subject_fingermap(subID, ses, dmNum, dmBaseDir, bidsDir, codeDir);
        catch ME
            fprintf('ERROR processing %s %s: %s\n', subID, ses, ME.message);
            fprintf('  In: %s (line %d)\n', ME.stack(1).file, ME.stack(1).line);
            continue;
        end
    end
end

fprintf('\n=== Batch processing complete ===\n');
function ts = get_sta(vertexIdx, taskName, fingerName, session, subID, bidsDir, codeDir, dmNum)
% GET_STA  Stimulus-triggered average timeseries for one or more vertices.
%
% Preloads all runs for the requested session once, filters to the
% requested vertices, and returns the epoch-averaged PSC timeseries.
%
% Usage:
%   ts = get_sta(vertexIdx, taskName, fingerName, session, subID, bidsDir, codeDir, dmNum)
%
% Inputs:
%   vertexIdx  - vector of 1-based indices into the concatenated [lh; rh]
%                vertex array (scalar also accepted)
%   taskName   - 'Execution' or 'Imagery'
%   fingerName - 'thumb','index','middle','ring','pinky'  (both tasks)
%                'sixth'                                  (Imagery only)
%   session    - 'ses-01', 'ses-02', or 'ses-03'
%   subID      - e.g. 'sub-0457'
%   bidsDir    - path to project root
%   codeDir    - path to code directory (contains map.json and DM folders)
%   dmNum      - design matrix number for this subject (e.g. 102)
%
% Output:
%   ts         - [nVerts x epochLen] averaged % signal change timeseries
%                time axis: 0, 1, 2, ... epochLen-1 seconds post-onset
%
% DM column mapping (same for both tasks):
%   thumb=1, index=2, middle=3, ring=4, pinky=5, sixth=6 (Imagery only)

% --- Parameters ---
TR          = 1;    % seconds
epochLen    = 20;   % seconds post-onset
baselineLen = 4;    % seconds pre-onset for baseline correction
space       = 'fsnative';

% --- DM run indices ---
switch taskName
    case 'Execution'
        taskRuns = 1:3;
        mi_nums  = [2, 4, 6];   % ME run file indices
        sesType  = 'ME';
    case 'Imagery'
        taskRuns = 1:5;
        mi_nums  = [1, 3, 5, 7, 8];  % MI run file indices
        sesType  = 'MI';
    otherwise
        error('taskName must be ''Execution'' or ''Imagery'', got: %s', taskName);
end

% --- Finger -> DM column ---
fingerMap = struct('thumb',1,'index',2,'middle',3,'ring',4,'pinky',5,'sixth',6);
if ~isfield(fingerMap, fingerName)
    error('Unknown fingerName: %s', fingerName);
end
fingerCol = fingerMap.(fingerName);
if strcmp(taskName, 'Execution') && strcmp(fingerName, 'sixth')
    error('''sixth'' finger is only available for Imagery task.');
end

% --- Session -> DM directory ---
mapData    = jsondecode(fileread(fullfile(codeDir, 'map.json')));
sesNames   = {mapData.sessionDirs.session};
dmDirNames = {mapData.sessionDirs.dmDir};
sesIdx     = find(strcmp(sesNames, session), 1);
if isempty(sesIdx)
    error('Session %s not found in map.json', session);
end
dmBaseDir = fullfile(codeDir, dmDirNames{sesIdx});

nVerts   = numel(vertexIdx);
vertexIdx = vertexIdx(:);  % ensure column vector

% --- Accumulate epochs across runs ---
sumEpoch = zeros(nVerts, epochLen);
nEpochs  = 0;

for iRun = 1:length(taskRuns)
    runNum = taskRuns(iRun);

    % Build file paths
    funcDir = fullfile(bidsDir, 'derivatives', 'fmriprep', subID, session, 'func');
    lhFile  = fullfile(funcDir, sprintf('%s_%s_task-%s_run-%02d_hemi-L_space-%s_bold.func.mgh', ...
                subID, session, taskName, runNum, space));
    rhFile  = fullfile(funcDir, sprintf('%s_%s_task-%s_run-%02d_hemi-R_space-%s_bold.func.mgh', ...
                subID, session, taskName, runNum, space));

    if ~exist(lhFile, 'file') || ~exist(rhFile, 'file')
        warning('get_sta: BOLD file not found for run %d, skipping.', runNum);
        continue;
    end

    % Load full hemispheres, filter immediately to requested vertices
    lhMGZ = MRIread(lhFile);
    rhMGZ = MRIread(rhFile);
    boldAll = [squeeze(lhMGZ.vol); squeeze(rhMGZ.vol)];  % [totalVerts x nTRs]
    bold    = boldAll(vertexIdx, :);                      % [nVerts x nTRs]
    nTRs    = size(bold, 2);

    % Convert to % signal change (run mean per vertex)
    runMean = mean(bold, 2);                   % [nVerts x 1]
    runMean(abs(runMean) < 1e-6) = 1e-6;
    psc = ((bold ./ runMean) - 1) * 100;       % [nVerts x nTRs]

    % Load DM and find onsets for this finger
    logDir    = fullfile(dmBaseDir, num2str(dmNum), 'Results');
    dmFileNum = mi_nums(runNum);
    dmPattern = fullfile(logDir, sprintf('sixFingers1_%s_%d_%d_*_dm.csv', sesType, dmNum, dmFileNum));
    dmFiles   = dir(dmPattern);

    if isempty(dmFiles)
        warning('get_sta: DM file not found for run %d, skipping.', runNum);
        continue;
    end

    dm = readmatrix(fullfile(logDir, dmFiles(1).name));
    if isnan(dm(1,1)), dm = dm(2:end, :); end

    onsets = find(diff([0; dm(:, fingerCol)]) == 1);

    for iOnset = 1:length(onsets)
        onset     = onsets(iOnset);
        baseStart = onset - baselineLen;
        epochEnd  = onset + epochLen - 1;

        if baseStart < 1 || epochEnd > nTRs
            continue;
        end

        baseline = mean(psc(:, baseStart:onset-1), 2);  % [nVerts x 1]
        epoch    = psc(:, onset:epochEnd) - baseline;   % [nVerts x epochLen]

        sumEpoch = sumEpoch + epoch;
        nEpochs  = nEpochs + 1;
    end
end

if nEpochs == 0
    warning('get_sta: no valid epochs found for %s | %s | %s | %s', ...
            subID, taskName, fingerName, session);
    ts = zeros(nVerts, epochLen);
    return;
end

ts = sumEpoch / nEpochs;  % [nVerts x epochLen]

end

function [dsm, myNoise] = load_dsm(dataLog, dmBaseDir, dmNum, bidsDir)
% Load design matrices and noise regressors
% Inputs:
%   dataLog - table with columns: subject, session, task, run
%   dmBaseDir - path to design matrix directory (e.g., .../code/fmri_pre_dm)
%   dmNum - design matrix number (e.g., 101)
%   bidsDir - path to BIDS directory
% Outputs:
%   dsm - cell array of design matrices convolved with HRF
%   myNoise - cell array of noise regressors

nRuns = size(dataLog, 1);
dsm = cell(1, nRuns);
myNoise = cell(1, nRuns);

% Define HRF (using SPM's canonical HRF if available, otherwise simple gamma)
TR = 1; % TR in seconds
try
    hrf = spm_hrf(TR);
catch
    % Simple double-gamma HRF if SPM not available
    t = 0:TR:32;
    hrf = gampdf(t, 6) - gampdf(t, 16)/6;
    hrf = hrf' / sum(hrf);
end

dmFileNums = [1,3,5,7,8,2,4,6];

for iRun = 1:nRuns
    % Load design matrix from log folder
    % Format: sixFingers1_ME_10_X_250908_dm.csv where X is run number
    % Map dataLog run to design matrix file number

    logDir = fullfile(dmBaseDir, num2str(dmNum), 'Results');
    dmFileNum  = dmFileNums(iRun);

    if strcmp(dataLog.task{iRun}, 'Imagery')
        sesType = "MI";
    elseif strcmp(dataLog.task{iRun}, 'Execution')
        sesType = "ME";
    end

    dmFile = sprintf('%s/sixFingers1_%s_%d_%d_*_dm.csv', logDir, sesType , dmNum, dmFileNum);
    file_struct = dir(dmFile); 

    dmFile = file_struct.name;
    dmFile =sprintf('%s/%s',logDir,dmFile);
    if ~exist(dmFile, 'file')
        error('Design matrix file not found: %s', dmFile);
    end

    fprintf('Loading design matrix: %s\n', dmFile);

    % Read design matrix (skip header row)
    ds = readmatrix(dmFile);
    if isnan(ds(1,1))
        ds = ds(2:end, :); % Skip header if present
    end

    % Convolve each column with HRF
    nConditions = size(ds, 2);
    ds_conv = zeros(size(ds, 1), nConditions);

    for iCond = 1:nConditions
        temp = conv(ds(:, iCond), hrf);
        ds_conv(:, iCond) = temp(1:size(ds, 1));
    end

    dsm{iRun} = ds_conv;

    % Load noise regressors from fMRIPrep confounds
    subDir = sprintf('%s/derivatives/fmriprep/%s/%s/func', ...
        bidsDir, dataLog.subject{iRun}, dataLog.session{iRun});

    confoundsFile = sprintf('%s/%s_%s_task-%s_run-%02d_desc-confounds_timeseries.tsv', ...
        subDir, dataLog.subject{iRun}, dataLog.session{iRun}, ...
        dataLog.task{iRun}, dataLog.run(iRun));

    if ~exist(confoundsFile, 'file')
        error('Confounds file not found: %s', confoundsFile);
    end

    fprintf('Loading confounds: %s\n', confoundsFile);

    % Read confounds table
    confounds = readtable(confoundsFile, 'FileType', 'text', 'Delimiter', '\t');

    % Select specific regressors (matching FST_public approach)
    whichRegressor = {'trans_x', 'trans_y', 'trans_z', ...
                      'rot_x', 'rot_y', 'rot_z', ...
                      'global_signal', 'white_matter', 'csf'};

    % Extract selected regressors
    regressorData = table2array(confounds(:, whichRegressor));

    % Replace NaN values with 0
    regressorData(isnan(regressorData)) = 0;

    % Add constant and linear drift
    nTimepoints = size(ds, 1);
    const = ones(nTimepoints, 1);
    ldrift = (1:nTimepoints)';

    % Combine all noise regressors
    myNoise{iRun} = [const, ldrift, regressorData];

    fprintf('Loaded design matrix and confounds for run %d\n', iRun);
end

end
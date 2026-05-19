function [dsm, myNoise] = load_dsm_rsa(dataLog, dmBaseDir, dmNum, bidsDir)
% Load design matrices and noise regressors for RSA GLM.
%
% Differences from load_dsm:
%   - Appends temporal derivative of each condition regressor
%   - Confounds: 6 motion params + FD + top 5 aCompCor (a_comp_cor_00..04)
%   - Scrubbing regressors: one-hot column per timepoint where FD > 0.5 mm
%
% Inputs:
%   dataLog   - table: subject, session, task, run
%   dmBaseDir - path to design matrix directory
%   dmNum     - design matrix number (e.g. 101)
%   bidsDir   - path to project root
% Outputs:
%   dsm     - cell {1 x nRuns}: condition regressors + temporal derivatives
%             columns 1:nFingers = HRF-convolved conditions
%             columns nFingers+1:2*nFingers = temporal derivatives
%   myNoise - cell {1 x nRuns}: nuisance regressors (constant, drift, motion,
%             FD, aCompCor x5, scrubbing one-hots)

nRuns = size(dataLog, 1);
dsm     = cell(1, nRuns);
myNoise = cell(1, nRuns);

TR = 1;
try
    hrf = spm_hrf(TR);
catch
    t   = 0:TR:32;
    hrf = gampdf(t, 6) - gampdf(t, 16) / 6;
    hrf = hrf' / sum(hrf);
end

for iRun = 1:nRuns

    % ---- Design matrix ----
    logDir = fullfile(dmBaseDir, num2str(dmNum), 'Results');

    if strcmp(dataLog.task{iRun}, 'Imagery')
        sesType  = 'MI';
        mi_nums  = [1, 3, 5, 7, 8];
        dmFileNum = mi_nums(dataLog.run(iRun));
    else
        sesType  = 'ME';
        me_nums  = [2, 4, 6];
        dmFileNum = me_nums(dataLog.run(iRun));
    end

    dmPattern   = sprintf('%s/sixFingers1_%s_%d_%d_*_dm.csv', logDir, sesType, dmNum, dmFileNum);
    file_struct = dir(dmPattern);
    if isempty(file_struct)
        error('No DM file found: %s', dmPattern);
    end
    dmFile = fullfile(logDir, file_struct(1).name);

    ds = readmatrix(dmFile);
    if isnan(ds(1, 1))
        ds = ds(2:end, :);
    end

    nTRs       = size(ds, 1);
    nConditions = size(ds, 2);

    % Convolve each condition with HRF
    ds_conv = zeros(nTRs, nConditions);
    for iCond = 1:nConditions
        tmp = conv(ds(:, iCond), hrf);
        ds_conv(:, iCond) = tmp(1:nTRs);
    end

    % Temporal derivative (forward finite difference)
    ds_deriv = [diff(ds_conv); zeros(1, nConditions)];

    % Final design matrix: [conditions | derivatives]
    dsm{iRun} = [ds_conv, ds_deriv];

    % ---- Noise regressors ----
    subDir = sprintf('%s/derivatives/fmriprep/%s/%s/func', ...
        bidsDir, dataLog.subject{iRun}, dataLog.session{iRun});

    confoundsFile = sprintf('%s/%s_%s_task-%s_run-%02d_desc-confounds_timeseries.tsv', ...
        subDir, dataLog.subject{iRun}, dataLog.session{iRun}, ...
        dataLog.task{iRun}, dataLog.run(iRun));

    if ~exist(confoundsFile, 'file')
        error('Confounds file not found: %s', confoundsFile);
    end

    confounds = readtable(confoundsFile, 'FileType', 'text', 'Delimiter', '\t');

    % 6 motion parameters
    motionCols = {'trans_x', 'trans_y', 'trans_z', 'rot_x', 'rot_y', 'rot_z'};
    motionData = table2array(confounds(:, motionCols));
    motionData(isnan(motionData)) = 0;

    % Framewise displacement
    fd = confounds.framewise_displacement;
    fd(isnan(fd)) = 0;

    % Top 5 aCompCor components
    aCompCorCols = {'a_comp_cor_00', 'a_comp_cor_01', 'a_comp_cor_02', ...
                    'a_comp_cor_03', 'a_comp_cor_04'};
    aCompCorData = table2array(confounds(:, aCompCorCols));
    aCompCorData(isnan(aCompCorData)) = 0;

    % Scrubbing: one-hot column per FD > 0.5 mm timepoint
    scrubIdx = find(fd > 0.5);
    scrubbing = zeros(nTRs, numel(scrubIdx));
    for k = 1:numel(scrubIdx)
        scrubbing(scrubIdx(k), k) = 1;
    end

    if numel(scrubIdx) > 0
        fprintf('  Run %d: %d timepoints scrubbed (FD > 0.5 mm)\n', ...
            dataLog.run(iRun), numel(scrubIdx));
    end

    % Constant + linear drift
    constant   = ones(nTRs, 1);
    linearDrift = (1:nTRs)';

    myNoise{iRun} = [constant, linearDrift, motionData, fd, aCompCorData, scrubbing];

    fprintf('  Loaded DM and confounds: run %d (%s)\n', dataLog.run(iRun), dataLog.task{iRun});
end

end

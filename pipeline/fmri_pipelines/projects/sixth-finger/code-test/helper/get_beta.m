function [data, betas, SEs, dfs, R2] = get_beta(datafiles, dsm, myNoise)
% Compute beta weights and standard errors per run using OLS GLM.
%
% Inputs:
%   datafiles - cell array of BOLD data [nVerts x nTimepoints] per run
%   dsm       - cell array of finger design matrices (HRF-convolved) per run
%   myNoise   - cell array of noise regressors per run
%
% Outputs:
%   data  - cell array of finger-only fitted data per run
%   betas - cell array of beta weights [nVerts x nRegressors] per run
%   SEs   - cell array of standard errors for finger regressors [nVerts x nFingers] per run
%   dfs   - vector of degrees of freedom [1 x nRuns]
%   R2    - cell array (unused, kept for interface compatibility)

nRuns = numel(datafiles);
data  = cell(1, nRuns);
betas = cell(1, nRuns);
SEs   = cell(1, nRuns);
dfs   = zeros(1, nRuns);
R2    = cell(1, nRuns);

for iRun = 1:nRuns
    % Full design matrix: finger regressors + noise regressors
    X = [dsm{iRun} myNoise{iRun}];

    % Percent signal change normalisation: (signal/mean - 1) * 100
    tmp = ((datafiles{iRun} ./ mean(datafiles{iRun}, 2)) - 1) * 100;

    % OLS: beta = (X'X)^-1 X' Y
    XtXinv      = inv(X' * X);
    betas{iRun} = (XtXinv * X' * tmp')';  % [nVerts x nRegressors]

    % Finger-only fitted data (noise regressors excluded)
    nFingers    = size(dsm{iRun}, 2);
    data{iRun}  = (X(:, 1:nFingers) * betas{iRun}(:, 1:nFingers)')';

    % Residuals and degrees of freedom
    residuals  = tmp - (X * betas{iRun}')';  % [nVerts x nTimepoints]
    n          = size(X, 1);   % timepoints
    p          = size(X, 2);   % total regressors
    df         = n - p;
    dfs(iRun)  = df;

    % Residual variance per vertex
    sigma2 = sum(residuals .^ 2, 2) / df;  % [nVerts x 1]

    % Standard error for finger regressors only: SE = sqrt(sigma2 * diag(X'X)^-1_jj)
    diagXtXinv  = diag(XtXinv);                               % [nRegressors x 1]
    SEs{iRun}   = sqrt(sigma2 * diagXtXinv(1:nFingers)');     % [nVerts x nFingers]

    fprintf('  Run %d: %d timepoints, %d regressors, df=%d\n', iRun, n, p, df);
end

end

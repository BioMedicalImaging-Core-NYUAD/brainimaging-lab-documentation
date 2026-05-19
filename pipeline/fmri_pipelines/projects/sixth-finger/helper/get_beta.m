function [data, betas, tstats, R2] = get_beta(datafiles, dsm, myNoise)
% Compute beta weights and t-statistics using GLM for each run
% Inputs:
%   datafiles - cell array of BOLD data (vertices x timepoints)
%   dsm - cell array of design matrices (convolved with HRF)
%   myNoise - cell array of noise regressors
% Outputs:
%   data    - cell array of fitted data (from design matrix only)
%   betas   - cell array of beta weights [nVerts x nRegressors]
%   tstats  - cell array of t-statistics for finger regressors only [nVerts x nFingers]
%   R2      - cell array of R-squared values (currently empty)

data    = cell(1, numel(datafiles));
betas   = cell(1, numel(datafiles));
tstats  = cell(1, numel(datafiles));
R2      = cell(1, numel(datafiles));

for iRun = 1:numel(datafiles)
    % Combine design matrix and noise regressors
    X = [dsm{iRun} myNoise{iRun}];

    % Convert to percent signal change
    % (signal / mean(signal) - 1) * 100
    tmp = ((datafiles{iRun} ./ mean(datafiles{iRun}, 2)) - 1) * 100;

    % Compute beta weights using least squares
    % betas = (X'X)^-1 * X' * Y
    XtXinv = inv(X' * X);
    betas{iRun} = (XtXinv * X' * tmp')';

    % Reconstruct data using only design matrix (no noise)
    nFingers = size(dsm{iRun}, 2);
    data{iRun} = (X(:, 1:nFingers) * betas{iRun}(:, 1:nFingers)')';

    % --- Compute t-statistics for finger regressors only ---
    % Residuals: Y - X*beta
    residuals = tmp - (X * betas{iRun}')';          % [nVerts x nTimepoints]

    % Residual variance per vertex: RSS / (n - p)
    n  = size(X, 1);   % timepoints
    p  = size(X, 2);   % total regressors (fingers + noise)
    df = n - p;        % degrees of freedom

    sigma2 = sum(residuals .^ 2, 2) / df;           % [nVerts x 1]

    % Standard error of each finger beta: sqrt(sigma2 * (X'X)^-1_jj)
    % XtXinv diagonal gives variance inflation per regressor
    diagXtXinv = diag(XtXinv);                      % [nRegressors x 1]

    % SE for finger regressors only [nVerts x nFingers]
    SE = sqrt(sigma2 * diagXtXinv(1:nFingers)');    % [nVerts x nFingers]

    % t-stat = beta / SE  (finger regressors only)
    tstats{iRun} = betas{iRun}(:, 1:nFingers) ./ SE; % [nVerts x nFingers]

    fprintf('Completed beta and t-stat computation for run %d\n', iRun);
end

end
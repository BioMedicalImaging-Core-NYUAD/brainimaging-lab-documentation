function [data, c_betas, c_SEs, R2] = get_beta(datafiles, dsm, myNoise)
% Compute contrast beta weights and standard errors using GLM for each run
% Inputs:
%   datafiles - cell array of BOLD data (vertices x timepoints)
%   dsm - cell array of design matrices (convolved with HRF)
%   myNoise - cell array of noise regressors
% Outputs:
%   data    - cell array of fitted data (from design matrix only)
%   c_betas - cell array of contrast betas [nVerts x nFingers]
%   c_SEs   - cell array of Contrast Standard Errors [nVerts x nFingers]
%   R2      - cell array of R-squared values (currently empty)

data    = cell(1, numel(datafiles));
c_betas = cell(1, numel(datafiles));
c_SEs   = cell(1, numel(datafiles));
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
    betas_run = (XtXinv * X' * tmp')';

    % Reconstruct data using only design matrix (no noise)
    nFingers = size(dsm{iRun}, 2);
    data{iRun} = (X(:, 1:nFingers) * betas_run(:, 1:nFingers)')';

    % --- Compute SE for contrasts ---
    % Residuals: Y - X*beta
    residuals = tmp - (X * betas_run')';            % [nVerts x nTimepoints]

    % Residual variance per vertex: RSS / (n - p)
    n  = size(X, 1);   % timepoints
    p  = size(X, 2);   % total regressors (fingers + noise)
    df = n - p;        % degrees of freedom

    sigma2 = sum(residuals .^ 2, 2) / df;           % [nVerts x 1]

    % Initialize output matrices for this run
    nVerts = size(tmp, 1);
    c_beta_run = zeros(nVerts, nFingers);
    c_SE_run   = zeros(nVerts, nFingers);
    
    for iFing = 1:nFingers
        % Construct the contrast vector
        % e.g., for 5 fingers: [1, -0.25, -0.25, -0.25, -0.25]
        % e.g., for 6 fingers: [1, -0.2, -0.2, -0.2, -0.2, -0.2]
        c = -1/(nFingers - 1) * ones(1, nFingers);
        c(iFing) = 1;
        
        % Pad the contrast vector with zeros for the noise regressors
        c_full = [c, zeros(1, p - nFingers)];
        
        % Contrast Beta: c * beta
        c_beta_run(:, iFing) = (c_full * betas_run')';
        
        % Contrast Variance Multiplier: c * (X'X)^-1 * c'
        % This is a single scalar that captures the variance inflation incorporating covariance
        vif = c_full * XtXinv * c_full';
        
        % Contrast SE: sqrt(sigma2 * VIF)
        c_SE_run(:, iFing) = sqrt(sigma2 * vif);
    end

    c_betas{iRun} = c_beta_run;
    c_SEs{iRun} = c_SE_run;

    fprintf('Completed contrast beta and SE computation for run %d\n', iRun);
end

end
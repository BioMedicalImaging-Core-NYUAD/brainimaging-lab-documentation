function [raw_betas, residuals, SEs, Finfo] = get_beta_rsa(datafiles, dsm, myNoise)
% Compute raw per-condition beta weights, GLM residuals, SEs, and F-stats for RSA.
%
% Differences from get_beta:
%   - Returns RAW condition betas (finger vs. implicit rest baseline),
%     not contrast-coded betas. Only the first nFingers columns of the
%     design matrix (condition regressors) are returned — temporal
%     derivatives and nuisance regressors are excluded.
%   - Also returns residuals (Y - X*beta) needed for the noise precision
%     matrix in the crossnobis step.
%   - Returns per-condition SEs derived from OLS residual variance and
%     the diagonal of (X'X)^-1 for condition columns only.
%   - Returns Finfo struct with components needed for exact omnibus F-test
%     (full vs. reduced model comparison, no orthogonality assumption).
%
% Inputs:
%   datafiles - {1 x nRuns} cell: BOLD data [nVerts x nTimepoints]
%   dsm       - {1 x nRuns} cell: design matrix [nTRs x 2*nFingers]
%               (condition regressors + temporal derivatives, from load_dsm_rsa)
%   myNoise   - {1 x nRuns} cell: nuisance regressors [nTRs x nNoise]
%
% Outputs:
%   raw_betas - {1 x nRuns} cell: [nVerts x nFingers] raw condition betas
%   residuals - {1 x nRuns} cell: [nVerts x nTimepoints] GLM residuals
%   SEs       - {1 x nRuns} cell: [nVerts x nFingers] per-condition standard errors
%   Finfo     - struct with fields:
%                 SS_model   {1 x nRuns} [nVerts x 1]  RSS_reduced - RSS_full
%                 SS_resid   {1 x nRuns} [nVerts x 1]  RSS_full (full model)
%                 df_num     scalar                     nFingers (numerator df)
%                 df_denom   [1 x nRuns]                nTRs - rank(X) per run

nRuns     = numel(datafiles);
raw_betas = cell(1, nRuns);
residuals = cell(1, nRuns);
SEs       = cell(1, nRuns);

Finfo.SS_model  = cell(1, nRuns);
Finfo.SS_resid  = cell(1, nRuns);
Finfo.df_num    = [];
Finfo.df_denom  = zeros(1, nRuns);

for iRun = 1:nRuns

    X = [dsm{iRun}, myNoise{iRun}];    % [nTRs x (2*nFingers + nNoise)]

    % nFingers = half of dsm columns (conditions + derivatives interleaved)
    nFingers = size(dsm{iRun}, 2) / 2;
    Finfo.df_num = nFingers;

    % Convert BOLD to percent signal change
    tmp = ((datafiles{iRun} ./ mean(datafiles{iRun}, 2)) - 1) * 100;  % [nVerts x nTRs]

    % OLS: betas = (X'X)^-1 X' Y'
    XtXinv    = inv(X' * X);
    betas_run = (XtXinv * X' * tmp')';   % [nVerts x nRegressors]

    % Raw condition betas only (columns 1:nFingers — the HRF-convolved regressors)
    raw_betas{iRun} = betas_run(:, 1:nFingers);   % [nVerts x nFingers]

    % GLM residuals: Y - X * beta_all
    resid_run       = tmp - (X * betas_run')';     % [nVerts x nTimepoints]
    residuals{iRun} = resid_run;

    % Per-vertex residual variance: RSS / (nTRs - rank(X))
    nTRs   = size(X, 1);
    df     = nTRs - rank(X);
    sigma2 = sum(resid_run .^ 2, 2) / df;          % [nVerts x 1]

    % SE per condition: sqrt(sigma2 * diag(XtXinv)_condition)
    diag_XtX_inv = diag(XtXinv);                   % [nRegressors x 1]
    SEs{iRun} = sqrt(sigma2 * diag_XtX_inv(1:nFingers)');  % [nVerts x nFingers]

    % ---- Exact omnibus F-stat: full vs. reduced model ----
    % Reduced model: temporal derivatives + nuisance (no canonical HRF finger regressors)
    % F-test thus asks: do canonical finger regressors explain variance
    % beyond HRF shape correction and nuisance? More conservative and interpretable
    % than testing conditions+derivatives jointly against nuisance only.
    X_red      = [dsm{iRun}(:, nFingers+1:end), myNoise{iRun}];  % [nTRs x (nFingers+nNoise)]
    betas_red  = (X_red' * X_red) \ (X_red' * tmp');      % [nNoise x nVerts]
    resid_red  = tmp - (X_red * betas_red)';               % [nVerts x nTRs]

    RSS_full    = sum(resid_run .^ 2, 2);   % [nVerts x 1]
    RSS_reduced = sum(resid_red .^ 2, 2);   % [nVerts x 1]

    Finfo.SS_model{iRun} = RSS_reduced - RSS_full;   % [nVerts x 1]
    Finfo.SS_resid{iRun} = RSS_full;                 % [nVerts x 1]
    Finfo.df_denom(iRun) = df;

    fprintf('  Completed GLM for run %d: %d verts, %d conditions, df=%d\n', ...
        iRun, size(tmp, 1), nFingers, df);
end

end

% =====================================================================
% view_roi_wta.m  —  View WTA ROI in Freeview
%
% Loads the Execution ses-01 WTA overlays for a chosen subject and
% launches Freeview on lh.inflated with F-map, -log10(p), and WTA map.
% =====================================================================

% ---- USER SETTING ----
subNum = '0883';   % subject number only, e.g. '0457'
% ----------------------

subID = ['sub-' subNum];

% ---- Paths ----
[~, currentUser] = system('whoami');
currentUser = strtrim(currentUser);

if strcmp(currentUser, 'pw1246')
    bidsDir = '/Users/pw1246/Library/CloudStorage/Box-Box/sixthfinger-test';
    fsHome  = '/Applications/freesurfer/7.4.1';
else
    bidsDir = '/Users/hha243/Library/CloudStorage/Box-Box/sixthfinger-test';
    fsHome  = '/Applications/freesurfer/8.1.0';
end

addpath(genpath(fullfile(bidsDir, 'code', 'RSA', 'helpers')));
if exist(fullfile(fsHome, 'matlab'), 'dir')
    addpath(genpath(fullfile(fsHome, 'matlab')));
end

% ---- Check ROI folder exists ----
roiDir = fullfile(bidsDir, 'derivatives', 'RSA', subID, 'ROI');
if ~exist(roiDir, 'dir')
    error('ROI folder not found for %s.\nRun define_roi_wta.m first.', subID);
end

% ---- Load ROI data for summary ----
load(fullfile(roiDir, 'Execution_allses_WTA.mat'), 'wta_map', 'p_thresh', 'nSesUsed');

fingerNames = {'thumb', 'index', 'middle', 'ring', 'pinky'};
fprintf('[%s] WTA summary (p < %.0e, %d sessions pooled):\n', subID, p_thresh, nSesUsed);
for iFing = 1:numel(fingerNames)
    fprintf('  %s: %d vertices\n', fingerNames{iFing}, sum(wta_map == iFing));
end
fprintf('  total active: %d vertices\n\n', sum(wta_map > 0));

% ---- Overlay files ----
fFile   = fullfile(roiDir, 'lh.Execution_allses_Fmap.mgh');
pFile   = fullfile(roiDir, 'lh.Execution_allses_neglog10p.mgh');
wtaFile = fullfile(roiDir, 'lh.Execution_allses_WTA.mgh');

% ---- Load df for threshold computation ----
load(fullfile(roiDir, 'Execution_allses_WTA.mat'), 'df_num_allses', 'df_denom_allses');
F_thresh   = finv(1 - p_thresh, df_num_allses, df_denom_allses);
F_max      = finv(1 - 1e-15,    df_num_allses, df_denom_allses);
p_thr_disp = -log10(p_thresh);
p_max_disp = 20;

% ---- Launch Freeview ----
surfFile = fullfile(bidsDir, 'derivatives', 'freesurfer', subID, 'surf', 'lh.inflated');
fvBin    = fullfile(fsHome, 'bin', 'freeview');

% Set FreeSurfer environment variables — MATLAB's system() does not
% inherit the shell PATH so freeview won't launch without these
setenv('FREESURFER_HOME', fsHome);
setenv('PATH', [fullfile(fsHome, 'bin') ':' getenv('PATH')]);

fvCmd = sprintf(['"%s" -f "%s"' ...
    ':overlay=%s:overlay_color=heat:overlay_threshold=%.2f,%.2f' ...
    ':overlay=%s:overlay_color=heat:overlay_threshold=%.2f,%.2f' ...
    ':overlay=%s:overlay_color=lut:overlay_threshold=0.5,5 &'], ...
    fvBin, surfFile, ...
    fFile, F_thresh, F_max, ...
    pFile, p_thr_disp, p_max_disp, ...
    wtaFile);

fprintf('Launching Freeview for %s...\n', subID);
system(fvCmd);

% =====================================================================
% check_maps.m
% Open fingermap overlays in freeview (lh inflated, left hemi only).
% Run each block independently: select it and press F9.
%
%   1. Execution  — fsaverage6  — ses-01/02/03  (colorwheel inverse, 1-5)
%   2. Execution  — fsnative    — ses-01/02/03  (colorwheel inverse, 1-5)
%   3. Imagery    — fsaverage6  — ses-01/02/03  (colorwheel inverse, 1-6)
%   4. Imagery    — fsnative    — ses-01/02/03  (colorwheel inverse, 1-6)
%
% To identify which session is active when cycling with OPTION+R:
%   The filename is shown in the Layer panel on the left side of FreeView.
% =====================================================================
clear all; close all; clc;

% --- Dynamic paths ---
[~, currentUser] = system('whoami');
currentUser = strtrim(currentUser);
if strcmp(currentUser, 'pw1246')
    bidsDir = '/Users/pw1246/Library/CloudStorage/Box-Box/sixthfinger-test';
    fvBin   = '/Applications/freesurfer/7.4.1/bin/freeview';
else
    bidsDir = '/Users/hha243/Library/CloudStorage/Box-Box/sixthfinger-test';
    fvBin   = '/Applications/freesurfer/8.1.0/bin/freeview';
end

d  = fullfile(bidsDir, 'derivatives');
fs = fullfile(d, 'freesurfer');

% overlay options shared across all commands
ov = @(path, tlo, thi) sprintf(':overlay=%s:overlay_threshold=%g,%g:overlay_color=colorwheel,inverse', path, tlo, thi);

% =====================================================================
% 1. Execution — fsaverage6
% =====================================================================
surf = fullfile(fs, 'fsaverage6', 'surf', 'lh.inflated');
cmd1 = [fvBin ' -f ' surf ...
    ov(fullfile(d,'Execution6','fsaverage6','ses-01','lh.fingermap_1.mgz'), 1, 5) ...
    ov(fullfile(d,'Execution6','fsaverage6','ses-02','lh.fingermap_2.mgz'), 1, 5) ...
    ov(fullfile(d,'Execution6','fsaverage6','ses-03','lh.fingermap_3.mgz'), 1, 5) ...
    ' --viewport 3d &'];
system(cmd1);

% =====================================================================
% 2. Execution — fsnative sub-0457
% =====================================================================
surf = fullfile(fs, 'sub-0457', 'surf', 'lh.inflated');
cmd2 = [fvBin ' -f ' surf ...
    ov(fullfile(d,'Execution_native','sub-0457','ses-01','lh.fingermap_1.mgz'), 1, 5) ...
    ov(fullfile(d,'Execution_native','sub-0457','ses-02','lh.fingermap_2.mgz'), 1, 5) ...
    ov(fullfile(d,'Execution_native','sub-0457','ses-03','lh.fingermap_3.mgz'), 1, 5) ...
    ' --viewport 3d &'];
system(cmd2);

% =====================================================================
% 3. Imagery — fsaverage6
% =====================================================================
surf = fullfile(fs, 'fsaverage6', 'surf', 'lh.inflated');
cmd3 = [fvBin ' -f ' surf ...
    ov(fullfile(d,'Imagery6','fsaverage6','ses-01','lh.fingermap_1.mgz'), 1, 6) ...
    ov(fullfile(d,'Imagery6','fsaverage6','ses-02','lh.fingermap_2.mgz'), 1, 6) ...
    ov(fullfile(d,'Imagery6','fsaverage6','ses-03','lh.fingermap_3.mgz'), 1, 6) ...
    ' --viewport 3d &'];
system(cmd3);

% =====================================================================
% 4. Imagery — fsnative sub-0457
% =====================================================================
surf = fullfile(fs, 'sub-0457', 'surf', 'lh.inflated');
cmd4 = [fvBin ' -f ' surf ...
    ov(fullfile(d,'Imagery_native','sub-0457','ses-01','lh.fingermap_1.mgz'), 1, 6) ...
    ov(fullfile(d,'Imagery_native','sub-0457','ses-02','lh.fingermap_2.mgz'), 1, 6) ...
    ov(fullfile(d,'Imagery_native','sub-0457','ses-03','lh.fingermap_3.mgz'), 1, 6) ...
    ' --viewport 3d &'];
system(cmd4);

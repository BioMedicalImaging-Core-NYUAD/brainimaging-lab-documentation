% =====================================================================
% check_maps.m
% Open fingermap overlays in freeview (lh inflated, left hemi only).
% Run each block independently: select it and press F9.
%
%   1. Execution  — fsaverage6  — ses-01/02/03
%   2. Execution  — fsnative    — ses-01/02/03
%   3. Imagery    — fsaverage6  — ses-01/02/03
%   4. Imagery    — fsnative    — ses-01/02/03
%
% FreeView interpolates linearly between each anchor, producing a smooth
% gradient between digits while anchoring each integer to its own color.
% Vertices with value 0 (outside ROI / untuned) are hidden by the threshold.
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

% --- Build BA1-4 binary mask .mgz for fsaverage6 only ---
glasserFsavg6 = fullfile(fs, 'fsaverage6', 'label', 'HCP-MMP1');

maskFsavg6 = fullfile(fs, 'fsaverage6', 'label', 'lh.BA1-4_mask.mgz');
if ~exist(maskFsavg6, 'file')
    tmpl = MRIread(fullfile(fs, 'fsaverage6', 'label', 'lh.BA9-46-7-40_mask.mgz'));
    tmpl.vol(:) = 0;
    for lb = {'lh.L_4_ROI.label','lh.L_3a_ROI.label','lh.L_3b_ROI.label','lh.L_1_ROI.label','lh.L_2_ROI.label'}
        ld = read_label('', fullfile(glasserFsavg6, lb{1}));
        tmpl.vol(ld(:,1)+1) = 1;
    end
    MRIwrite(tmpl, maskFsavg6);
    fprintf('Created %s\n', maskFsavg6);
end

% yellow overlay for fsaverage6 only
roiFsavg6 = sprintf(':overlay=%s:overlay_color=0,255,255,0,1,255,255,0:overlay_threshold=0.5,1', maskFsavg6);

% =====================================================================
% === OPTION D: sky blue → green → yellow → orange → red → purple ===
%
%   1  thumb   — sky blue  [  0, 150, 255]
%   2  index   — green     [  0, 255,   0]
%   3  middle  — yellow    [255, 255,   0]
%   4  ring    — orange    [255, 128,   0]
%   5  pinky   — red       [255,   0,   0]
%   6  sixth   — purple    [ 48,   0, 211]  (Imagery only)
% =====================================================================
colorsD5 = '1,0,150,255,2,0,255,0,3,255,255,0,4,255,128,0,5,255,0,0';
colorsD6 = [colorsD5 ',6,48,0,211'];
ovD5 = @(path) sprintf(':overlay=%s:overlay_custom=%s:overlay_threshold=0.5,5', path, colorsD5);
ovD6 = @(path) sprintf(':overlay=%s:overlay_custom=%s:overlay_threshold=0.5,6', path, colorsD6);

% 1. Execution — fsaverage6
surf = fullfile(fs, 'fsaverage6', 'surf', 'lh.inflated');
cmdD1 = [fvBin ' -f ' surf ...
    ovD5(fullfile(d,'Execution6','fsaverage6','ses-01','lh.fingermap_1.mgz')) ...
    ovD5(fullfile(d,'Execution6','fsaverage6','ses-02','lh.fingermap_2.mgz')) ...
    ovD5(fullfile(d,'Execution6','fsaverage6','ses-03','lh.fingermap_3.mgz')) ...
    roiFsavg6 ' --viewport 3d &'];
system(cmdD1);

% 2. Execution — fsnative sub-0688
surf = fullfile(fs, 'sub-0688', 'surf', 'lh.inflated');
cmdD2 = [fvBin ' -f ' surf ...
    ovD5(fullfile(d,'Execution_native','sub-0688','ses-01','lh.fingermap_1.mgz')) ...
    ovD5(fullfile(d,'Execution_native','sub-0688','ses-02','lh.fingermap_2.mgz')) ...
    ovD5(fullfile(d,'Execution_native','sub-0688','ses-03','lh.fingermap_3.mgz')) ...
    ' --viewport 3d &'];
system(cmdD2);

% 3. Imagery — fsaverage6
surf = fullfile(fs, 'fsaverage6', 'surf', 'lh.inflated');
cmdD3 = [fvBin ' -f ' surf ...
    ovD6(fullfile(d,'Imagery6','fsaverage6_p10','ses-01','lh.fingermap_1.mgz')) ...
    ovD6(fullfile(d,'Imagery6','fsaverage6_p10','ses-02','lh.fingermap_2.mgz')) ...
    ovD6(fullfile(d,'Imagery6','fsaverage6_p10','ses-03','lh.fingermap_3.mgz')) ...
    roiFsavg6 ' --viewport 3d &'];
system(cmdD3);

% 4. Imagery — fsnative sub-0688
surf = fullfile(fs, 'sub-0624', 'surf', 'lh.inflated');
cmdD4 = [fvBin ' -f ' surf ...
    ovD6(fullfile(d,'Imagery_native','sub-0624','ses-01','lh.fingermap_1.mgz')) ...
    ovD6(fullfile(d,'Imagery_native','sub-0624','ses-02','lh.fingermap_2.mgz')) ...
    ovD6(fullfile(d,'Imagery_native','sub-0624','ses-03','lh.fingermap_3.mgz')) ...
    ' --viewport 3d &'];
system(cmdD4);

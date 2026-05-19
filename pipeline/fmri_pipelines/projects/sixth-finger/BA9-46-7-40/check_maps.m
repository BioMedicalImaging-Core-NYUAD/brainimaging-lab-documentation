bidsDir = '/Users/hha243/Library/CloudStorage/Box-Box/sixthfinger-test';
fsHome  = '/Applications/freesurfer/8.1.0';
fvBin   = fullfile(fsHome, 'bin', 'freeview');

fs   = fullfile(bidsDir, 'derivatives', 'freesurfer');
d    = fullfile(bidsDir, 'derivatives');
base = fullfile(d, 'Imagery6_BA9-46-7-40', 'fsaverage6');

ov = @(hemi, ses) sprintf(':overlay=%s:overlay_color=heat:overlay_threshold=2,8', ...
    fullfile(base, sprintf('ses-%02d', ses), sprintf('%s.thumb_tstat_%d.mgz', hemi, ses)));

surf_lh = fullfile(fs, 'fsaverage6', 'surf', 'lh.inflated');
surf_rh = fullfile(fs, 'fsaverage6', 'surf', 'rh.inflated');

annot_lh = fullfile(fs, 'fsaverage6', 'label', 'lh.HCP-MMP1.annot');
annot_rh = fullfile(fs, 'fsaverage6', 'label', 'rh.HCP-MMP1.annot');

cmd = [fvBin ...
    ' -f ' surf_lh ov('lh',1) ov('lh',2) ov('lh',3) ':annot=' annot_lh ...
    ' -f ' surf_rh ov('rh',1) ov('rh',2) ov('rh',3) ':annot=' annot_rh ...
    ' --viewport 3d &'];
system(cmd);


%%
bidsDir = '/Users/hha243/Library/CloudStorage/Box-Box/sixthfinger-test';
fsHome  = '/Applications/freesurfer/8.1.0';
fvBin   = fullfile(fsHome, 'bin', 'freeview');

fs   = fullfile(bidsDir, 'derivatives', 'freesurfer');
d    = fullfile(bidsDir, 'derivatives');
base = fullfile(d, 'Imagery6_BA9-46-7-40', 'fsaverage6');

% t-stat overlay (activation)
ov = @(hemi, ses) sprintf(':overlay=%s:overlay_color=heat:overlay_threshold=2,8', ...
    fullfile(base, sprintf('ses-%02d', ses), sprintf('%s.sixth_tstat_%d.mgz', hemi, ses)));

% ROI mask overlay — solid yellow, semi-transparent, outline only
roi = @(hemi) sprintf(':overlay=%s:overlay_color=0,255,255,255,1,0,255,255:overlay_threshold=0.5,1', ...
    fullfile(fs, 'fsaverage6', 'label', sprintf('%s.BA9-46-7-40_mask.mgz', hemi)));

surf_lh = fullfile(fs, 'fsaverage6', 'surf', 'lh.inflated');
surf_rh = fullfile(fs, 'fsaverage6', 'surf', 'rh.inflated');

cmd = [fvBin ...
    ' -f ' surf_lh ov('lh',1) ov('lh',2) ov('lh',3) roi('lh') ...
    ' -f ' surf_rh ov('rh',1) ov('rh',2) ov('rh',3) roi('rh') ...
    ' --viewport 3d &'];
system(cmd);

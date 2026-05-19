bidsDir = '/Users/hha243/Library/CloudStorage/Box-Box/sixthfinger-test';
fsHome  = '/Applications/freesurfer/8.1.0';

task = 'Execution';
ses  = 'ses-03';
hemi = 'lh';

setenv('FREESURFER_HOME', fsHome);
setenv('SUBJECTS_DIR', fullfile(bidsDir, 'derivatives', 'freesurfer'));

surf    = fullfile(bidsDir, 'derivatives', 'freesurfer', 'fsaverage6', 'surf', [hemi '.inflated']);
overlay = fullfile(bidsDir, 'derivatives', 'group_fsavg6', task, ses, [hemi '.fingermap.mgz']);
fv      = fullfile(fsHome, 'bin', 'freeview');

cmd = sprintf('%s -f %s:overlay=%s:overlay_color=colorwheel,inverse:overlay_threshold=1,5 &', ...
    fv, surf, overlay);
system(cmd);

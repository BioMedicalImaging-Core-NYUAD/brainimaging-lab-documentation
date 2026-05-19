%% Visualize finger maps in freeview
% View the finger beta maps for the sixthfinger project

% Automatically detect bidsDir relative to this script's location
% (works for any user as long as the project folder structure is intact)
bidsDir = fullfile(getenv('HOME'), 'Library', 'CloudStorage', 'Box-Box', 'sixthfinger-test');
addpath("helper")



% Set up FreeSurfer env
fsHome  = '/Applications/freesurfer/8.1.0';

setenv('FREESURFER_HOME', fsHome);
setenv('SUBJECTS_DIR', fullfile(bidsDir, 'derivatives', 'freesurfer'));

surf    = fullfile(bidsDir, 'derivatives', 'freesurfer', 'fsaverage', 'surf', 'lh.inflated');
overlay = fullfile(bidsDir, 'derivatives', 'group', 'Execution', 'ses-02', 'lh.fingermap.mgz');
fv      = fullfile(fsHome, 'bin', 'freeview');

cmd = sprintf('%s -f %s:overlay=%s:overlay_color=colorwheel:overlay_threshold=1,5 &', fv, surf, overlay);
system(cmd);

% ---------------------

% view_fv(subject, bidsDir, 'l' ['Execution/' ses '/index'], ['Imagery/' ses '/index']);
% 
% view_fv(subject, bidsDir, 'l' 'Execution/ses-01/middle','Execution/ses-02/middle','Execution/ses-03/middle')
% view_fv(subject, bidsDir, 'l','Imagery/ses-01/sixth','Imagery/ses-02/sixth')
% view_fv(subject, bidsDir, 'l','Execution/ses-02/thumb','Execution/ses-02/pinky','Imagery/ses-02/sixth')
% view_fv(subject, bidsDir, 'l', ['Execution/' ses '/thumb'], ['Execution/' ses '/index'], ['Execution/' ses '/middle'], ['Execution/' ses '/ring'], ['Execution/' ses '/pinky']);

% view_fv(subject, bidsDir, 'l', ['Imagery/' ses '/thumb'], ['Imagery/' ses '/index'], ['Imagery/' ses '/middle'], ['Imagery/' ses '/ring'], ['Imagery/' ses '/pinky'], ['Imagery/' ses '/sixth']);
% view_fv(subject, bidsDir, 'l', ['Imagery/' ses '/sixth']);
% view_fv(subject, bidsDir, 'l', ['Execution/' ses '/thumb']);
% view_fv(subject, bidsDir, 'l', 'Execution/ses-01/fingermap')
% view_fv(subject, bidsDir, 'l', 'Imagery/ses-01/fingermap')


function [projectDir, freesurferDir, githubDir, resultsdir]=set_up(username)

% User specific locations
switch(username)
    case {'omnia'}
       %projectDir = '/Volumes/Bas/MRI_Workshop/Module_3/';
       projectDir = '/Volumes/Vision/MRI/Workshop2023/Module_3/';
       freesurferDir = '/Applications/freesurfer/7.2.0';
       %githubDir = '/Volumes/Bas/MRI_Workshop/Module_3/github';
       githubDir = '/Volumes/Vision/MRI/Workshop2023/Module_3/github';
       resultsdir = fullfile(projectDir, 'derivatives/results');

    case {'workshop'}
       projectDir = '/Users/nyuad/Desktop/Module_3/';
       freesurferDir = '/Applications/freesurfer/7.2.0';
       githubDir = '~/Desktop/Module_3/github'; 
       resultsdir = fullfile(projectDir, 'derivatives/results');
      
end

% Setup toolboxes
addpath(genpath(fullfile(githubDir, 'MRI_tools'))); % https://github.com/WinawerLab/MRI_tools
addpath(genpath(fullfile(githubDir, 'GLMdenoise'))); % https://github.com/cvnlab/GLMdenoise
addpath(genpath(fullfile(githubDir, 'jsonlab'))); % https://github.com/fangq/jsonlab
addpath(genpath(fullfile(githubDir, 'cvncode'))); % https://github.com/cvnlab/cvncode
addpath(genpath(fullfile(githubDir, 'knkutils'))); % https://github.com/cvnlab/knkutils
addpath(genpath(fullfile(githubDir, 'gifti'))); % https://github.com/gllmflndn/gifti
addpath(genpath(fullfile(githubDir, 'atlasmgz'))); % https://github.com/WinawerLab/atlasmgz
addpath(genpath(fullfile(githubDir, 'MultipleTestingToolbox'))); % for fdr correction
addpath(genpath(fullfile(githubDir, 'retinotopy-nyuad')));

% Freesurfer settings
PATH = getenv('PATH'); setenv('PATH', [PATH ':' freesurferDir '/bin']); % add freesurfer/bin to path
setenv('FREESURFER_HOME', freesurferDir);
addpath(genpath(fullfile(freesurferDir, 'matlab')));
setenv('SUBJECTS_DIR', [projectDir '/derivatives/freesurfer']); 

% Figure setups 
reset(groot);

end 


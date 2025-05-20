clear all; close all; clc;

% Set information for your experiment and fmriprep output

subject = 'sub-0665';
nRuns = 3;


task = 'fingertapping';
space = 'fsnative';
fileType = '.mgh';
TR = 1.0; % in seconds Repetition Time
hemi = {'L';'R'};

if ispc
    bidsDir = '\\rcsfileshare.abudhabi.nyu.edu\mri\projects\MS_osama\hadiBIDS\fmriprep_output_from_HPC';
elseif isunix
    bidsDir = '\mnt\rcs_mri';
end
    
    
setenv('FS_LICENSE', '/Applications/freesurfer/7.4.1/license.txt');


datafiles = cell(1,nRuns); % initialize for all the runs
idx_hemi = cell(numel(hemi),nRuns);  % Left first then right 

for iRun = 1:nRuns

    % file path
    subDir = sprintf('%s/derivatives/fmriprep/%s/func',bidsDir,subject);

    func = cell(2,1); % initialize for 2 hemi
    
    for iH = 1:numel(hemi)

        fileName = sprintf('%s/%s_task-%s_run-%s_hemi-%s_space-%s_bold.func',subDir,subject,task,sprintf('%02d',iRun),hemi{iH},space);

        input = [fileName '.gii'];
        output = [fileName fileType]; % the file type that we want to load
        disp(['Filename ', input])
        % check to see if data exists in the desired fileType, if not,
        % mir_convert file from gii
        if ~exist(output)
            disp(['File does not exist in ' fileType ' format, converting from .gii ...'])
            system(['mri_convert ' input ' ' output]);
        else
            disp(['File exists for Run ', num2str(iRun)])
        
        end
        
        disp(['Loading: ' output])

        tmp = MRIread(output);
        idx_hemi{iH,iRun} = tmp.nvoxels;
        func{iH} = squeeze(tmp.vol);
    end
    datafiles{iRun} = cat(1,func{:});
    datafiles{iRun} = datafiles{iRun}';
end


%% Load noise regressors csv
 
fileName_noise_regressors = sprintf('%s/%s_task-%s_run-%s_desc-confounds_timeseries.tsv', subDir,subject,task,sprintf('%02d',iRun));

noise_regressors_data = cell(1, nRuns);

% We have 381 features in the .tsv, we need to extract the noise regressors

regressors_names = {'trans_x', 'trans_y', 'trans_z', 'rot_x', 'rot_y', 'rot_z'};

for iRun = 1:nRuns

    noise_regressors_data{iRun} = readtable(fileName_noise_regressors, 'FileType','text');
    noise_regressors_data{iRun} = noise_regressors_data{iRun}(:, regressors_names);
    %noise_regressors_data{iRun} = table2array(noise_regressors_data{iRun})';
end



%% Visualise the data


% ----- USER CHOICES ---------------------------------------------------
runIdx   = 2;        % which run?  1 … numel(datafiles)
voxelIdx = 100000;     % which voxel/vertex index?

figure('Color','w');
tl = tiledlayout(1,2,'TileSpacing','compact');  % 1 row × 2 columns


plot_voxel(runIdx, voxelIdx, datafiles, TR);

% Compute FFT for the chosen voxel, chosen run

plot_fft(runIdx, voxelIdx, datafiles, TR);


%% Filtering

% For each voxel filter all frequencies below 1/40Hz = 0.25 Hz
          % <- your TR (s)
f_hp   = 1/40;         % 0.025 Hz cut-off
order  = 2;            % 2-pole Butterworth (→ 12 dB/oct per pass)
fs   = 1/TR;                               % sampling rate (Hz)
[b,a] = butter(order, f_hp/(fs/2), 'high');% design once

nRuns        = numel(datafiles);
datafiles_hp = cell(size(datafiles));

for r = 1:nRuns
    X = datafiles{r};

    mu = mean(X,1);
    % First dimension of X in filtfilt must be time
    % TODO: check that X has time in first dimension before launching this
    X_filt = filtfilt(b, a, X);            % zero-phase
    X_rest = X_filt+mu;         % Added the mean after filtering, because if not the percentage_change next would become very big (since the mean is 0)
    datafiles_hp{r} = X_rest;

end


%% Visualise the data after filtering


figure('Color','w');
tl = tiledlayout(1,2,'TileSpacing','compact');  % 1 row × 2 columns

% ----- USER CHOICES ---------------------------------------------------
runIdx   = 2;        % which run?  1 … numel(datafiles)
voxelIdx = 100000;     % which voxel/vertex index?

plot_voxel(runIdx, voxelIdx, datafiles_hp, TR);

% Compute FFT for the chosen voxel, chosen run

plot_fft(runIdx, voxelIdx, datafiles_hp, TR);


%% Convert to signal change percentage

% converting to % signal change

%Compute the average value

data = datafiles_hp;

% Prepare cell arrays to store outputs
average_signals = cell(1, nRuns);
percent_change_signals = cell(1, nRuns);

for i = 1:nRuns

    % Extract the data matrix
    this_data = data{i};  % Size: 300 x 320721

    % Step 1: Compute average across the 1st dimension (rows)
    % Average the signal for each voxel
    
    avg_signal = mean(this_data, 1);  % Result is 1 x 320721
    

    % Step 2: Compute percent signal change for each point
    % Expand avg_signal to match the size of this_data
    avg_signal_expanded = repmat(avg_signal, size(this_data, 1), 1);  % 300 x 320721
    
    percent_change = ((this_data - avg_signal_expanded) ./ avg_signal_expanded) * 100;

    % Store the results
    average_signals{i} = avg_signal;
    percent_change_signals{i} = percent_change;

end


%% Plot percentage change signal


figure('Color','w');
tl = tiledlayout(1,1,'TileSpacing','compact');  % 1 row × 2 columns

runIdx   = 2;        % which run?  1 … numel(datafiles)
voxelIdx = 100000;     % which voxel/vertex index?

plot_percent_change(runIdx, voxelIdx, percent_change_signals, TR);

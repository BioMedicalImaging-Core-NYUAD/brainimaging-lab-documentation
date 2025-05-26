%%

% load data into 1 by nRun cell array

% create design matrix  n by m 


EEG_FMRI_DATA_PATH = getenv('EEG_FMRI_DATA');

%datapath = sprintf('%s\\%s\\%s\\matlab', EEG_FMRI_DATA_PATH, task, subject);
datapath = fullfile(EEG_FMRI_DATA_PATH, task, subject, 'matlab');
number_conditions = 5;  % Five fingers
number_regressors_motion = 6;  % translation x,y,z and rotation x,y,z 
number_regressors_extra = 2;   % constant regressor and drift
n_cols_total = number_conditions+number_regressors_motion+number_regressors_extra
run_length = 300; %In seconds (the TR was 1 seconds)
nRuns = 3;
block_size = 20;

designMatrix = zeros(run_length, n_cols_total,  nRuns);

const_regress_vector = repelem(1, run_length)';

drift_regress_vector = 1:300;
drift_regress_vector = drift_regress_vector';

gam_x_values = linspace(1,block_size, block_size);

hrf = gampdf(gam_x_values,2,3);

% Plot hrf
% What do we need to ensure?

plot(gam_x_values,hrf);

for iRun=1:nRuns

    file_array_name = ['fingertap_0', num2str(iRun), '.csv'];
    fullpath = fullfile(datapath, file_array_name);
    data_output = readtable(fullpath);
    

    % the designmatrix is filled from data_output
    % the first column is for finger number 1 and so on, the last columns are
    % for the noise regressors
    % in data_output we look at the blocktype column, each block is 20 seconds,
    % so we need to create a repetition of 20 times the values

    condition_vector = repelem(data_output.blocktype, 20);
    
    % Determine the number of rows (same as number of elements in vector)
    num_rows = length(condition_vector);
    
    % Determine the number of columns (max value in vector)
    num_cols = max(condition_vector);
    
    % Preallocate binary matrix
    binary_matrix = zeros(num_rows, num_cols);
    
    % Fill matrix using subscript indexing
    row_indices = (1:num_rows)';
    col_indices = condition_vector(:);  % Ensure it's a column vector
    
    % Linear indexing to set the appropriate entries to 1
    binary_matrix(sub2ind(size(binary_matrix), row_indices, col_indices)) = 1;

    designMatrix(:,1:number_conditions,iRun) = binary_matrix;
    
    % The noise regressors have already been loaded in load_data.m

    % PUTI - add constant 1s as a regressor, add linear drift 1:300 as
    % another regressor DONE D

    designMatrix(:,number_conditions+1:number_regressors_motion+number_conditions,iRun ) = table2array(noise_regressors_data{iRun});
    
    designMatrix(:, number_conditions+number_regressors_motion+1:n_cols_total, iRun) = [const_regress_vector, drift_regress_vector] ;
     
    
    % PUTI - - remember to chop the left overs

    for col = 1:number_conditions
        convolved_signal = conv(designMatrix(:,col,iRun),hrf);
        convolved_signal = convolved_signal(1:run_length);  % Chop the leftovers
        designMatrix(:,col,iRun) = convolved_signal;
            % Chop off the left overs
        %plot(1:run_length, convolved_signal);
    end
    
   
end

%% Learn GLM

% Y = X.B + Epsilon, with Epsilon = 0
% B = pinv(X) * Y

betas = cell(1, nRuns);


% Three approaches are possible to handle the different runs

% Either concatenate the designmatrix and data for all the runs
% OR you can average the data per run and then estimate beta (this can help
% reduce the noise)
% Or estimate betas per run and then average the betas

% WE wil try all three ways and see which one produces better results



%% Method 1, concatenation of design matrices across runs


% Concatenate the designMatrix of shape (runtime,  features, nRuns)
% New shape (runtime x nRuns, features)
designMatrix_concatenated = reshape( permute(designMatrix, [1 3 2]), [], size(designMatrix,2) );

% Concatenate the datafiles (bold signal array) of shape (runtime, nVoxels,
% nRuns


percent_change_signals_concatenated = vertcat(percent_change_signals{:}); 


betas = pinv(designMatrix_concatenated) * percent_change_signals_concatenated; % done per run separately

% Save results in surface space

save betas betas
%%
load betas betas
% Get betas for the index finger
% The index finger was numbered as block_type = 2, corresponding to the
% second column of our designMatrix

finger_number = 2;

% We need to get each TR of the index finger block and 40 seconds extended after
% the index block finished and their betas




% Find the voxels that has the largest betas for the index finger

% For now we will just get the betas of the index finger without the ones
% for the (+40 seconds)

betas_index = betas(2,:);

% Find the voxels for which the betas are maximal


% isolated+extended
% TR's


% save as mgz
%TODO filter on the maximum betas_index
% largest betas for index finger +40seconds after the index is pressed

% Make a matrix where the finger is pressed on the rows, and the 40 seconds
% next (random fingers) on the column



val = betas_index;
valName = 'betas_index';

%fspth = '\\rcsfileshare.abudhabi.nyu.edu\mri\projects\MS_osama\hadiBIDS\fmriprep_output_from_HPC/derivatives/fmriprep/sub-0665/func';

mgz_header_template_path = fullfile(bidsDir, 'derivatives', 'freesurfer', subject, 'mri', 'orig.mgz' );

resultsdir = '.';
addpath( genpath( fullfile( getenv('FREESURFER_HOME'), 'fsfast', 'toolbox' ) ) );


mgz = MRIread(mgz_header_template_path);

mgz.vol = [];

leftidx = idx_hemi{1,1};
rightidx = idx_hemi{2,1};

mgz.vol = val(1:leftidx);


MRIwrite(mgz, fullfile(resultsdir, ['lh.' valName '.mgz']));
mgz.vol = val((leftidx+1):end);
MRIwrite(mgz, fullfile(resultsdir, ['rh.' valName '.mgz']));



%% To visualise in freeview







%% Visualise the surface

% ---- Set file paths ----
subject_id = 'sub-0665';
fs_dir     = '\\rcsfileshare.abudhabi.nyu.edu\mri\projects\MS_osama\hadiBIDS\fmriprep_output_from_HPC\derivatives\freesurfer';
surf_file  = fullfile(fs_dir, subject_id, 'surf', 'lh.inflated');
beta_file  = fullfile(pwd, 'lh.betas_index.mgz');  % Or adjust path if stored elsewhere

% ---- Load the subject’s inflated surface ----
[vertices, faces] = read_surf(surf_file);   % returns Nx3 and Mx3 (0-based faces)
faces = faces + 1;                           % convert to MATLAB 1-based indexing

% ---- Load beta values (mgz format) ----
b = MRIread(beta_file);
beta_vals = b.vol(:);   % should be a vector with 163842 entries for full surface

% ---- Plot ----
figure('Color','w');
trisurf(faces, vertices(:,1), vertices(:,2), vertices(:,3), beta_vals, ...
    'EdgeColor','none', 'FaceAlpha', 1);
axis equal off;
lighting gouraud; camlight headlight;
colormap jet; colorbar;
title('LH – Beta (Index Finger) in fsnative space');




%% Test try plot


% ------------------------------------------------------------
%  CONFIGURE PATHS
% -------------------------------------------------------------
subject_id  = 'sub-0665';

% FreeSurfer derivatives root (recon‑all directory)
fs_dir  = fullfile( ...
    '\\rcsfileshare.abudhabi.nyu.edu\mri\projects\MS_osama\hadiBIDS', ...
    'fmriprep_output_from_HPC', 'derivatives', 'freesurfer' );

% Where you want to save the new mgz files
results_dir = pwd;          % current folder (change if desired)

% Your beta vector (LH+RH) and the hemi‑index masks you already have
val        = betas_index;   % 1 × (LH+RH vertices)
leftidx    = idx_hemi{1};   % logical / index for LH vertices
rightidx   = idx_hemi{2};   % logical / index for RH vertices
valName    = 'betas_index';

% ------------------------------------------------------------
%  WRITE LH AND RH .mgz FILES WITH A VALID HEADER
% -------------------------------------------------------------
templ_path = fullfile(fs_dir, subject_id, 'surf', 'lh.thickness');
template   = MRIread(templ_path);  % clone header

% LH
template.vol      = val(leftidx);
template.volsize  = size(template.vol);
template.nframes  = 1;
lh_mgz = fullfile(results_dir, ['lh.' valName '.mgz']);
MRIwrite(template, lh_mgz);

% RH
template.vol      = val(rightidx);
template.volsize  = size(template.vol);
rh_mgz = fullfile(results_dir, ['rh.' valName '.mgz']);
MRIwrite(template, rh_mgz);

fprintf('Wrote:\n  %s\n  %s\n', lh_mgz, rh_mgz);

% ------------------------------------------------------------
%  LOAD SURFACES AND BETA VALUES
% -------------------------------------------------------------
% Surface geometry (inflated)
lh_surf = fullfile(fs_dir, subject_id, 'surf', 'lh.inflated');
rh_surf = fullfile(fs_dir, subject_id, 'surf', 'rh.inflated');

[vl, fl] = read_surf(lh_surf);  fl = fl + 1;   % LH vertices/faces
[vr, fr] = read_surf(rh_surf);  fr = fr + 1;   % RH

% Beta data
bl = MRIread(lh_mgz);  bl = bl.vol(:);
br = MRIread(rh_mgz);  br = br.vol(:);

% ------------------------------------------------------------
%  PLOT BOTH HEMISPHERES
% -------------------------------------------------------------
figure('Color','w'); tiledlayout(1,2,'TileSpacing','compact');

% --- LH ---
nexttile;
trisurf(fl, vl(:,1), vl(:,2), vl(:,3), bl, ...
        'EdgeColor','none');
axis equal off; view([-90 0]);  % lateral
lighting gouraud; camlight headlight;
title('LH – β (index finger)'); material dull;

% --- RH ---
nexttile;
trisurf(fr, vr(:,1), vr(:,2), vr(:,3), br, ...
        'EdgeColor','none');
axis equal off; view([90 0]);   % lateral
lighting gouraud; camlight headlight;
title('RH – β (index finger)'); material dull;

% Shared colour‑scale
cmin = -max(abs([bl; br])); cmax = -cmin;
colormap jet; caxis([cmin cmax]); colorbar;


%% Find the voxels where there is a peak for the betas of the index finger

% the average on the 40 seconds should eliminate the activity going on
% during fingertap at other fingers

% betas 
% largest


%% Generate ROI labels from the Glasser Atlas in subject native space (fsnative)

% the script createAtlasLabels.sh will load different Atlases for which it
% knows the location of each ROI on the atlas space and will convert them
% into the individual space of each subject


atlas_file_path = 'label/Glasser2016';




for ROI = 1:number_ROIs

% load ROI using GUI select
% Open a file selection dialog for the relevant file type (e.g., .txt or .mat)
[filename, pathname] = uigetfile({'*.*', 'All Files (*.*)'}, 'Select ROI Label File');


% Check if a file was selected
if isequal(filename, 0)
    disp('No file selected.');
else
    fullpath = fullfile(pathname, filename);
    % Pass the selected file to your function
    ROI_voxels_mask = read_ROIlabel(fullpath);
end



%% Use the ROI as filter for betas

% The ROI_voxels_mask is a list of the voxels number that belongs to the ROI
% W're assurming that nothing in the code had changed the order of the
% voxel dimensions in the betas variable


filtered_betas = betas(:, ROI_voxels_mask);






%%


%

% Path to the folder with ROI label files
atlas_file_path = 'label/Glasser2016';

% Get list of all label files (assuming .label or .txt, adjust as needed)
roi_files = dir(fullfile(atlas_file_path, '*.label'));

% Preallocate
nROIs = numel(roi_files);
mean_betas_per_roi = zeros(nROIs, 1);
roi_names = cell(nROIs, 1);

for i = 1:nROIs
    % Full path to ROI label file
    roi_path = fullfile(roi_files(i).folder, roi_files(i).name);
    
    % Read voxel indices for this ROI
    ROI_voxels_mask = read_ROIlabel(roi_path);   % indices into betas

    % Select beta values for this ROI
    betas_roi = betas(:, ROI_voxels_mask);       % [nRegressors × ROI voxels]
    
    % Average across voxels, then across regressors (or just one regressor if needed)
    mean_betas_per_roi(i) = mean(betas_roi(:));  % scalar mean

    % Store the ROI name
    roi_names{i} = roi_files(i).name;
end

% Find the ROI with the maximum average beta
[~, max_idx] = max(mean_betas_per_roi);
max_roi_name = roi_names{max_idx};
max_roi_value = mean_betas_per_roi(max_idx);

fprintf('ROI with max beta = %s (avg beta = %.4f)\n', max_roi_name, max_roi_value);


%% 

% ----- Load voxel indices for the winning ROI -------------------------
chosen_roi_file = fullfile(roi_files(max_idx).folder, roi_files(max_idx).name);
ROI_voxels_mask = read_ROIlabel(chosen_roi_file);

% ----- Initialize for time series collection --------------------------
nRuns = numel(datafiles);
avg_ts_all_runs = [];

for r = 1:nRuns
    X = datafiles{r};   % assumed [time × voxels]
    
    % Extract ROI voxels
    roi_ts = X(:, ROI_voxels_mask);  % [time × ROI_voxels]
    
    % Average across voxels
    avg_ts = mean(roi_ts, 2);        % [time × 1]
    
    % Optionally concatenate across runs (if aligned), or store separately
    avg_ts_all_runs = [avg_ts_all_runs; avg_ts];  % vertical concat
end

% ----- Plot -----------------------------------------------------------
TR = 1.0;  % <- Set your TR
t = (0:numel(avg_ts_all_runs)-1) * TR;

figure('Color','w');
plot(t, avg_ts_all_runs, 'LineWidth', 1.5);
xlabel('Time (s)');
ylabel('BOLD Intensity (a.u.)');
title(sprintf('Average Time Series – ROI: %s', roi_files(max_idx).name), 'Interpreter','none');
grid on;










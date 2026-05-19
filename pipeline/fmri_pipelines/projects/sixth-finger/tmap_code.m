addpath('/Users/hha243/Desktop/MacBook/NYUPostDoc/MatlabFuncs/spm')

gii_file1 = '/Users/hha243/Desktop/MacBook/NYUPostDoc/CAIRprojects/EEGfMRI/sixth-finger-fmri/derivatives-puti/derivatives/fmriprep/sub-0853/ses-01/func/sub-0853_ses-01_task-motor_run-01_hemi-L_space-fsnative_bold.func.gii';
g = gifti(gii_file1);
bold_surface_data = g.cdata;



TR = 1;
hrf = spm_hrf(TR);
num_timepoints = size(design_matrix, 1);
num_regressors = size(design_matrix, 2);
X_convolved = zeros(num_timepoints, num_regressors);
for i = 1:num_regressors
    regressor = design_matrix(:, i);
    convolved_regressor = conv(regressor, hrf);
    X_convolved(:, i) = convolved_regressor(1:num_timepoints);
end


Y = bold_surface_data'; 

X = [X_convolved, ones(num_timepoints, 1)];

beta_weights = X \ Y;

disp('Beta weights done')
c = [1/5, 1/5, 1/5, 1/5, 1/5, 0]';

con_map = c' * beta_weights;

residuals = Y - X * beta_weights;
degrees_of_freedom = num_timepoints - size(X, 2);
variance = sum(residuals.^2) / degrees_of_freedom;
std_error = sqrt(variance * (c' * inv(X'*X) * c));

t_map = con_map ./ std_error;
output_data.cdata = t_map';
t_map_gii = gifti(output_data);

save(t_map_gii, 'my_t_map.gii');

disp('Successfully saved t-map to my_t_map.gii');
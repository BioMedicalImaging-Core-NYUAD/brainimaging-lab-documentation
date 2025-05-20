%% Classification and plots

%% Classification from Puti's workshop tutorial
% we got to section 4.2


% Which voxels are the ones classifying the conditions well?
%% Visualise data

percent_change_signals_array = cat(3, percent_change_signals{:});

% we need to sort the data according to the conditions in the designMatrix

% Build a condition_matrix such that it has a shape of (n_run, n_conditions,  

% We want to plot each condition alone (5 plots), for 50 voxels (on the y
% axis) and then across runs (3 runs), the heat map will be the activity of
% that voxel averaged over time for this run

% Let us average over time for one condition

% Let us consider condition = 1

percent_change_signals_array_cat = cat(2, percent_change_signals_array, designMatrix(:, 1:5,:));

% For condition 1, for voxedl 50, for run 1 lets get the condition vector
% in each run, the condition appears for 3 blocks each 20 seconds = 60 seconds, 

start_nvox = 150000; 
end_nvox = 150050;  % How many Voxels we want to show in the plot? We would take from start_nvox to end_nvox
n_vox = end_nvox-start_nvox;

TR_per_run = sum( designMatrix(:,1) == 1 );

TR_per_condition = TR_per_run*nRuns;

conditions_total = zeros(TR_per_condition, number_conditions, n_vox);
for iCon = 1:number_conditions
    for voxel = 1:n_vox
        pc = squeeze(percent_change_signals_array_cat(:, voxel, :)); 
        dm = squeeze(designMatrix(:, iCon, :));    
        %condition_1 = percent_change_signals_array_cat(:,voxel, :) .*designMatrix(:,iCon,:);
        condition = pc .* dm;
        
        non_zero_cols = arrayfun(@(c) nonzeros(condition(:,c)), 1:size(condition,2), 'UniformOutput',false);
        v = vertcat(non_zero_cols{:});
        conditions_total(:, iCon, voxel) = v;
   end
end


% Plot per TR

figure(1);

tiledlayout(1,5);

conditions_total_r = reshape(conditions_total,TR_per_condition, n_vox, []);

for condIdx = 1:number_conditions
    nexttile,
    imagesc(conditions_total_r(:, :,condIdx),[min(conditions_total_r(:)) max(conditions_total_r(:))]);  % Show the activity pattern
    xlabel('Voxel');  % Label the x-axis
    ylabel('TR');    % Label the y-axis
    title(sprintf('Condition %d', condIdx));  % Title for this subplot
    colormap(gray);   % Use grayscale colors
    colorbar;         % Show the color scale
end



%% Plot per run
% Let us average the TR's over the runs for each condition and for each
% voxel

% Each run had 60 TR per condition, they are placed in order from 1 to 180

tmp = reshape(conditions_total_r, TR_per_run, nRuns, n_vox, number_conditions);

% Mean over first dimension

conditions_total_r_avg_runs = squeeze( mean(tmp, 1) );   % → size: [nRuns × nVoxels × nConds]


figure(1);

tiledlayout(1,5);

for condIdx = 1:number_conditions
    nexttile,
    imagesc(conditions_total_r_avg_runs(:, :,condIdx),[min(conditions_total_r_avg_runs(:)) max(conditions_total_r_avg_runs(:))]);  % Show the activity pattern
    xlabel('Voxel');  % Label the x-axis
    ylabel('Run');    % Label the y-axis
    title(sprintf('Condition %d', condIdx));  % Title for this subplot
    colormap(gray);   % Use grayscale colors
    colorbar;         % Show the color scale
end



%% Average activity across condition and runs
% continue from 4.2

conditions_total_r = reshape(conditions_total,TR_per_condition, n_vox, []);

conditions_total_r_avg_time = mean(conditions_total_r)
function [outputArg1,outputArg2] = plot_voxel(runIdx,voxelIdx, datafiles, TR)



% ----- EXTRACT THE TIME-SERIES ---------------------------------------
X = datafiles{runIdx};              % [vox × T] (your current orientation)
if size(X,1) < size(X,2)            % safety: flip if it’s [T × vox]
    X = X';
end

ts = X(voxelIdx, :);                % 1 × T vector
t  = (0:numel(ts)-1) * TR;          % time axis (s)

% ----- PLOT -----------------------------------------------------------

nexttile;
plot(t, ts, 'LineWidth', 1);
xlabel('Time (s)');  ylabel('Bold signal Percentage Change (%)');
title(sprintf('Run %d   –   Voxel %d', runIdx, voxelIdx));
grid on;

end


function [outputArg1,outputArg2] = plot_fft(runIdx,voxelIdx, datafiles, TR)
%PLOT_FFT Summary of this function goes here
%   Detailed explanation goes here

% ----- EXTRACT THE TIME-SERIES ---------------------------------------
X = datafiles{runIdx};              % [vox × T] (your current orientation)
if size(X,1) < size(X,2)            % safety: flip if it’s [T × vox]
    X = X';
end

ts = X(voxelIdx, :);                % 1 × T vector
t  = (0:numel(ts)-1) * TR;          % time axis (s)


% -------- FFT of this voxel ------------------------------------------
N  = numel(ts);          % # time-points in this run
fs = 1/TR;               % sampling rate (Hz)

Y  = fft(ts);            % complex spectrum
P  = abs(Y/N).^2;        % power (variance) spectrum  –OR–  abs(Y/N) for amplitude

% keep positive-frequency half (0 … Nyquist)
half = 1:floor(N/2)+1;
f    = fs*(half-1)/N;    % frequency axis



nexttile;
semilogy(f, P(half), 'LineWidth',1);   % log power – change to plot() for linear
xlabel('Frequency (Hz)');
ylabel('Power  (a.u.)');
title(sprintf('FFT – Run %d,  Voxel %d', runIdx, voxelIdx));
grid on;
xlim([0 fs/2]);          % show the whole positive band
end


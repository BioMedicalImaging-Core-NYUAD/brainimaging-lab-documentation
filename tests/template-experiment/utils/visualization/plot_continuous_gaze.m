function plot_continuous_gaze(dataFileOrPa)
% PLOT_CONTINUOUS_GAZE - Plot continuous gaze trajectory as connected dots
% Usage: plot_continuous_gaze('circular_path_data.mat') or plot_continuous_gaze(pa)
%
% This function plots the continuous gaze tracking data recorded during
% the experiment. It shows:
% 1. Gaze trajectory as connected dots overlaid on the circular path
% 2. X position over time
% 3. Y position over time
% 4. Distance from center over time

if nargin < 1 || isempty(dataFileOrPa)
    % Default to data folder
    scriptDir = fileparts(mfilename('fullpath'));
    experimentDir = fullfile(scriptDir, '..', '..');
    dataFile = fullfile(experimentDir, 'data', 'circular_path_data.mat');
    S = load(dataFile, 'pa');
    if ~isfield(S, 'pa')
        error('plot_continuous_gaze:invalidData', 'File does not contain pa struct');
    end
    pa = S.pa;
elseif ischar(dataFileOrPa) || isstring(dataFileOrPa)
    % Input is a file path
    S = load(dataFileOrPa, 'pa');
    if ~isfield(S, 'pa')
        error('plot_continuous_gaze:invalidData', 'File does not contain pa struct');
    end
    pa = S.pa;
elseif isstruct(dataFileOrPa)
    % Input is the pa structure directly
    pa = dataFileOrPa;
else
    error('plot_continuous_gaze:invalidInput', 'Input must be a file path (string) or pa structure');
end

% Check if continuous gaze data exists
if ~isfield(pa.data, 'continuousGazeX') || ~isfield(pa.data, 'continuousGazeY')
    error('plot_continuous_gaze:missingData', 'Continuous gaze data not found. Run experiment with continuous tracking enabled.');
end

gazeX = pa.data.continuousGazeX(:);
gazeY = pa.data.continuousGazeY(:);
gazeTime = pa.data.continuousGazeTime(:);

% Filter out NaN values
valid = ~isnan(gazeX) & ~isnan(gazeY);
gazeXv = gazeX(valid);
gazeYv = gazeY(valid);
gazeTimev = gazeTime(valid);

if isempty(gazeXv)
    error('plot_continuous_gaze:noData', 'No valid gaze samples found.');
end

% Get screen center and radius for reference
% Try to get from VP structure if available, otherwise use defaults
if isfield(pa, 'screenCenter') && numel(pa.screenCenter) == 2
    center = pa.screenCenter(:)';
else
    % Default center (will be updated if we can find window center)
    center = [960, 540];
end

if isfield(pa, 'fixationRadiusPix')
    radius = pa.fixationRadiusPix;
else
    radius = 100; % Default radius
end

% Create figure
figure('Color','w', 'Position', [100, 100, 1200, 800]);

% Plot 1: Gaze trajectory with circular path overlay
subplot(2,2,1);
hold on;
% Draw circular path
haveViscircles = exist('viscircles','file') == 2;
if haveViscircles
    viscircles(center, radius, 'Color', 'k', 'LineWidth', 2, 'LineStyle', '--');
else
    rectangle('Position',[center(1)-radius, center(2)-radius, 2*radius, 2*radius], ...
              'Curvature',[1 1], 'EdgeColor','k', 'LineWidth',2, 'LineStyle','--');
end
% Draw crosshair at center
plot([center(1)-20 center(1)+20], [center(2) center(2)], 'k-', 'LineWidth', 1);
plot([center(1) center(1)], [center(2)-20 center(2)+20], 'k-', 'LineWidth', 1);
% Plot gaze trajectory as connected dots
plot(gazeXv, gazeYv, 'b-', 'LineWidth', 1.5, 'Marker', '.', 'MarkerSize', 8);
% Mark start and end
if length(gazeXv) > 0
    plot(gazeXv(1), gazeYv(1), 'go', 'MarkerSize', 12, 'MarkerFaceColor', 'g');
    plot(gazeXv(end), gazeYv(end), 'ro', 'MarkerSize', 12, 'MarkerFaceColor', 'r');
end
xlabel('X position (pixels)');
ylabel('Y position (pixels)');
title('Continuous Gaze Trajectory');
legend('Circular path', 'Center', 'Gaze path', 'Start', 'End', 'Location', 'best');
axis equal;
grid on;

% Plot 2: X position over time
subplot(2,2,2);
plot(gazeTimev, gazeXv, 'b-', 'LineWidth', 1.5);
hold on;
plot([gazeTimev(1), gazeTimev(end)], [center(1), center(1)], 'r--', 'LineWidth', 1);
xlabel('Time (seconds)');
ylabel('X position (pixels)');
title('Gaze X Position Over Time');
legend('Gaze X', 'Screen center', 'Location', 'best');
grid on;

% Plot 3: Y position over time
subplot(2,2,3);
plot(gazeTimev, gazeYv, 'b-', 'LineWidth', 1.5);
hold on;
plot([gazeTimev(1), gazeTimev(end)], [center(2), center(2)], 'r--', 'LineWidth', 1);
xlabel('Time (seconds)');
ylabel('Y position (pixels)');
title('Gaze Y Position Over Time');
legend('Gaze Y', 'Screen center', 'Location', 'best');
grid on;

% Plot 4: Distance from center over time
subplot(2,2,4);
distanceFromCenter = sqrt((gazeXv - center(1)).^2 + (gazeYv - center(2)).^2);
plot(gazeTimev, distanceFromCenter, 'b-', 'LineWidth', 1.5);
hold on;
plot([gazeTimev(1), gazeTimev(end)], [radius, radius], 'r--', 'LineWidth', 1);
xlabel('Time (seconds)');
ylabel('Distance from center (pixels)');
title('Gaze Distance from Center');
legend('Distance', 'Circular path radius', 'Location', 'best');
grid on;

% Print summary statistics
fprintf('\n=== Continuous Gaze Tracking Summary ===\n');
fprintf('Total samples recorded: %d\n', length(gazeXv));
if ~isempty(gazeTimev)
    fprintf('Total duration: %.2f seconds (%.2f minutes)\n', gazeTimev(end), gazeTimev(end)/60);
    if isfield(pa, 'gazeSampleInterval')
        fprintf('Sampling rate: %.2f Hz (every %.2f seconds)\n', 1/pa.gazeSampleInterval, pa.gazeSampleInterval);
    else
        fprintf('Sampling interval: 0.5 seconds (estimated)\n');
    end
    fprintf('Mean distance from center: %.2f pixels\n', mean(distanceFromCenter));
    fprintf('Std distance from center: %.2f pixels\n', std(distanceFromCenter));
    fprintf('Max distance from center: %.2f pixels\n', max(distanceFromCenter));
    fprintf('Min distance from center: %.2f pixels\n', min(distanceFromCenter));
end
fprintf('\n');

end


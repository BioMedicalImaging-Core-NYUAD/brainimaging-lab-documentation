function visualize_eyetracking(dataFile)
% VISUALIZE_EYETRACKING - Plot gaze points over circular fixation path
% Usage: visualize_eyetracking('circular_path_data.mat')

if nargin < 1 || isempty(dataFile)
    dataFile = 'circular_path_data.mat';
end

S = load(dataFile, 'pa');
if ~isfield(S, 'pa')
    error('visualize_eyetracking:invalidData', 'File does not contain pa struct');
end
pa = S.pa;

% Extract gaze arrays
if ~isfield(pa, 'data') || ~isfield(pa.data, 'gazeX') || ~isfield(pa.data, 'gazeY')
    error('visualize_eyetracking:missingGaze', 'pa.data.gazeX/gazeY not found');
end
gazeX = pa.data.gazeX(:);
gazeY = pa.data.gazeY(:);

% Determine center
if isfield(pa, 'screenCenter') && numel(pa.screenCenter) == 2
    center = pa.screenCenter(:)';
else
    center = [960, 540];
end

% Radius
if ~isfield(pa, 'fixationRadiusPix')
    error('visualize_eyetracking:missingRadius', 'pa.fixationRadiusPix not found');
end
radius = pa.fixationRadiusPix;

% Valid points
valid = ~isnan(gazeX) & ~isnan(gazeY);
gazeXv = gazeX(valid);
gazeYv = gazeY(valid);

% Trial numbers for color (truncate to saved trials if needed)
if isfield(pa, 'trialCounter') && pa.trialCounter > 0
    n = numel(gazeX);
    trialIdx = (1:n)';
    trialIdx = trialIdx(valid);
else
    trialIdx = ones(sum(valid),1);
end

% Create figure
figure('Color','w'); hold on;

% Draw circle (use viscircles if available)
haveViscircles = exist('viscircles','file') == 2;
if haveViscircles
    viscircles(center, radius, 'Color', 'k', 'LineWidth', 1);
else
    rectangle('Position',[center(1)-radius, center(2)-radius, 2*radius, 2*radius], ...
              'Curvature',[1 1], 'EdgeColor','k', 'LineWidth',1);
end

% Crosshair at center
plot([center(1)-10 center(1)+10],[center(2) center(2)],'k-');
plot([center(1) center(1)],[center(2)-10 center(2)+10],'k-');

% Scatter gaze points color-coded by trial index
if ~isempty(gazeXv)
    scatter(gazeXv, gazeYv, 12, trialIdx, 'filled', 'MarkerFaceAlpha', 0.6);
    colormap(parula(max(trialIdx)));
    colorbar; caxis([min(trialIdx) max(trialIdx)]);
else
    text(center(1), center(2), 'No valid gaze samples', 'HorizontalAlignment','center');
end

axis equal; xlabel('X (pixels)'); ylabel('Y (pixels)');
title('Gaze positions over circular fixation path');
set(gca, 'YDir','reverse'); % Screen coordinates have y downwards
hold off;



function ag(varargin)
% AG - Animate eye tracking data from egg experiment
% Usage: 
%   ag()                    % Find most recent file automatically
%   ag(pa)                  % pa structure directly
%   ag('path/to/file.mat')  % File path
%
% This function creates an animated visualization showing:
% - The image that was displayed
% - Eye tracking data overlaid in real-time
% - Current fixation as a semi-transparent red circle
% - Previous fixations connected by lines (markers removed as animation progresses)
%
% Animation plays at the same speed as the actual experiment.

scriptDir = fileparts(mfilename('fullpath'));
resultsDir = fullfile(scriptDir, 'results');

% Parse input arguments
if nargin == 0
    % No input - find most recent file in results directory
    if ~exist(resultsDir, 'dir')
        error('ag:noDataDir', 'Results directory not found: %s', resultsDir);
    end
    
    % Find all .mat files
    matFiles = dir(fullfile(resultsDir, '*.mat'));
    if isempty(matFiles)
        error('ag:noFiles', 'No .mat files found in %s', resultsDir);
    end
    
    % Get file paths and modification times
    filePaths = cell(length(matFiles), 1);
    fileTimes = zeros(length(matFiles), 1);
    for i = 1:length(matFiles)
        filePaths{i} = fullfile(matFiles(i).folder, matFiles(i).name);
        fileInfo = dir(filePaths{i});
        fileTimes(i) = fileInfo.datenum;
    end
    
    % Find most recent file
    [~, idx] = max(fileTimes);
    dataFile = filePaths{idx};
    fprintf('Using most recent file: %s\n', dataFile);
    
    S = load(dataFile, 'pa');
    if ~isfield(S, 'pa')
        error('ag:invalidData', 'File does not contain pa struct');
    end
    pa = S.pa;
    
elseif nargin == 1
    input = varargin{1};
    if isstruct(input)
        % Input is the pa structure directly
        pa = input;
    elseif ischar(input) || isstring(input)
        % Input is a file path
        dataFile = char(input);
        if ~exist(dataFile, 'file')
            error('ag:fileNotFound', 'File not found: %s', dataFile);
        end
        S = load(dataFile, 'pa');
        if ~isfield(S, 'pa')
            error('ag:invalidData', 'File does not contain pa struct');
        end
        pa = S.pa;
    else
        error('ag:invalidInput', 'Single input must be pa structure or file path');
    end
else
    error('ag:invalidInput', 'Invalid number of arguments. See help for usage.');
end

% Check if eye tracking data exists
if ~isfield(pa, 'data') || ~isfield(pa.data, 'continuousGazeX') || ...
   ~isfield(pa.data, 'continuousGazeY') || ~isfield(pa.data, 'continuousGazeTime')
    error('ag:noData', 'No eye tracking data found in pa structure');
end

% Extract gaze data
gazeX = pa.data.continuousGazeX(:);
gazeY = pa.data.continuousGazeY(:);
gazeTime = pa.data.continuousGazeTime(:);

% Extract pupil data if available
hasPupilData = isfield(pa.data, 'continuousPupilArea');
if hasPupilData
    pupilArea = pa.data.continuousPupilArea(:);
else
    pupilArea = [];
end

% Filter out NaN values
valid = ~isnan(gazeX) & ~isnan(gazeY) & ~isnan(gazeTime);
gazeXv = gazeX(valid);
gazeYv = gazeY(valid);
gazeTimev = gazeTime(valid);
if hasPupilData
    pupilAreav = pupilArea(valid);
    % Calculate scaling factors for pupil size
    validPupil = ~isnan(pupilAreav) & pupilAreav > 0;
    if any(validPupil)
        minPupil = min(pupilAreav(validPupil));
        maxPupil = max(pupilAreav(validPupil));
        pupilMinSize = 200;
        pupilMaxSize = 600;
        fprintf('Pupil size data available (range: %.1f - %.1f). Fixation circle size will vary with pupil size.\n', minPupil, maxPupil);
    else
        hasPupilData = false;
        fprintf('Pupil size data field exists but contains no valid data. Using fixed circle size.\n');
    end
else
    fprintf('No pupil size data available. Using fixed circle size for fixations.\n');
end

if isempty(gazeXv)
    error('ag:noData', 'No valid gaze samples found.');
end

% Get screen parameters
if isfield(pa, 'screenWidthPix') && isfield(pa, 'screenHeightPix')
    screenWidth = pa.screenWidthPix;
    screenHeight = pa.screenHeightPix;
else
    screenWidth = 1920;
    screenHeight = 1080;
end

% Get background color
if isfield(pa, 'backGroundColor')
    bgColor = pa.backGroundColor / 255;
else
    bgColor = [128 128 128] / 255; % Default mid-gray
end

% Load image if path is stored
hasImage = false;
imgData = [];
imgRect = [];
if isfield(pa, 'imagePath') && exist(pa.imagePath, 'file')
    try
        imgData = imread(pa.imagePath);
        hasImage = true;
        if isfield(pa, 'imageRect')
            imgRect = pa.imageRect;
        end
    catch
        fprintf('Warning: Could not load image from %s\n', pa.imagePath);
    end
end

% Determine animation time range
startTime = 0;
endTime = gazeTimev(end);
totalDuration = endTime;

% Create time vector for animation (sample at ~30 Hz for smooth animation)
frameRate = 30; % frames per second
dt = 1 / frameRate;
timeVec = startTime:dt:endTime;

% Calculate figure size (1:2 scale of screen)
scale = 0.5;
figWidth = screenWidth * scale;
figHeight = screenHeight * scale;

% Create figure
fig = figure('Color', bgColor, 'Position', [100, 100, figWidth, figHeight]);
ax = axes('Parent', fig);
hold(ax, 'on');
axis(ax, 'equal');

% Set axis limits to match screen
xlim(ax, [0, screenWidth]);
ylim(ax, [0, screenHeight]);
set(ax, 'YDir', 'reverse'); % Match screen coordinates (Y increases downward)

% Hide axes, ticks, and labels
set(ax, 'Color', bgColor);
set(ax, 'XColor', 'none');
set(ax, 'YColor', 'none');
set(ax, 'XTick', []);
set(ax, 'YTick', []);
set(ax, 'XTickLabel', []);
set(ax, 'YTickLabel', []);
xlabel(ax, '');
ylabel(ax, '');

% Display image if available
if hasImage && ~isempty(imgRect)
    % Convert image coordinates for display
    % imgRect format: [left, top, right, bottom] in screen coordinates
    % Since YDir is reversed (Y increases downward), we need to provide Y coordinates correctly
    % For imagesc with reversed Y, we provide [bottom, top] for Y range
    imgX = [imgRect(1), imgRect(3)];
    imgY = [imgRect(4), imgRect(2)]; % [bottom, top] since Y increases downward
    imagesc(ax, imgX, imgY, imgData);
    set(ax, 'YDir', 'reverse'); % Keep Y reversed for gaze coordinates
end

% Initialize plot handles
gazeLineHandle = plot(ax, NaN, NaN, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Gaze path');
currentGazeHandle = scatter(ax, NaN, NaN, 400, 'r', 'filled', 'MarkerFaceAlpha', 0.5, 'DisplayName', 'Current fixation');

% Initialize tracking variables
gazeX_plotted = [];
gazeY_plotted = [];
pupilArea_plotted = [];
lastIdx = 0;

% Animation loop
fprintf('Starting animation (duration: %.1f seconds)...\n', totalDuration);
fprintf('Press any key to pause/resume, close figure to exit.\n');

for tIdx = 1:length(timeVec)
    currentTime = timeVec(tIdx);
    
    % Find all gaze samples up to current time
    idx = find(gazeTimev <= currentTime);
    
    % Only update if we have new samples
    if length(idx) > lastIdx
        newIdx = (lastIdx + 1):length(idx);
        gazeX_plotted = [gazeX_plotted; gazeXv(idx(newIdx))];
        gazeY_plotted = [gazeY_plotted; gazeYv(idx(newIdx))];
        if hasPupilData
            pupilArea_plotted = [pupilArea_plotted; pupilAreav(idx(newIdx))];
        end
        
        % Update gaze path line (all samples up to current)
        if length(gazeX_plotted) > 1
            set(gazeLineHandle, 'XData', gazeX_plotted(1:end-1), 'YData', gazeY_plotted(1:end-1));
        end
        
        % Show current fixation (most recent gaze point) as semi-transparent red circle
        if ~isempty(gazeX_plotted)
            currentGazeX = gazeX_plotted(end);
            currentGazeY = gazeY_plotted(end);
            
            if hasPupilData && ~isempty(pupilArea_plotted) && ~isnan(pupilArea_plotted(end)) && pupilArea_plotted(end) > 0
                currentPupil = pupilArea_plotted(end);
                normalizedPupil = (currentPupil - minPupil) / (maxPupil - minPupil);
                normalizedPupil = max(0, min(1, normalizedPupil)); % Clamp to [0, 1]
                circleSize = pupilMinSize + normalizedPupil * (pupilMaxSize - pupilMinSize);
            else
                circleSize = 400; % Default size if no pupil data
            end
            
            set(currentGazeHandle, 'XData', currentGazeX, 'YData', currentGazeY, 'SizeData', circleSize, 'Visible', 'on');
        else
            set(currentGazeHandle, 'Visible', 'off');
        end
        
        lastIdx = length(idx);
    end
    
    % Update display every frame for smoothness
    drawnow('limitrate'); % Limit rate for smoother animation
    
    % Real-time pacing (match experiment speed)
    if tIdx < length(timeVec)
        pause(dt);
    end
    
    % Check for key press to pause/resume
    if ~isempty(get(fig, 'CurrentCharacter'))
        pause;
        set(fig, 'CurrentCharacter', char(0)); % Clear the character
    end
end

fprintf('Animation complete!\n');

end


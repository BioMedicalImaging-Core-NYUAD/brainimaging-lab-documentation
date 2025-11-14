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
        pupilMinSize = 50;
        pupilMaxSize = 500;
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

% Load images if paths are stored
hasImage1 = false;
hasImage2 = false;
hasImage3 = false;
imgData1 = [];
imgData2 = [];
imgData3 = [];
imgRect1 = [];
imgRect2 = [];
imgRect3 = [];
duration1 = 10.0; % Default
duration2 = 15.0; % Default
duration3 = 10.0; % Default

% Load first image (backward compatibility with old format)
if isfield(pa, 'imagePath1') && exist(pa.imagePath1, 'file')
    try
        imgData1 = imread(pa.imagePath1);
        hasImage1 = true;
        if isfield(pa, 'imageRect1')
            imgRect1 = pa.imageRect1;
        end
        if isfield(pa, 'duration1')
            duration1 = pa.duration1;
        end
    catch
        fprintf('Warning: Could not load image 1 from %s\n', pa.imagePath1);
    end
elseif isfield(pa, 'imagePath') && exist(pa.imagePath, 'file')
    % Backward compatibility
    try
        imgData1 = imread(pa.imagePath);
        hasImage1 = true;
        if isfield(pa, 'imageRect')
            imgRect1 = pa.imageRect;
        end
    catch
        fprintf('Warning: Could not load image from %s\n', pa.imagePath);
    end
end

% Load second image
if isfield(pa, 'imagePath2') && exist(pa.imagePath2, 'file')
    try
        imgData2 = imread(pa.imagePath2);
        hasImage2 = true;
        if isfield(pa, 'imageRect2')
            imgRect2 = pa.imageRect2;
        end
        if isfield(pa, 'duration2')
            duration2 = pa.duration2;
        end
    catch
        fprintf('Warning: Could not load image 2 from %s\n', pa.imagePath2);
    end
end

% Load third image
if isfield(pa, 'imagePath3') && exist(pa.imagePath3, 'file')
    try
        imgData3 = imread(pa.imagePath3);
        hasImage3 = true;
        if isfield(pa, 'imageRect3')
            imgRect3 = pa.imageRect3;
        end
        if isfield(pa, 'duration3')
            duration3 = pa.duration3;
        end
    catch
        fprintf('Warning: Could not load image 3 from %s\n', pa.imagePath3);
    end
end

% Determine animation time range
startTime = 0;
endTime = gazeTimev(end);
totalDuration = endTime;

% Create time vector for animation (sample at ~20 Hz for smooth animation)
frameRate = 20; % frames per second (reduced for smoother playback)
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
set(ax, 'YDir', 'reverse'); % Set YDir reverse BEFORE displaying image

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

% Display images will be updated during animation based on time
% Store image handles for later use
imgHandle1 = [];
imgHandle2 = [];
imgHandle3 = [];
if hasImage1 && ~isempty(imgRect1)
    imgX1 = [imgRect1(1), imgRect1(3)];
    imgY1 = [imgRect1(2), imgRect1(4)];
    imgHandle1 = imagesc(ax, imgX1, imgY1, imgData1);
    set(imgHandle1, 'Visible', 'on'); % Show first image initially
end
if hasImage2 && ~isempty(imgRect2)
    imgX2 = [imgRect2(1), imgRect2(3)];
    imgY2 = [imgRect2(2), imgRect2(4)];
    imgHandle2 = imagesc(ax, imgX2, imgY2, imgData2);
    set(imgHandle2, 'Visible', 'off'); % Hide second image initially
end
if hasImage3 && ~isempty(imgRect3)
    imgX3 = [imgRect3(1), imgRect3(3)];
    imgY3 = [imgRect3(2), imgRect3(4)];
    imgHandle3 = imagesc(ax, imgX3, imgY3, imgData3);
    set(imgHandle3, 'Visible', 'off'); % Hide third image initially
end

% Initialize plot handles
gazeLineHandle = plot(ax, NaN, NaN, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Gaze path');
currentGazeHandle = scatter(ax, NaN, NaN, 400, 'r', 'filled', 'MarkerFaceAlpha', 0.5, 'DisplayName', 'Current fixation');

% Initialize tracking variables - pre-allocate for efficiency
maxSamples = length(gazeXv);
gazeX_plotted = nan(1, maxSamples);
gazeY_plotted = nan(1, maxSamples);
if hasPupilData
    pupilArea_plotted = nan(1, maxSamples);
end
currentIdx = 0; % Current number of plotted samples
gazeIdx = 1; % Current index in gaze data
currentPhoto = 0; % Track which photo is currently displayed (0=photo1, 1=photo2, 2=photo3)
photoStartIdx = 1; % Track where current photo's gaze data starts

% Animation loop
fprintf('Starting animation (duration: %.1f seconds)...\n', totalDuration);
fprintf('Press any key to pause/resume, close figure to exit.\n');

frameStartTime = tic; % Track frame timing for smoothness

for tIdx = 1:length(timeVec)
    currentTime = timeVec(tIdx);
    
    % Update image display based on current time and clear lines when switching photos
    newPhoto = 0; % Determine which photo should be displayed
    if currentTime < duration1
        newPhoto = 0; % Photo 1
    elseif currentTime < duration1 + duration2
        newPhoto = 1; % Photo 2
    else
        newPhoto = 2; % Photo 3
    end
    
    % If photo changed, clear previous gaze lines and reset tracking
    if newPhoto ~= currentPhoto
        % Clear the gaze line by setting it to empty
        set(gazeLineHandle, 'XData', NaN, 'YData', NaN);
        % Reset plotted arrays for new photo
        currentIdx = 0;
        photoStartIdx = gazeIdx; % Mark where new photo's data starts
        currentPhoto = newPhoto;
    end
    
    % Update image visibility
    if hasImage1 && ~isempty(imgHandle1)
        set(imgHandle1, 'Visible', newPhoto == 0);
    end
    if hasImage2 && ~isempty(imgHandle2)
        set(imgHandle2, 'Visible', newPhoto == 1);
    end
    if hasImage3 && ~isempty(imgHandle3)
        set(imgHandle3, 'Visible', newPhoto == 2);
    end
    
    % Find new gaze samples up to current time
    while gazeIdx <= length(gazeTimev) && gazeTimev(gazeIdx) <= currentTime
        currentIdx = currentIdx + 1;
        gazeX_plotted(currentIdx) = gazeXv(gazeIdx);
        gazeY_plotted(currentIdx) = gazeYv(gazeIdx);
        if hasPupilData
            pupilArea_plotted(currentIdx) = pupilAreav(gazeIdx);
        end
        gazeIdx = gazeIdx + 1;
    end
    
    % Update plot only if we have data
    if currentIdx > 0
        % Update gaze path line (all samples up to current)
        if currentIdx > 1
            set(gazeLineHandle, 'XData', gazeX_plotted(1:currentIdx-1), 'YData', gazeY_plotted(1:currentIdx-1));
        end
        
        % Interpolate gaze position for smoother, more accurate display
        % Find the two samples that bracket the current time
        if currentIdx > 0 && gazeIdx <= length(gazeTimev)
            % We have samples before and after current time - interpolate
            t1 = gazeTimev(gazeIdx - 1);
            t2 = gazeTimev(gazeIdx);
            if t2 > t1 && currentTime >= t1 && currentTime <= t2
                % Linear interpolation
                alpha = (currentTime - t1) / (t2 - t1);
                currentGazeX = gazeXv(gazeIdx - 1) + alpha * (gazeXv(gazeIdx) - gazeXv(gazeIdx - 1));
                currentGazeY = gazeYv(gazeIdx - 1) + alpha * (gazeYv(gazeIdx) - gazeYv(gazeIdx - 1));
                if hasPupilData
                    currentPupil = pupilAreav(gazeIdx - 1) + alpha * (pupilAreav(gazeIdx) - pupilAreav(gazeIdx - 1));
                end
            else
                % Use most recent sample
                currentGazeX = gazeX_plotted(currentIdx);
                currentGazeY = gazeY_plotted(currentIdx);
                if hasPupilData
                    currentPupil = pupilArea_plotted(currentIdx);
                end
            end
        else
            % Use most recent sample
            currentGazeX = gazeX_plotted(currentIdx);
            currentGazeY = gazeY_plotted(currentIdx);
            if hasPupilData
                currentPupil = pupilArea_plotted(currentIdx);
            end
        end
        
        % Calculate circle size
        if hasPupilData && exist('currentPupil', 'var') && ~isnan(currentPupil) && currentPupil > 0
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
    
    % Update display
    drawnow;
    
    % Accurate timing control
    if tIdx < length(timeVec)
        elapsed = toc(frameStartTime);
        frameStartTime = tic; % Reset for next frame
        sleepTime = dt - elapsed;
        if sleepTime > 0
            pause(sleepTime);
        end
    end
    
    % Check for key press to pause/resume (non-blocking)
    if ~isempty(get(fig, 'CurrentCharacter'))
        pause;
        set(fig, 'CurrentCharacter', char(0)); % Clear the character
        frameStartTime = tic; % Reset timing after pause
    end
end

fprintf('Animation complete!\n');

end


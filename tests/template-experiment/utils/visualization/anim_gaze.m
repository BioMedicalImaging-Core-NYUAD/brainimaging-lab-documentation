function anim_gaze(varargin)
% ANIM_GAZE - Animate eye tracking data with moving dot
% Usage: 
%   anim_gaze()                                      % Find most recent file automatically
%   anim_gaze(pa)                                    % pa structure directly
%   anim_gaze('0201', '01', '01')                    % subject, session, run
%   anim_gaze('0201', '01', '01', 'circularpath')   % with task name
%   anim_gaze('02010101')                            % Combined: subject(4) + session(2) + run(2)
%   anim_gaze(02010101)                              % Numeric version
%   anim_gaze(..., 'speed', 2)                       % Speed up animation by 2x
%
% This function creates an animated visualization showing:
% - The circular path with a traveling dot (recreating the experiment)
% - Eye tracking data overlaid in real-time
% - Current fixation as a semi-transparent red circle
% - Previous fixations connected by lines (markers removed as animation progresses)
%
% Animation plays at the same speed as the actual experiment.

scriptDir = fileparts(mfilename('fullpath'));
experimentDir = fullfile(scriptDir, '..', '..');
expDataDir = fullfile(experimentDir, 'data', 'exp');

% Parse input arguments
if nargin == 0
    % No input - find most recent file in data/exp directory
    if ~exist(expDataDir, 'dir')
        error('anim_gaze:noDataDir', 'Data directory not found: %s', expDataDir);
    end
    
    % Find all .mat files recursively
    matFiles = dir(fullfile(expDataDir, '**', '*.mat'));
    if isempty(matFiles)
        error('anim_gaze:noFiles', 'No .mat files found in %s', expDataDir);
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
        error('animate_eyetracking:invalidData', 'File does not contain pa struct');
    end
    pa = S.pa;
    
elseif nargin == 1
    % Single input - could be pa structure, file path, or combined ID string
    input = varargin{1};
    if isstruct(input)
        % Input is the pa structure directly
        pa = input;
    elseif ischar(input) || isstring(input)
        inputStr = char(input);
        % Check if it's a file path (contains '/' or '\')
        if contains(inputStr, filesep) || contains(inputStr, '/') || contains(inputStr, '\')
            % Input is a file path
            S = load(inputStr, 'pa');
            if ~isfield(S, 'pa')
                error('anim_gaze:invalidData', 'File does not contain pa struct');
            end
            pa = S.pa;
        elseif length(inputStr) == 8 && all(isstrprop(inputStr, 'digit'))
            % Combined ID format: '02010101' = subject(0201) + session(01) + run(01)
            subjectID = inputStr(1:4);
            sessionID = inputStr(5:6);
            runID = inputStr(7:8);
            taskName = 'circularpath'; % Default task name
            
            fileName = sprintf('sub-%s_ses-%s_run-%s_task-%s.mat', subjectID, sessionID, runID, taskName);
            dataFile = fullfile(expDataDir, sprintf('sub-%s', subjectID), ...
                sprintf('ses-%s', sessionID), fileName);
            
            if ~exist(dataFile, 'file')
                error('anim_gaze:fileNotFound', 'Data file not found: %s', dataFile);
            end
            
            S = load(dataFile, 'pa');
            if ~isfield(S, 'pa')
                error('anim_gaze:invalidData', 'File does not contain pa struct');
            end
            pa = S.pa;
        else
            error('anim_gaze:invalidInput', 'Single string input must be file path or 8-digit ID (e.g., ''02010101'')');
        end
    elseif isnumeric(input) && isscalar(input)
        % Numeric input: 02010101
        inputStr = sprintf('%08d', input);
        if length(inputStr) ~= 8
            error('anim_gaze:invalidInput', 'Numeric input must be 8 digits (e.g., 02010101)');
        end
        subjectID = inputStr(1:4);
        sessionID = inputStr(5:6);
        runID = inputStr(7:8);
        taskName = 'circularpath'; % Default task name
        
        fileName = sprintf('sub-%s_ses-%s_run-%s_task-%s.mat', subjectID, sessionID, runID, taskName);
        dataFile = fullfile(expDataDir, sprintf('sub-%s', subjectID), ...
            sprintf('ses-%s', sessionID), fileName);
        
        if ~exist(dataFile, 'file')
            error('anim_gaze:fileNotFound', 'Data file not found: %s', dataFile);
        end
        
        S = load(dataFile, 'pa');
        if ~isfield(S, 'pa')
            error('anim_gaze:invalidData', 'File does not contain pa struct');
        end
        pa = S.pa;
    else
        error('anim_gaze:invalidInput', 'Single input must be pa structure, file path, or 8-digit ID');
    end
    
elseif nargin >= 3
    % Multiple inputs - subject, session, run (and optionally task)
    subjectID = varargin{1};
    sessionID = varargin{2};
    runID = varargin{3};
    if nargin >= 4
        taskName = varargin{4};
    else
        taskName = 'circularpath'; % Default task name
    end
    
    % Convert to strings if numeric
    if isnumeric(subjectID), subjectID = sprintf('%04d', subjectID); end
    if isnumeric(sessionID), sessionID = sprintf('%02d', sessionID); end
    if isnumeric(runID), runID = sprintf('%02d', runID); end
    
    fileName = sprintf('sub-%s_ses-%s_run-%s_task-%s.mat', subjectID, sessionID, runID, taskName);
    dataFile = fullfile(expDataDir, sprintf('sub-%s', subjectID), ...
        sprintf('ses-%s', sessionID), fileName);
    
    if ~exist(dataFile, 'file')
        error('anim_gaze:fileNotFound', 'Data file not found: %s', dataFile);
    end
    
    S = load(dataFile, 'pa');
    if ~isfield(S, 'pa')
        error('anim_gaze:invalidData', 'File does not contain pa struct');
    end
    pa = S.pa;
else
    error('anim_gaze:invalidInput', 'Invalid number of arguments. See help for usage examples.');
end

% Parse optional name-value pairs (e.g., 'speed', 2)
speedMultiplier = 1; % Default: no speed change
i = 1;
while i <= length(varargin)
    if ischar(varargin{i}) && strcmpi(varargin{i}, 'speed')
        if i + 1 <= length(varargin) && isnumeric(varargin{i+1}) && isscalar(varargin{i+1})
            speedMultiplier = varargin{i+1};
            if speedMultiplier <= 0
                error('anim_gaze:invalidSpeed', 'Speed multiplier must be positive');
            end
            i = i + 2; % Skip both 'speed' and its value
        else
            error('anim_gaze:invalidSpeed', 'Speed flag must be followed by a numeric value');
        end
    else
        i = i + 1;
    end
end

% Check if continuous gaze data exists
if ~isfield(pa.data, 'continuousGazeX') || ~isfield(pa.data, 'continuousGazeY') || ...
   ~isfield(pa.data, 'continuousGazeTime')
    error('anim_gaze:missingData', 'Continuous gaze data not found. Run experiment with continuous tracking enabled.');
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
    % Calculate scaling factors for pupil size (normalize to reasonable range)
    validPupil = ~isnan(pupilAreav) & pupilAreav > 0;
    if any(validPupil)
        minPupil = min(pupilAreav(validPupil));
        maxPupil = max(pupilAreav(validPupil));
        % Scale pupil size to circle size range
        pupilMinSize = 50;
        pupilMaxSize = 500;
        fprintf('Pupil size data available (range: %.1f - %.1f). Fixation circle size will vary with pupil size.\n', minPupil, maxPupil);
    else
        hasPupilData = false; % No valid pupil data
        fprintf('Pupil size data field exists but contains no valid data. Using fixed circle size.\n');
    end
else
    fprintf('No pupil size data available. Using fixed circle size for fixations.\n');
end

if isempty(gazeXv)
    error('anim_gaze:noData', 'No valid gaze samples found.');
end

% Get parameters
if isfield(pa, 'screenCenter') && numel(pa.screenCenter) == 2
    center = pa.screenCenter(:)';
else
    center = [960, 540]; % Default center
end

% Determine screen dimensions from center (assuming center = [width/2, height/2])
% Or try to get from saved data if available
if isfield(pa, 'screenWidthPix') && isfield(pa, 'screenHeightPix')
    screenWidth = pa.screenWidthPix;
    screenHeight = pa.screenHeightPix;
else
    % Infer from center (center is typically at [width/2, height/2])
    screenWidth = center(1) * 2;
    screenHeight = center(2) * 2;
end

% Scale to 1:2 (half size)
scaleFactor = 0.5;
figWidth = screenWidth * scaleFactor;
figHeight = screenHeight * scaleFactor;

if isfield(pa, 'fixationRadiusPix')
    radius = pa.fixationRadiusPix;
else
    radius = 100; % Default radius
end

if isfield(pa, 'fixationSpeed')
    fixationSpeed = pa.fixationSpeed; % radians per second
else
    fixationSpeed = 2*pi / 36; % Default: 36 seconds per rotation
end

if isfield(pa, 'travelingDotRadiusPix')
    dotSize = pa.travelingDotRadiusPix;
else
    dotSize = 5; % Default dot size
end

% Determine animation time range
startTime = 0;
endTime = gazeTimev(end);
totalDuration = endTime;

% Create time vector for animation (sample at ~60 Hz for smooth animation)
frameRate = 60; % frames per second
dt = 1 / frameRate;
timeVec = startTime:dt:endTime;

% Apply speed multiplier to timing
dt = dt / speedMultiplier;
if speedMultiplier ~= 1
    fprintf('Animation speed: %.1fx\n', speedMultiplier);
end

% Get background color (mid-gray, convert from 0-255 to 0-1 range)
if isfield(pa, 'backGroundColor')
    bgColor = pa.backGroundColor / 255;
else
    bgColor = [128 128 128] / 255; % Default mid-gray
end

% Create figure with same aspect ratio as experiment screen, scaled to 1:2
fig = figure('Color', bgColor, 'Position', [100, 100, figWidth, figHeight]);
ax = axes('Parent', fig);
hold(ax, 'on');
axis(ax, 'equal');

% Set axis limits to focus on circle area with padding
% Calculate padding to show circle area nicely (smaller padding = more zoom)
% Change this value to adjust zoom: smaller = more zoomed in, larger = more zoomed out
padding = radius * 0.5;
xlim(ax, [center(1) - radius - padding, center(1) + radius + padding]);
ylim(ax, [center(2) - radius - padding, center(2) + radius + padding]);
set(ax, 'YDir', 'reverse'); % Match screen coordinates (Y increases downward)

% Hide axes, ticks, and labels
set(ax, 'Color', bgColor); % Match background color
set(ax, 'XColor', 'none'); % Hide x-axis
set(ax, 'YColor', 'none'); % Hide y-axis
set(ax, 'XTick', []); % Remove x-ticks
set(ax, 'YTick', []); % Remove y-ticks
set(ax, 'XTickLabel', []); % Remove x-labels
set(ax, 'YTickLabel', []); % Remove y-labels
xlabel(ax, ''); % Remove x-label
ylabel(ax, ''); % Remove y-label

% Draw circular path (static)
haveViscircles = exist('viscircles','file') == 2;
if haveViscircles
    viscircles(ax, center, radius, 'Color', 'k', 'LineWidth', 2);
else
    rectangle('Position', [center(1)-radius, center(2)-radius, 2*radius, 2*radius], ...
              'Curvature', [1 1], 'EdgeColor', 'k', 'LineWidth', 2, 'Parent', ax);
end

% Draw crosshair at center
plot(ax, [center(1)-20 center(1)+20], [center(2) center(2)], 'k-', 'LineWidth', 1);
plot(ax, [center(1) center(1)], [center(2)-20 center(2)+20], 'k-', 'LineWidth', 1);

% Initialize plot handles
dotHandle = plot(ax, NaN, NaN, 'ko', 'MarkerSize', dotSize*2, 'MarkerFaceColor', 'k');
gazeLineHandle = plot(ax, NaN, NaN, 'b-', 'LineWidth', 1.5);
% Use scatter for semi-transparent red circle (better alpha support)
currentGazeHandle = scatter(ax, NaN, NaN, 400, 'r', 'filled', 'MarkerFaceAlpha', 0.5, 'MarkerEdgeAlpha', 0.3);

% Title with time display (keep title visible)
titleHandle = title(ax, sprintf('Time: %.2f / %.2f seconds', 0, totalDuration));
set(titleHandle, 'Color', 'k'); % Black text on gray background

% Animation loop
fprintf('Starting animation (%.2f seconds)...\n', totalDuration);
fprintf('Press any key in the figure window to pause/resume, or close to stop.\n');

pauseState = false;
currentGazeIdx = 1; % Index into gaze data
gazeX_plotted = [];
gazeY_plotted = [];
pupilArea_plotted = [];

for frameIdx = 1:length(timeVec)
    currentTime = timeVec(frameIdx);
    
    % Check for pause/resume (click on figure)
    if ~isempty(get(fig, 'CurrentCharacter'))
        pauseState = ~pauseState;
        set(fig, 'CurrentCharacter', char(0)); % Clear the character
        if pauseState
            fprintf('Animation paused. Click figure and press any key to resume.\n');
        else
            fprintf('Animation resumed.\n');
        end
    end
    
    if pauseState
        pause(0.1);
        continue;
    end
    
    % Calculate dot position at current time
    dotAngle = fixationSpeed * currentTime;
    dotX = center(1) + radius * cos(dotAngle);
    dotY = center(2) + radius * sin(dotAngle);
    
    % Update dot position
    set(dotHandle, 'XData', dotX, 'YData', dotY);
    
    % Find gaze samples up to current time
    while currentGazeIdx <= length(gazeTimev) && gazeTimev(currentGazeIdx) <= currentTime
        gazeX_plotted(end+1) = gazeXv(currentGazeIdx);
        gazeY_plotted(end+1) = gazeYv(currentGazeIdx);
        if hasPupilData
            pupilArea_plotted(end+1) = pupilAreav(currentGazeIdx);
        end
        currentGazeIdx = currentGazeIdx + 1;
    end
    
    % Update gaze line (all previous points)
    if ~isempty(gazeX_plotted)
        set(gazeLineHandle, 'XData', gazeX_plotted, 'YData', gazeY_plotted);
    end
    
    % Show current fixation (most recent gaze point) as semi-transparent red circle
    % Size proportional to pupil size if available
    if ~isempty(gazeX_plotted)
        currentGazeX = gazeX_plotted(end);
        currentGazeY = gazeY_plotted(end);
        
        % Calculate circle size based on pupil if available
        if hasPupilData && ~isempty(pupilArea_plotted) && ~isnan(pupilArea_plotted(end)) && pupilArea_plotted(end) > 0
            % Scale pupil area to circle size (normalize to range)
            currentPupil = pupilArea_plotted(end);
            % Linear scaling: map [minPupil, maxPupil] to [pupilMinSize, pupilMaxSize]
            normalizedPupil = (currentPupil - minPupil) / (maxPupil - minPupil);
            normalizedPupil = max(0, min(1, normalizedPupil)); % Clamp to [0, 1]
            circleSize = pupilMinSize + normalizedPupil * (pupilMaxSize - pupilMinSize);
        else
            % Default size if no pupil data
            circleSize = 400;
        end
        
        set(currentGazeHandle, 'XData', currentGazeX, 'YData', currentGazeY, 'SizeData', circleSize, 'Visible', 'on');
    else
        set(currentGazeHandle, 'Visible', 'off');
    end
    
    % Update title with current time
    set(titleHandle, 'String', sprintf('Time: %.2f / %.2f seconds', currentTime, totalDuration));
    
    % Refresh display
    drawnow;
    
    % Pause to maintain real-time speed
    pause(dt);
end

fprintf('Animation complete!\n');

end


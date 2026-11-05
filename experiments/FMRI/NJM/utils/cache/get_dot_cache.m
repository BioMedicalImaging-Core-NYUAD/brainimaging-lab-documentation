function cache = get_dot_cache(fixationSpeed, fixationRadiusPix, ifi)
% GET_DOT_CACHE - Get or create cached dot position lookup table
%
% Input:
%   fixationSpeed - Rotation speed in radians per second
%   fixationRadiusPix - Radius of circular path in pixels
%   ifi - Inter-frame interval in seconds
%
% Output:
%   cache - Structure with:
%     .dotX - X offset lookup table (cos values * radius)
%     .dotY - Y offset lookup table (sin values * radius)
%     .angles - Angle values for lookup
%     .nSamples - Number of samples in cache
%     .timeStep - Time step between samples
%
% This function checks if a cached lookup table exists matching the
% parameters. If not, it creates one and saves it.

scriptDir = fileparts(mfilename('fullpath'));
cacheDir = scriptDir;
cacheFile = fullfile(cacheDir, sprintf('dot_cache_r%.1f_s%.6f_ifi%.6f.mat', ...
    fixationRadiusPix, fixationSpeed, ifi));

% Check if cache file exists
if exist(cacheFile, 'file')
    load(cacheFile, 'cache');
    return;
end

% Calculate number of samples needed for one full rotation
rotationPeriod = 2*pi / fixationSpeed;  % seconds for one full rotation
timeStep = ifi;  % Sample at frame rate
nSamples = ceil(rotationPeriod / timeStep);

% Pre-calculate angles and positions
angles = linspace(0, 2*pi, nSamples);
dotX = fixationRadiusPix * cos(angles);
dotY = fixationRadiusPix * sin(angles);

% Store in cache structure
cache = struct();
cache.dotX = dotX;
cache.dotY = dotY;
cache.angles = angles;
cache.nSamples = nSamples;
cache.timeStep = timeStep;
cache.fixationSpeed = fixationSpeed;
cache.fixationRadiusPix = fixationRadiusPix;
cache.ifi = ifi;

% Save cache file
save(cacheFile, 'cache');
fprintf('Created dot position cache: %s\n', cacheFile);

end


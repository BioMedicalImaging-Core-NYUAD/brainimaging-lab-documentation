function pa = record_continuous_gaze(pa, experimentStartTime)
% RECORD_CONTINUOUS_GAZE - Record gaze sample if enough time has passed
%
% Inputs:
%   pa - Parameters structure
%   experimentStartTime - Start time of experiment (from GetSecs)
%
% Output:
%   pa - Modified parameters structure with new gaze sample if recorded
%
% This function checks if enough time has passed since the last sample
% and records a new gaze sample if so.

if ~pa.eyeTrackingEnabled
    return;
end

currentTime = GetSecs;
timeSinceLastSample = currentTime - pa.lastGazeSampleTime;

% Only record if enough time has passed
if timeSinceLastSample >= pa.gazeSampleInterval
    try
        s = Eyelink('newestfloatsample');
        if ~isempty(s)
            gx = NaN; gy = NaN;
            lx = s.gx(1); ly = s.gy(1);
            rx = s.gx(2); ry = s.gy(2);
            
            % Check for valid left eye data (not NaN and not missing marker)
            if ~isnan(lx) && ~isnan(ly) && lx ~= -32768 && ly ~= -32768
                gx = lx; gy = ly;
            % Fall back to right eye if left is invalid
            elseif ~isnan(rx) && ~isnan(ry) && rx ~= -32768 && ry ~= -32768
                gx = rx; gy = ry;
            end
            
            % Store sample if we have valid data and space
            pa.gazeSampleCounter = pa.gazeSampleCounter + 1;
            if pa.gazeSampleCounter <= pa.maxGazeSamples
                pa.data.continuousGazeX(pa.gazeSampleCounter) = gx;
                pa.data.continuousGazeY(pa.gazeSampleCounter) = gy;
                pa.data.continuousGazeTime(pa.gazeSampleCounter) = currentTime - experimentStartTime;
            end
            pa.lastGazeSampleTime = currentTime;
        end
    catch
        % Silently fail if Eyelink sample retrieval fails
    end
end

end


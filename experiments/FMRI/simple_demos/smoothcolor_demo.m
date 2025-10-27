function smooth_color_fade_10s
% Smooth 10-second color fade demo for Psychtoolbox.

AssertOpenGL;
ListenChar(2);                      % keep keypresses out of MATLAB
KbReleaseWait;

Screen('Preference','Verbosity', 3);

try
    scr = max(Screen('Screens'));
    [win, rect] = Screen('OpenWindow', scr, 0); %#ok<ASGLU>
    Screen('ColorRange', win, 1);
    HideCursor;

    ifi = Screen('GetFlipInterval', win);
    vbl = Screen('Flip', win);

    % Define colors to fade between
    colors = [
        1 0 0;    % red
        0 1 0;    % green
        0 0 1;    % blue
        1 1 0;    % yellow
        1 0 1;    % magenta
        0 1 1;    % cyan
        1 1 1;    % white
        0 0 0     % black
    ];

    totalTime = 10;               % total duration (seconds)
    nSegs = size(colors,1) - 1;   % number of color transitions
    segDur = totalTime / nSegs;   % seconds per transition

    startTime = GetSecs;

    while GetSecs - startTime < totalTime
        t = GetSecs - startTime;
        seg = min(floor(t / segDur) + 1, nSegs);
        localT = (t - (seg - 1)*segDur) / segDur; % 0–1 within this segment

        % Linear interpolation between current and next color
        col = (1 - localT) * colors(seg,:) + localT * colors(seg+1,:);

        Screen('FillRect', win, col);
        vbl = Screen('Flip', win, vbl + 0.5*ifi); %#ok<NASGU>

        if KbCheck; break; end    % optional early exit
    end

    sca;

catch ME
    sca;
    ListenChar(0); ShowCursor;
    rethrow(ME);
end

ListenChar(0); ShowCursor;
end

function runDisplay(scr, const, my_key)
% runDisplay - Main display loop with eye tracking (VRI method)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EYETRACKING CALIBRATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if const.EL_mode
    % Calibrate
    [~, exitFlag] = initEyelinkStates('calibrate', const.window, const.EL);
    if exitFlag
        cleanup(const);
        return
    end

    % Start recording
    err = Eyelink('CheckRecording');
    if err ~= 0
        initEyelinkStates('startrecording', const.window, const.EL);
        disp('Eyelink now recording .. ')
    end
end

HideCursor(scr.scr_num);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WAIT FOR TRIGGER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
DrawFormattedText(const.window, 'Press T or 5 to start...', 'center', 'center', 1);
Screen('Flip', const.window);

% Wait for T or 5
keyCode = zeros(1, 256);
while ~(keyCode(my_key.t) || keyCode(my_key.five))
    [~, ~, keyCode] = KbCheck(-1);
    if keyCode(my_key.escape)
        cleanup(const);
        return
    end
end

FlushEvents('KeyDown');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAIN LOOP - VRI method exactly
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
frameCounter = 1;
const.expStop = 0;
blinkCounter = 0;
blinkFrameThresh = (1/scr.ifi) * const.blinkSecThresh;

tic
vbl = Screen('Flip', const.window);

try
    waitframes = 1;
    vblendtime = vbl + const.totalduration;

    if const.EL_mode
        Eyelink('message', 'DISPLAY START');
    end

    while vbl <= vblendtime
        % Draw fixation dot
        Screen('DrawDots', const.window, scr.windCenter_px, ...
            const.fixationRadius_px, const.white, [], 2);

        Screen('DrawingFinished', const.window);
        vbl = Screen('Flip', const.window, vbl + (waitframes - 0.5) * scr.ifi);

        % Eye tracking monitoring (VRI method exactly)
        if const.EL_mode
            evt = Eyelink('newestfloatsample');
            xPos = evt.gx;
            yPos = evt.gy;

            % Blink detection
            if isequal(xPos(1), xPos(2), yPos(1), yPos(2))
                blinkCounter = blinkCounter + 1;
                if blinkCounter >= blinkFrameThresh
                    % play alarm: Beeper(400, 0.8, 1);
                end
            else
                blinkCounter = 0;
            end
        end

        frameCounter = frameCounter + 1;
    end

    if const.EL_mode
        Eyelink('message', 'DISPLAY END');
    end
    const.expStop = 1;

catch ME
    disp(getReport(ME))
    disp('catchex')
end

toc

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SAVE EYETRACKING DATA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if const.EL_mode
    disp("Please wait, saving EYELINK file..")
    if ~exist(const.eyeDataDir, 'dir')
        mkdir(const.eyeDataDir);
    end
    initEyelinkStates('eyestop', scr.scr_num, {const.eyeFileName, const.eyeDataDir})
end

fprintf('\n=== EXPERIMENT COMPLETE ===\n');
fprintf('Total frames: %d\n', frameCounter);

end

function cleanup(const)
    try
        if const.EL_mode
            Eyelink('Shutdown');
        end
    catch
    end
    sca;
    ListenChar(0);
    ShowCursor;
end

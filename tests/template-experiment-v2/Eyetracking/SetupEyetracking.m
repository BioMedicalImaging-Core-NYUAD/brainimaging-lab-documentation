function [el, pa] = SetupEyetracking(VP, pa, dummymode)
% SetupEyetracking - Initialize eye tracking using uncertainty experiment method
%
% This follows the uncertainty experiment approach which is different from VRI

    % Provide Eyelink with details about the graphics environment
    % Call EyelinkInitDefaults FIRST (before EyelinkInit) - uncertainty method
    el = EyelinkInitDefaults(VP.window);

    % Customize calibration appearance
    el.calibrationtargetcolour = WhiteIndex(el.window);
    el.backgroundcolour = VP.gray * 255;  % Gray background
    el.msgfontcolour = WhiteIndex(el.window);
    el.calibrationtargetsize = 1;
    el.calibrationtargetwidth = 0.5;
    el.targetbeep = 0;
    el.feedbackbeep = 0;

    % Initialize PsychSound for calibration/validation audio feedback
    try
        InitializePsychSound();
    catch
        fprintf('Warning: Could not initialize PsychSound\n');
    end

    % CRITICAL: Must call this function to apply the changes - uncertainty method
    EyelinkUpdateDefaults(el);

    % NOW initialize the connection (after EyelinkInitDefaults) - uncertainty method
    if ~EyelinkInit(dummymode)
        fprintf('Eyelink Init aborted.\n');
        el = [];
        return;
    end

    % Open file to record eye data
    edfFile = [pa.eyeFileBase '.edf'];
    i = Eyelink('Openfile', edfFile);
    if i ~= 0
        fprintf('Cannot create EDF file ''%s''\n', edfFile);
        el = [];
        return;
    end

    % Make sure we're still connected
    if Eyelink('IsConnected') ~= 1 && ~dummymode
        el = [];
        return;
    end

    fprintf('Eyelink connected successfully.\n');

    % SET UP EYE-TRACKER CONFIGURATION
    Eyelink('Command', 'add_file_preamble_text ''Recorded by template-experiment''');

    % Set display coordinates - uncertainty method (explicit screen_pixel_coords)
    [width, height] = Screen('WindowSize', VP.window);
    Eyelink('Command', 'screen_pixel_coords = %ld %ld %ld %ld', 0, 0, width-1, height-1);
    Eyelink('Message', 'DISPLAY_COORDS %ld %ld %ld %ld', 0, 0, width-1, height-1);

    fprintf('Screen coordinates set: [0 0 %d %d]\n', width-1, height-1);

    % Calibration area
    Eyelink('Command', 'calibration_area_proportion = 0.8 0.4');
    Eyelink('Command', 'validation_area_proportion = 0.8 0.4');

    % Calibration type
    Eyelink('Command', 'calibration_type = HV5');

    % Set parser
    Eyelink('Command', 'saccade_velocity_threshold = 35');
    Eyelink('Command', 'saccade_acceleration_threshold = 9500');

    % Retrieve tracker version
    [v, vs] = Eyelink('GetTrackerVersion');
    fprintf('Running experiment on a ''%s'' tracker.\n', vs);
    vsn = regexp(vs, '\d', 'match');

    % Configure sample and event data
    if v == 3 && str2double(vsn{1}) == 4  % EL 1000 version 4.xx
        Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
        Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS,INPUT,HTARGET');
        Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,FIXUPDATE,INPUT');
        Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS,INPUT,HTARGET');
    else
        Eyelink('command', 'file_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,INPUT');
        Eyelink('command', 'file_sample_data  = LEFT,RIGHT,GAZE,HREF,AREA,GAZERES,STATUS,INPUT');
        Eyelink('command', 'link_event_filter = LEFT,RIGHT,FIXATION,SACCADE,BLINK,MESSAGE,BUTTON,FIXUPDATE,INPUT');
        Eyelink('command', 'link_sample_data  = LEFT,RIGHT,GAZE,GAZERES,AREA,STATUS,INPUT');
    end

    if ~dummymode
        Screen('HideCursorHelper', VP.window);
    end

    % Store in pa
    pa.EL = el;
    pa.eyeTrackingEnabled = 1;

    fprintf('\n=== Starting Calibration ===\n');
    fprintf('Follow the calibration targets on the screen.\n');
    fprintf('Press ENTER on Host PC to accept calibration.\n\n');

    % Enter calibration mode - uncertainty method
    EyelinkDoTrackerSetup(el);

    fprintf('Calibration complete.\n');

end

function main()
% MAIN - Brief checkerboard events for HRF estimation (scanner QC)
%
% Event-related design: 1 s full-field contrast-reversing checkerboard
% flashes with jittered inter-stimulus intervals (4-12 s, uniform).
% 27 events over ~4 minutes.
%
% Purpose: estimate the hemodynamic response function in V1 to compare
% BOLD sensitivity and temporal resolution across scanners.
%
% Attention task: fixation dot dims briefly at random intervals;
% participant presses a button on each dimming.
%
% References:
%   Glover (1999) NeuroImage - Deconvolution of impulse response in
%     event-related BOLD fMRI
%   Boynton et al. (1996) J Neurosci - Linear systems analysis of fMRI
%   Dale & Buckner (1997) Human Brain Mapping - Selective averaging of
%     rapidly presented individual trials
%
% All parameters in utils/setup/setup_param.m

clear all; close all; sca; %#ok<CLALL>

scriptDir = fileparts(mfilename('fullpath'));

% Add shared lab utilities
projectRoot = fullfile(scriptDir, '..', '..', '..', '..');
vpixxPath = fullfile(projectRoot, 'experiments', 'general', 'vpixx-utilities');
if exist(vpixxPath, 'dir'), addpath(vpixxPath); end

addpath(genpath(fullfile(scriptDir, 'utils')));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RUNTIME CONFIGURATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
debugConfig = struct();
debugConfig.enabled = 1;
debugConfig.useVPixx = 0;
debugConfig.fullscreen = 1;
debugConfig.skipSyncTests = 1;
debugConfig.displayMode = 2;          % 1 = NYUAD lab, 2 = laptop
debugConfig.manualTrigger = 1;
debugConfig.buttonbox = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GET BIDS INFORMATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
experimentDir = scriptDir;
try
    debugConfig.bidsInfo = get_info(experimentDir, 'checkerboard');
catch ME
    if contains(ME.message, 'cancelled') || contains(ME.message, 'not to overwrite')
        fprintf('Exiting.\n');
        return;
    end
    rethrow(ME);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETUP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[VP, debugConfig] = setup_display(debugConfig);
[VP, pa] = setup_param(VP, debugConfig);
kb = setup_keyboard();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% RUN EXPERIMENT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
try
    % Pre-compute checkerboard textures (inside try so errors are caught)
    [chk1, chk2] = make_checkerboard_textures(VP, pa);
    fprintf('Checkerboard textures created (radius %.0f px, %d rings, %d wedges)\n', ...
        pa.checkerRadiusPix, pa.nRings, pa.nWedges);

    wait_trigger(VP, debugConfig.manualTrigger);

    experimentStartTime = GetSecs;
    pa.experimentStartTime = experimentStartTime;
    pa.timingBaseTime = experimentStartTime;
    fprintf('\n=== %s ===\n', pa.experimentName);

    KbQueueCreate();
    KbQueueStart();

    % --- Initial baseline fixation ---
    Screen('FillRect', VP.window, VP.backGroundColor);
    draw_fixation(VP, pa, pa.fixColor);
    Screen('Flip', VP.window);
    WaitSecs(pa.initialBaselineDuration);

    % --- Event loop ---
    for ev = 1:pa.nEvents
        eventOnset = GetSecs;
        plannedOnset = eventOnset - experimentStartTime;

        fprintf('Event %d/%d (onset %.1f s)\n', ev, pa.nEvents, plannedOnset);

        % Log event
        pa.eventCounter = pa.eventCounter + 1;
        pa.events(pa.eventCounter).onset = plannedOnset;
        pa.events(pa.eventCounter).duration = pa.stimDuration;
        pa.events(pa.eventCounter).trial_type = 'checkerboard';

        % --- Flash the checkerboard (contrast-reversing) ---
        nFlipFrames = round(pa.stimDuration * VP.frameRate);
        framesPerPhase = max(1, round((1 / pa.flickerHz / 2) * VP.frameRate));
        phase = 0;
        for f = 1:nFlipFrames
            if mod(f - 1, framesPerPhase) == 0
                phase = 1 - phase;
            end
            if phase == 0
                Screen('DrawTexture', VP.window, chk1);
            else
                Screen('DrawTexture', VP.window, chk2);
            end
            draw_fixation(VP, pa, pa.fixColor);
            Screen('Flip', VP.window);
        end

        % --- ISI: fixation only ---
        Screen('FillRect', VP.window, VP.backGroundColor);
        draw_fixation(VP, pa, pa.fixColor);
        Screen('Flip', VP.window);

        isiDuration = pa.isiSequence(ev);
        isiEnd = GetSecs + isiDuration;

        while GetSecs < isiEnd - 0.5 * VP.ifi
            % Check escape
            [pressed, firstPress] = KbQueueCheck();
            if pressed && firstPress(kb.escKey)
                fprintf('Terminated by user.\n');
                error('user_abort');
            end
            WaitSecs(0.001);
        end
    end

    % --- Final baseline ---
    Screen('FillRect', VP.window, VP.backGroundColor);
    draw_fixation(VP, pa, pa.fixColor);
    Screen('Flip', VP.window);
    WaitSecs(pa.finalBaselineDuration);

    % End screen
    Screen('FillRect', VP.window, VP.backGroundColor);
    Screen('TextSize', VP.window, 36);
    DrawFormattedText(VP.window, 'Done', 'center', 'center', [255 255 255]);
    Screen('Flip', VP.window);
    WaitSecs(pa.endScreenDuration);

catch ME
    if ~strcmp(ME.message, 'user_abort')
        fprintf('\n!!! ERROR !!!\n%s\n', ME.message);
        if ~isempty(ME.stack)
            for i = 1:length(ME.stack)
                fprintf('  %d. %s (line %d)\n', i, ME.stack(i).name, ME.stack(i).line);
            end
        end
        % Show error on screen so it's visible in fullscreen
        try
            Screen('FillRect', VP.window, [0 0 0]);
            Screen('TextSize', VP.window, 24);
            DrawFormattedText(VP.window, ...
                sprintf('ERROR: %s\nPress any key to close.', ME.message), ...
                'center', 'center', [255 100 100]);
            Screen('Flip', VP.window);
            KbStrokeWait(-1);
        catch
        end
    end
end

if exist('experimentStartTime', 'var')
    cleanup_experiment(VP, pa, kb, experimentStartTime);
else
    cleanup_experiment(VP, pa, kb, GetSecs);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% LOCAL HELPER FUNCTIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [tex1, tex2] = make_checkerboard_textures(VP, pa)
% MAKE_CHECKERBOARD_TEXTURES - Create two phase-inverted radial checkerboards.

w = round(VP.windowWidthPix);
h = round(VP.windowHeightPix);
halfW = w / 2;
halfH = h / 2;

[xx, yy] = meshgrid(linspace(-halfW, halfW, w), linspace(-halfH, halfH, h));
r = sqrt(xx.^2 + yy.^2);
theta = atan2(yy, xx);

% Radial rings (log-spaced for roughly equal cortical magnification)
maxR = max(halfW, halfH);
logR = log(r + 1);
logMax = log(maxR + 1);
ringPhase = floor(logR / logMax * pa.nRings);

% Angular wedges
wedgePhase = floor((theta + pi) / (2*pi) * pa.nWedges);

% Checkerboard pattern
pattern = mod(ringPhase + wedgePhase, 2);

% Circular aperture
inField = r <= pa.checkerRadiusPix;

% Phase 1: white checks on black
img1 = uint8(VP.backGroundColor(1) * ones(h, w, 3));
for ch = 1:3
    plane = img1(:,:,ch);
    plane(inField & pattern == 1) = 255;
    plane(inField & pattern == 0) = 0;
    img1(:,:,ch) = plane;
end

% Phase 2: inverted
img2 = uint8(VP.backGroundColor(1) * ones(h, w, 3));
for ch = 1:3
    plane = img2(:,:,ch);
    plane(inField & pattern == 1) = 0;
    plane(inField & pattern == 0) = 255;
    img2(:,:,ch) = plane;
end

tex1 = Screen('MakeTexture', VP.window, img1);
tex2 = Screen('MakeTexture', VP.window, img2);

end

function draw_fixation(VP, pa, color)
% DRAW_FIXATION - Draw fixation cross at screen center.
Screen('DrawLines', VP.window, ...
    [-pa.fixCrossLen, pa.fixCrossLen, 0, 0; ...
     0, 0, -pa.fixCrossLen, pa.fixCrossLen], ...
    pa.fixCrossWidth, color, VP.windowCenter);
end

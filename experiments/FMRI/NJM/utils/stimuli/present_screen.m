function [pa, out] = present_screen(VP, pa, kb, tex, tOn, tOff, opts)
% PRESENT_SCREEN - Show one screen from tOn to tOff, locked to the scanner trigger
%
% Inputs:
%   VP, pa, kb - Standard experiment structures
%   tex  - offscreen window with the pre-rendered screen, or [] for the fixation cross
%   tOn  - planned onset, seconds from the trigger (NaN = show it now)
%   tOff - planned end, seconds from the trigger
%   opts - optional struct:
%          .event      event name sent at onset (see send_event)
%          .collect    true = this is the decision screen: return at the first response
%          .auto       simulated response for this trial (testing)
%          .highlight  button number: draw the selection border on top
%          .prepTrial  trial number whose screens are pre-rendered right after the onset
%
% Outputs:
%   pa  - Updated parameters structure
%   out - .onset (GetSecs time of the first frame), .esc (ESC pressed),
%         .responded, .button, .pressTime
%
% Timing: the first frame is flipped on the screen refresh closest to the
% scheduled time (WaitSecs + plain Flip, as in qc/fingers-mapping: timed
% Flips are unreliable with PsychVulkanCore on the stimulus Mac). The screen
% is redrawn every frame. A late frame never shifts the following screens.

if nargin < 7 || isempty(opts), opts = struct(); end
event = opt(opts, 'event', '');
collect = opt(opts, 'collect', false);
highlight = opt(opts, 'highlight', []);
prepTrial = opt(opts, 'prepTrial', []);
auto = opt(opts, 'auto', []);

out = struct('onset', NaN, 'esc', false, 'responded', false, 'button', NaN, 'pressTime', NaN);
ifi = VP.ifi;

draw_frame();
Screen('DrawingFinished', VP.window);
if ~isnan(tOn)
    WaitSecs('UntilTime', pa.t0 + tOn - 0.5 * ifi);
end
Screen('Flip', VP.window);
out.onset = GetSecs;
lastFlip = out.onset;
pa = send_event(pa, event, out.onset, tOn);
if collect
    KbQueueFlush();                                   % presses made before the question do not count
end

if ~isempty(prepTrial)
    pa = prepare_trial_screens(VP, pa, prepTrial);
end

% Redraw until 1.5 frames before the planned end. Flip returns at a screen
% refresh, so the loop then ends on the refresh just before the last one of
% this screen, and the next screen's first Flip lands on the refresh closest
% to its planned onset. (Stopping at 0.5 frames, as the lab's older code does,
% makes every following screen exactly one frame late.)
tEnd = pa.t0 + tOff;
while GetSecs < tEnd - 1.5 * ifi
    draw_frame();
    Screen('Flip', VP.window);
    lastFlip = GetSecs;

    if pa.doutResetAt > 0 && lastFlip >= pa.doutResetAt
        try
            Datapixx('SetDoutValues', 0); Datapixx('RegWrRd');
        catch
        end
        pa.doutResetAt = 0;
    end

    % Read the keyboard queue once per frame (a second read would lose the press)
    [pressed, firstPress] = KbQueueCheck();
    if pressed && firstPress(kb.escKey) > 0
        out.esc = true;
        break;
    end

    if collect
        [pa, got, button, tPress] = get_response(pa, kb, pressed, firstPress, out.onset, auto);
        % The button box is polled, so keep polling until just before the next frame
        while ~got && pa.useButtonBox && ~pa.autoRespond && GetSecs < lastFlip + ifi - 0.004
            [pa, got, button, tPress] = get_response(pa, kb, false, [], out.onset, auto);
        end
        if got
            out.responded = true; out.button = button; out.pressTime = tPress;
            break;
        end
    end
end

    function draw_frame()
        if isempty(tex)
            draw_fixation(VP.window, pa);
        else
            % copy the pre-rendered screen as it is (no blending with the background)
            Screen('BlendFunction', VP.window, 'GL_ONE', 'GL_ZERO');
            Screen('DrawTexture', VP.window, tex);
            Screen('BlendFunction', VP.window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
            if ~isempty(highlight)
                draw_highlight(VP.window, pa, highlight);
            end
        end
    end

end

%--------------------------------------------------------------------------
function v = opt(s, name, default)
if isfield(s, name), v = s.(name); else, v = default; end
end

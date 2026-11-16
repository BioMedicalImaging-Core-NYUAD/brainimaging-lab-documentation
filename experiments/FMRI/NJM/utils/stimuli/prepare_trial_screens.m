function pa = prepare_trial_screens(VP, pa, k)
% PREPARE_TRIAL_SCREENS - Draw the three screens of trial k into offscreen windows
%
% Inputs:
%   VP - Viewing parameters
%   pa - Parameters structure
%   k  - trial number within the run
%
% Output:
%   pa.screenTex(1:3) - offscreen windows for phase 1, 2 and 3 of trial k
%
% Called during the fixation period before the trial, so that showing a
% screen is a single texture draw and the onset is not delayed by text
% rendering.

pa = close_trial_screens(pa);
for phase = 1:3
    w = Screen('OpenOffscreenWindow', VP.window, pa.colors.background);
    Screen('BlendFunction', w, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    Screen('TextFont', w, pa.sizes.font);
    draw_offer_screen(w, pa, pa.trials(k), phase);
    pa.screenTex(phase) = w;
end
pa.screenTrial = k;

end

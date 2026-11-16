function njm_playback(subjectID, sessionID, opts)
% NJM_PLAYBACK - Replay the participant's scanned trials for the think-aloud interview
%
% Protocol (post-scan debriefing): the participant looks at a visual playback
% of the choice trials she did in the scanner and says aloud what she was
% thinking. This shows every completed trial again - both full offers, with
% her choice marked - at the interviewer's pace.
%
%   njm_playback('0201', '01')
%   njm_playback('0201', '01', struct('runs', [1 2], 'debug', struct('fullscreen', 0)))
%
% Keys: RIGHT arrow or SPACE = next trial, LEFT arrow or B = previous trial, ESC = stop.
% Nothing is recorded by this script (the audio recorder is separate).
% Default display is a laptop, fullscreen; change with opts.debug as in main.m.

if nargin < 2 || isempty(sessionID), sessionID = '01'; end
if nargin < 3, opts = struct(); end
scriptDir = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(scriptDir, 'utils')));
subjectID = regexprep(char(subjectID), '^sub-', ''); sessionID = regexprep(char(sessionID), '^ses-', '');
dataDir = fullfile(scriptDir, 'data', 'exp', sprintf('sub-%s', subjectID), sprintf('ses-%s', sessionID));

debugConfig = struct('enabled', 1, 'useVPixx', 0, 'fullscreen', 1, 'skipSyncTests', 1, 'displayMode', 2, ...
    'manualTrigger', 1, 'buttonbox', 0, 'eyetracking', 0);
if isfield(opts, 'debug')
    names = fieldnames(opts.debug);
    for i = 1:numel(names), debugConfig.(names{i}) = opts.debug.(names{i}); end
end
autoAdvance = [];                                       % seconds per trial; only for automated tests
if isfield(opts, 'autoAdvance'), autoAdvance = opts.autoAdvance; end

% collect the completed trials of the saved runs, in the order they were done
files = dir(fullfile(dataDir, sprintf('sub-%s_ses-%s_task-njm_run-*.mat', subjectID, sessionID)));
files = files(cellfun(@isempty, strfind({files.name}, '_old-'))); %#ok<STRCLFH>
if isempty(files), error('njm_playback:noData', 'No saved runs in %s', dataDir); end
design = table(); button = []; rt = []; label = {};
for i = 1:numel(files)
    S = load(fullfile(files(i).folder, files(i).name), 'pa'); pa0 = S.pa;
    if isfield(opts, 'runs') && ~ismember(pa0.bidsInfo.runNumber, opts.runs), continue; end
    done = pa0.data.completed;
    design = [design; pa0.design(done, :)]; %#ok<AGROW>
    button = [button; pa0.data.response_button(done)]; %#ok<AGROW>
    rt = [rt; pa0.data.reaction_time(done)]; %#ok<AGROW>
    label = [label; pa0.data.response_label(done)]; %#ok<AGROW>
end
[~, order] = sort(design.trial_global);
design = design(order, :); button = button(order); rt = rt(order); label = label(order);
n = height(design);
if n == 0, error('njm_playback:noData', 'No completed trials to replay'); end

cfg = njm_load_config(scriptDir, 'task');
[VP, ~] = setup_display(debugConfig);
try
    pa = struct('P', cfg.P, 'screenTex', [], 'screenTrial', 0);
    [pa.L, pa.sizes, pa.colors] = njm_layout(VP, cfg.P);
    pa.trials = njm_trial_structs(cfg.P, design, cfg.P.session.n_trials_total);
    pa.tex = njm_load_textures(VP, cfg, [design.A_face; design.B_face]);
    kb = setup_keyboard(pa);
    captionRect = [VP.Rect(1), pa.L.cardFull(1, 4), VP.Rect(3), VP.Rect(4)];

    k = 1;
    while k >= 1 && k <= n
        Screen('BlendFunction', VP.window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
        Screen('TextFont', VP.window, pa.sizes.font);
        draw_offer_screen(VP.window, pa, pa.trials(k), 2);
        if isnan(button(k))
            caption = 'No answer was given on this one.';
        else
            side = 1 + (button(k) > 2);
            Screen('FrameRect', VP.window, pa.colors.highlight, pa.L.cardFull(side, :), pa.L.highlightWidth);
            caption = sprintf('Your answer: %s  (after %.1f seconds)', label{k}, rt(k));
        end
        njm_text(VP.window, caption, pa.sizes.prompt, pa.colors.text, captionRect, 'center', VP.Rect(3) - VP.Rect(1));
        Screen('Flip', VP.window);

        if ~isempty(autoAdvance)
            WaitSecs(autoAdvance); k = k + 1; continue;
        end
        while KbCheck(-1); WaitSecs(0.01); end
        while true
            [down, ~, keyCode] = KbCheck(-1);
            if down
                if keyCode(kb.escKey), k = 0; break; end
                if keyCode(kb.rightKey) || keyCode(kb.spaceKey), k = k + 1; break; end
                if keyCode(kb.leftKey) || keyCode(kb.backKey), k = max(1, k - 1); break; end
            end
            WaitSecs(0.005);
        end
    end
catch ME
    sca; ShowCursor;
    rethrow(ME);
end
sca; ShowCursor;
fprintf('Playback finished (%d trials available).\n', n);

end

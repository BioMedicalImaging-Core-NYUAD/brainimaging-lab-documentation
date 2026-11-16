function njm_preview_screens(opts)
% NJM_PREVIEW_SCREENS - Save pictures of the task screens (no participant, no scanner)
%
% Opens a window, draws the screens of one trial exactly as the task draws
% them, and saves them as PNG files in the folder screens/:
%   phase1_employer.png, phase2_offer.png, phase3_decision.png,
%   phase3_feedback.png (selection border), fixation.png, catch_trial_phase2.png,
%   instructions_<n>.png
% Use it to check the layout after changing texts, photos or the layout in
% the JSON, and for figures in the protocol.
%
%   njm_preview_screens                    window on this computer
%   njm_preview_screens(struct('debug', struct('displayMode', 1, 'fullscreen', 1, 'useVPixx', 1)))   on the scanner projector

if nargin < 1, opts = struct(); end
scriptDir = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(scriptDir, 'utils')));
outDir = fullfile(scriptDir, 'screens');
if ~exist(outDir, 'dir'), mkdir(outDir); end

debugConfig = struct('enabled', 1, 'useVPixx', 0, 'fullscreen', 0, 'skipSyncTests', 2, 'displayMode', 2, ...
    'manualTrigger', 1, 'buttonbox', 0, 'eyetracking', 0);
if isfield(opts, 'debug')
    names = fieldnames(opts.debug);
    for i = 1:numel(names), debugConfig.(names{i}) = opts.debug.(names{i}); end
end

cfg = njm_load_config(scriptDir, 'task');
design = make_subject_design(cfg, '9999', '01');
design = design(design.run == 1, :);

[VP, ~] = setup_display(debugConfig);
try
    pa = struct('P', cfg.P, 'screenTex', [], 'screenTrial', 0);
    [pa.L, pa.sizes, pa.colors] = njm_layout(VP, cfg.P);
    pa.trials = njm_trial_structs(cfg.P, design, cfg.P.session.n_trials_total);
    pa.tex = njm_load_textures(VP, cfg, [design.A_face; design.B_face]);
    kb = setup_keyboard(pa); %#ok<NASGU>

    k = find(strcmp(design.trial_kind, 'tradeoff'), 1);
    pa = prepare_trial_screens(VP, pa, k);
    names = {'phase1_employer', 'phase2_offer', 'phase3_decision'};
    for ph = 1:3
        imwrite(Screen('GetImage', pa.screenTex(ph)), fullfile(outDir, [names{ph} '.png']));
    end

    Screen('BlendFunction', VP.window, 'GL_ONE', 'GL_ZERO');
    Screen('DrawTexture', VP.window, pa.screenTex(3));
    Screen('BlendFunction', VP.window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    draw_highlight(VP.window, pa, 3);
    imwrite(Screen('GetImage', VP.window, [], 'backBuffer'), fullfile(outDir, 'phase3_feedback.png'));
    Screen('Flip', VP.window);

    draw_fixation(VP.window, pa);
    imwrite(Screen('GetImage', VP.window, [], 'backBuffer'), fullfile(outDir, 'fixation.png'));
    Screen('Flip', VP.window);

    k = find(design.is_catch == 1, 1);
    pa = prepare_trial_screens(VP, pa, k);
    imwrite(Screen('GetImage', pa.screenTex(2)), fullfile(outDir, 'catch_trial_phase2.png'));

    pages = [cfg.P.instructions.task_pages(:)', {sprintf(cfg.P.instructions.run_reminder, 1, cfg.P.session.n_runs)}];
    margin = round(0.08 * (VP.Rect(3) - VP.Rect(1)));
    rect = [VP.Rect(1) + margin, VP.Rect(2), VP.Rect(3) - margin, VP.Rect(4)];
    for p = 1:numel(pages)
        Screen('FillRect', VP.window, pa.colors.background);
        njm_text(VP.window, pages{p}, pa.sizes.instructions, pa.colors.text, rect, 'center', rect(3) - rect(1), pa.sizes.font);
        imwrite(Screen('GetImage', VP.window, [], 'backBuffer'), fullfile(outDir, sprintf('instructions_%d.png', p)));
        Screen('Flip', VP.window);
    end
    fprintf('Window %d x %d px, %.1f pixels per degree\n', VP.Rect(3) - VP.Rect(1), VP.Rect(4) - VP.Rect(2), VP.pixelsPerDegree);
    fprintf('Screens saved in %s\n', outDir);
catch ME
    sca; ShowCursor;
    rethrow(ME);
end
sca; ShowCursor;

end

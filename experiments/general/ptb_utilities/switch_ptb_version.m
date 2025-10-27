function switch_ptb_version(verOrPath, verbose)
% SWITCH_PTB_VERSION  Robustly switch Psychtoolbox versions within one session.
% Now with progress output + timings to diagnose slowness.
%
% Usage:
%   switch_ptb_version('3.0.19.1');              % verbose on
%   switch_ptb_version('3.0.19.1', false);       % quiet
%   switch_ptb_version('/full/path/to/PTB', true)

    if nargin < 2, verbose = true; end
    T0 = tic;

    logmsg(verbose, '=== PTB SWITCH START ===');

    % --- Resolve target root ------------------------------------------------
    if isfolder(verOrPath)
        ptb_root = verOrPath;
    else
        homeDir = getenv('HOME');
        bases = { fullfile(homeDir,'Documents','Psychtoolbox_versions'), ...
                  fullfile(homeDir,'Documents','Psychtoolbox_version') };
        ptb_root = '';
        for b = bases
            candidate = fullfile(b{1}, ['Psychtoolbox-', verOrPath]);
            if isfolder(candidate), ptb_root = candidate; break; end
        end
        if isempty(ptb_root)
            error('PTB folder not found. Checked:\n  %s\n  %s', bases{1}, bases{2});
        end
    end
    logmsg(verbose, 'Target root: %s', ptb_root);

    % --- Choose subtree to add (some dists have wrapper 'Psychtoolbox') ---
    if isfolder(fullfile(ptb_root,'Psychtoolbox'))
        add_root = fullfile(ptb_root,'Psychtoolbox');
    else
        add_root = ptb_root;
    end
    logmsg(verbose, 'Add root:    %s', add_root);

    % --- Preflight: read version on disk (not runtime) ---------------------
    vfile = fullfile(add_root,'PsychBasic','PsychtoolboxVersion.m');
    if ~isfile(vfile)
        error('Cannot find PsychtoolboxVersion.m under %s', add_root);
    end
    txt = fileread(vfile);
    m = regexp(txt,'\b3\.\d+\.\d+(?:\.\d+)?\b','match');  % 3.x.x or 3.x.x.x
    claimed = 'unknown'; if ~isempty(m), claimed = m{1}; end
    logmsg(verbose, 'On-disk version claimed: %s', claimed);

    % --- If pwd is inside a PTB tree, cd out so pwd can't shadow -----------
    if contains(lower(pwd),'psychtoolbox')
        cd(getenv('HOME'));
        logmsg(verbose, 'Moved out of PTB directory to avoid shadowing.');
    end

    % --- 1) Remove ALL existing PTB paths (loop until none) ---------------
    t = tic;
    tokens = lower(["psychtoolbox","psychapps","psychbasic","psychcontributed","psychdemos", ...
                    "psychhardware","psychjava","psychmatlabtests","psychobsolete", ...
                    "psychopengl","psychoptics","psychpriority","psychsound"]);
    total_removed = 0;
    iter = 0;

    while true
        iter = iter + 1;
        p = strsplit(path, pathsep);
        isptb = false(size(p));
        for k = 1:numel(p)
            pk = lower(p{k});
            for tkn = tokens
                if contains(pk, tkn), isptb(k) = true; break; end
            end
        end
        defs = [which('PsychtoolboxVersion','-all'); which('Screen','-all')];
        for f = defs'
            if ~isempty(f{1})
                gp = strsplit(genpath(fileparts(f{1})), pathsep);
                for g = gp
                    if ~isempty(g{1}), isptb(strcmp(p, g{1})) = true; end
                end
            end
        end
        idx = find(isptb);
        if isempty(idx)
            logmsg(verbose, 'Removed PTB paths in %d iteration(s). Total removed: %d (%.3fs)', ...
                iter-1, total_removed, toc(t));
            break;
        end
        logmsg(verbose, 'Iteration %d: removing %d PTB path entries...', iter, numel(idx));
        for ii = 1:numel(idx)
            if ~isempty(p{idx(ii)}) && exist(p{idx(ii)},'dir')
                rmpath(p{idx(ii)});
                total_removed = total_removed + 1;
            end
        end
        drawnow;  % flush output so you can see progress
    end

    % --- 2) Hard-flush caches in a separate function -----------------------
    logmsg(verbose, 'Flushing MATLAB caches...');
    t = tic;
    hard_flush_matlab_caches(verbose);
    logmsg(verbose, 'Caches flushed (%.3fs).', toc(t));

    % --- 3) Add target PTB at the very front ------------------------------
    logmsg(verbose, 'Adding PTB paths (this can take a moment)...');
    t = tic;
    addpath(genpath(add_root), '-begin');   % genpath can be slow; we time it.
    rehash toolboxcache;
    logmsg(verbose, 'PTB paths added (%.3fs).', toc(t));

    % --- 4) Optional overrides (your machine-specific MEX first) ----------
    if exist('ptb_use_overrides','file') == 2
        logmsg(verbose, 'Applying overrides via ptb_use_overrides()...');
        t = tic; ptb_use_overrides(); rehash toolboxcache; logmsg(verbose, 'Overrides applied (%.3fs).', toc(t));
    end

    % --- 5) Report + sanity checks ----------------------------------------
    logmsg(verbose, 'Verifying symbols...');
    pv = which('PsychtoolboxVersion','-all');
    sv = which('Screen','-all');
    if verbose
        disp('which PsychtoolboxVersion -all'); disp(pv);
        disp('which Screen -all');             disp(sv);
    end
    try
        vr = PsychtoolboxVersion;
        logmsg(true, 'PsychtoolboxVersion says (runtime): %s', vr);
    catch ME
        logmsg(true, 'PsychtoolboxVersion call failed: %s', ME.message);
    end

    % Warn if Screen MEX missing
    logmsg(verbose, 'Searching for Screen.mexmaca64...');
    t = tic;
    sbin = dir(fullfile(add_root,'**','Screen.mexmaca64'));  % Apple silicon
    if isempty(sbin)
        logmsg(true, 'WARNING: Screen.mexmaca64 not found under %s. Tree may be source-only/incomplete.', add_root);
    else
        logmsg(verbose, 'Found Screen.mexmaca64 at: %s', fullfile(sbin(1).folder, sbin(1).name));
    end
    logmsg(verbose, 'Screen.mex search done (%.3fs).', toc(t));

    logmsg(true, '=== PTB SWITCH DONE (%.3fs) ===', toc(T0));
end

% ---------------------------- Helpers -------------------------------------
function hard_flush_matlab_caches(verbose)
    t = tic;
    % Defensive: leave any PTB dir
    if contains(lower(pwd),'psychtoolbox')
        try, cd(getenv('HOME')); catch, end
    end
    % Evict specific PTB functions and global caches
    logmsg(verbose, '  clear PsychtoolboxVersion / Screen');
    clear PsychtoolboxVersion Screen
    logmsg(verbose, '  clear mex/classes; rehash toolboxcache');
    clear mex
    clear classes
    rehash
    rehash toolboxcache
    % Force toolbox cache XML rebuild (can help stubborn cases)
    try
        cf = dir(fullfile(prefdir,'toolbox_cache-*.xml'));
        if ~isempty(cf)
            logmsg(verbose, '  deleting toolbox cache XML(s): %d', numel(cf));
            for k = 1:numel(cf)
                delete(fullfile(cf(k).folder, cf(k).name));
            end
            rehash toolboxcache
        end
    catch
        % ignore if not writable
    end
    logmsg(verbose, '  hard flush done (%.3fs).', toc(t));
end

function logmsg(verbose, fmt, varargin)
    if ~verbose, return; end
    fprintf(['[PTB-SWITCH] ', fmt, '\n'], varargin{:});
    drawnow;
end

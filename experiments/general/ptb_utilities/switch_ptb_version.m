function switch_ptb_version(verOrPath, verbose)
% SWITCH_PTB_VERSION  Robust in-session Psychtoolbox switcher (verbose + safe fallback).
%
% Usage:
%   switch_ptb_version('3.0.22.1');        % verbose on (default)
%   switch_ptb_version('3.0.22.1', false); % quiet
%   switch_ptb_version('/full/path/to/Psychtoolbox-3.0.22.1');

    if nargin < 2, verbose = true; end
    ptblog('set', verbose);
    tic; ptblog('=== PTB SWITCH START ===');

    %% Resolve target root
    if isfolder(verOrPath)
        ptb_root = verOrPath;
    else
        homeDir = getenv('HOME');
        bases = { fullfile(homeDir,'Documents','Psychtoolbox_versions'), ...
                  fullfile(homeDir,'Documents','Psychtoolbox_version') };
        ptb_root = '';
        for b = bases
            cand = fullfile(b{1}, ['Psychtoolbox-', verOrPath]);
            if isfolder(cand), ptb_root = cand; break; end
        end
        if isempty(ptb_root)
            error('PTB folder not found. Checked:\n  %s\n  %s', bases{1}, bases{2});
        end
    end
    ptblog('Target root: %s', ptb_root);

    % choose subtree (wrapper vs flat)
    if isfolder(fullfile(ptb_root,'Psychtoolbox'))
        add_root = fullfile(ptb_root,'Psychtoolbox');
    else
        add_root = ptb_root;
    end
    ptblog('Add root:    %s', add_root);

    % best-effort on-disk version (optional)
    vfile = fullfile(add_root,'PsychBasic','PsychtoolboxVersion.m');
    claimed = 'unknown';
    if isfile(vfile)
        txt = fileread(vfile);
        m = regexp(txt,'\b3\.\d+\.\d+(?:\.\d+)?\b','match'); % match 3.x.x or 3.x.x.x
        if ~isempty(m), claimed = m{1}; end
    end
    ptblog('On-disk version claimed: %s', claimed);

    % leave any PTB dir to avoid pwd shadowing
    if contains(lower(pwd),'psychtoolbox')
        cd(getenv('HOME')); ptblog('Moved out of PTB directory.');
    end

    %% 1) Bounded removal of old PTB paths; fallback if needed
    tokens = lower(["psychtoolbox","psychapps","psychbasic","psychcontributed","psychdemos", ...
                    "psychhardware","psychjava","psychmatlabtests","psychobsolete", ...
                    "psychopengl","psychoptics","psychpriority","psychsound"]);

    max_iters = 3; total_removed = 0;
    for iter = 1:max_iters
        p = strsplit(path, pathsep);

        % mark entries that look like PTB
        isptb = false(size(p));
        for k = 1:numel(p)
            pk = lower(p{k});
            for tkn = tokens
                if contains(pk, tkn), isptb(k) = true; break; end
            end
        end

        % also mark folders hosting current defining files (if any)
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
            ptblog('Removed PTB paths in %d iteration(s). Total removed: %d', iter-1, total_removed);
            break;
        end

        ptblog('Iteration %d: removing %d PTB path entries...', iter, numel(idx));
        for ii = 1:numel(idx)
            if ~isempty(p{idx(ii)}) && exist(p{idx(ii)},'dir')
                rmpath(p{idx(ii)}); total_removed = total_removed + 1;
            end
        end
        drawnow;

        if iter == max_iters
            ptblog('[FALLBACK] PTB paths still present after %d passes. Using restoredefaultpath...', max_iters);
            restoredefaultpath; rehash toolboxcache;
            % delete toolbox cache XML if present (forces rebuild)
            try
                cf = dir(fullfile(prefdir,'toolbox_cache-*.xml'));
                for k = 1:numel(cf), delete(fullfile(cf(k).folder, cf(k).name)); end
                rehash toolboxcache;
            catch, end
        end
    end

    %% 2) Add target PTB immediately (no clears beforehand!)
    ptblog('Adding PTB paths...');
    addpath(genpath(add_root), '-begin');

    % --- FORCE a restart-like refresh (do this AFTER addpath) ---
    % 1) Evict key PTB symbols so they reload from the new tree
    clear PsychtoolboxVersion Screen
    % 2) Unload MEXes and flush class & Java caches
    clear mex
    clear classes
    clear java
    % 3) Rebuild function & toolbox indices
    rehash
    rehash toolboxcache
    % 4) (Hard) nuke the toolbox cache XML so indexing is rebuilt from disk
    try
        cf = dir(fullfile(prefdir,'toolbox_cache-*.xml'));
        for k = 1:numel(cf)
            delete(fullfile(cf(k).folder, cf(k).name));
        end
        rehash toolboxcache
    catch
        % ignore if not writable
    end

    % optional overrides
    if exist('ptb_use_overrides','file') == 2
        ptblog('Applying overrides...');
        ptb_use_overrides(); rehash toolboxcache;
    end

    %% 3) (Optional extra) small refresh again to be safe
    clear PsychtoolboxVersion Screen
    clear mex
    rehash; rehash toolboxcache;

    %% 4) Derive the ACTIVE PTB root from what MATLAB resolves now
    pv = which('PsychtoolboxVersion','-all');
    assert(~isempty(pv), 'PsychtoolboxVersion not found after adding PTB.');
    pvfile = pv{1};                                % active definition
    runtime_root = fileparts(fileparts(pvfile));   % .../PsychBasic/.. -> PTB root

    %% 5) Report
    ptblog('Verifying symbols...');
    if ptblog('isverbose')
        disp('which PsychtoolboxVersion -all'); disp(pv);
        disp('which Screen -all');             disp(which('Screen','-all'));
    end
    try
        vr = PsychtoolboxVersion;
        ptblog('PsychtoolboxVersion says (runtime): %s', vr);
    catch ME
        ptblog('PsychtoolboxVersion call failed: %s', ME.message);
    end

    % Warn if Screen MEX missing (use runtime_root; not add_root)
    sbin = dir(fullfile(runtime_root,'**','Screen.mexmaca64'));  % Apple silicon
    if isempty(sbin)
        ptblog('WARNING: Screen.mexmaca64 not found under %s. Tree may be source-only/incomplete.', runtime_root);
    else
        ptblog('Found Screen.mexmaca64 at: %s', fullfile(sbin(1).folder, sbin(1).name));
    end

    ptblog('=== PTB SWITCH DONE (%.3fs) ===', toc);
end

% ------------------------- persistent logger -------------------------------
function out = ptblog(cmd, varargin)
% ptblog('set', true/false) -> set verbosity (persistent)
% ptblog(fmt, ...)          -> print if verbose
% tf = ptblog('isverbose')  -> query flag
    persistent vFlag
    if nargin>=1 && ischar(cmd)
        switch cmd
            case 'set'
                vFlag = logical(varargin{1}); out = [];
            case 'isverbose'
                out = ~isempty(vFlag) && vFlag;
            otherwise
                if ~isempty(vFlag) && vFlag
                    fprintf(['[PTB-SWITCH] ', cmd, '\n'], varargin{:});
                    drawnow;
                end
                out = [];
        end
    else
        out = [];
    end
end

function clear_ptb_path(verbose)
%CLEAR_PTB_PATH  Remove all Psychtoolbox folders from MATLAB path.
% Usage:
%   clear_ptb_path
%   clear_ptb_path(true)   % also prints removed paths
%
% This function searches the MATLAB path for any folders containing the
% string "psychtoolbox" (case-insensitive) and removes them.  Useful when
% switching PTB versions or starting from a clean environment.

    if nargin < 1, verbose = false; end

    % Split the current MATLAB path into its component folders
    p = strsplit(path, pathsep);

    % Identify folders that contain "psychtoolbox"
    isptb = contains(lower(p), 'psychtoolbox');

    % Optionally show what will be removed
    if verbose
        disp('Removing these Psychtoolbox paths:');
        disp(p(isptb).');
    end

    % Remove all matching folders from the path
    cellfun(@rmpath, p(isptb));

    % Refresh the toolbox cache
    rehash toolboxcache;

    if verbose
        fprintf('Removed %d Psychtoolbox path entries.\n', nnz(isptb));
    end
end

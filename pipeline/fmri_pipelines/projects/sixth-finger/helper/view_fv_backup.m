function freeview_cmd = view_fv(whichSub, bidsDir, varargin)
% View overlay on inflated surface in freeview
% Simplified version for sixthfinger project (no ROI labels)
%
% Inputs:
%   whichSub - subject ID (e.g., 'sub-0853' or '0853')
%   bidsDir - BIDS directory path
%   varargin - optional hemisphere ('l', 'r') followed by overlay names
%              e.g., 'thumb', 'index', 'middle', 'ring', 'pinky'
%
% Example usage:
%   view_fv('sub-0853', bidsDir, 'thumb', 'index', 'middle', 'ring', 'pinky');
%   view_fv('sub-0853', bidsDir, 'l', 'thumb'); % left hemisphere only

derivDir = [bidsDir '/derivatives'];

%% Check if BIDS derivatives directory exists
if ~exist(derivDir, 'dir')
    error(['BIDS derivatives directory does not exist: ' derivDir])
end

% Expand ~ if present
if contains(derivDir, '~')
    derivDir = strrep(derivDir, '~', getenv('HOME'));
end

%% Find subject directory
if ~contains(whichSub, 'sub-')
    whichSub = ['sub-' whichSub];
end

subfolder = dir(sprintf('%s/freesurfer/*%s*', derivDir, whichSub));
if isempty(subfolder)
    % Try without 'sub-' prefix
    tmp = strsplit(whichSub, '-');
    subfolder = dir(sprintf('%s/freesurfer/*%s*', derivDir, tmp{2}));
end

if isempty(subfolder)
    error(['Could not find FreeSurfer directory for subject: ' whichSub])
end

subfolderName = subfolder([subfolder.isdir]).name;
subjectDir = sprintf('%s/freesurfer/%s', derivDir, subfolderName);

%% Check if freeview exists
tmpDir = dir(fullfile('/Applications/freesurfer/*'));
fsPattern = '^\d+\.\d+\.\d+$'; % e.g., 7.4.1
fvCmd = '';
for ii = 1:length(tmpDir)
    if ~isempty(regexp(tmpDir(ii).name, fsPattern, 'once'))
        fvDir = [tmpDir(ii).folder '/' tmpDir(ii).name];
        setenv('FREESURFER_HOME', fvDir);
        fvCmd = [fvDir '/bin/freeview'];
    end
end

if isempty(fvCmd)
    error('Could not find FreeSurfer installation in /Applications/freesurfer/')
end

setenv('SUBJECTS_DIR', [derivDir '/freesurfer']);

%% Check which hemisphere to plot
if ~isempty(varargin) && ismember(lower(varargin{1}), {'l', 'lh', 'left'})
    hemi = {'l'};
    varargin = varargin(2:end);
elseif ~isempty(varargin) && ismember(lower(varargin{1}), {'r', 'rh', 'right'})
    hemi = {'r'};
    varargin = varargin(2:end);
else
    hemi = {'l', 'r'};
end

%% Build freeview command for each hemisphere
cmd = [];
for whichHemi = 1:numel(hemi)

    % Find the inflated surface
    inflated = sprintf('%s/surf/%sh.inflated', subjectDir, hemi{whichHemi});

    % Check if the inflated surface file exists
    if ~exist(inflated, 'file')
        error(['Inflated surface not found: ' inflated]);
    end

    % Build overlay command
    overlayCmd = '';
    fingersDir = sprintf('%s/fingers/%s', derivDir, whichSub);

    for whichOverlay = 1:length(varargin)
        overlayName = varargin{whichOverlay};
        whereOverlay = sprintf('%s/%sh.%s.mgz', fingersDir, hemi{whichHemi}, overlayName);

        if exist(whereOverlay, 'file')
            % Add overlay with default colorwheel settings
            overlayCmd = [overlayCmd, sprintf(':overlay=%s:overlay_color=colorwheel,inverse', whereOverlay)];
            fprintf('Found overlay: %s\n', whereOverlay);
        else
            warning(['Overlay not found: ' whereOverlay]);
        end
    end

    if isempty(overlayCmd)
        warning(['No overlay files found for ' hemi{whichHemi} 'h hemisphere']);
    end

    % Add surface and overlays to command (no ROI labels)
    cmd = sprintf('%s -f %s%s', cmd, inflated, overlayCmd);

end

%% Execute freeview command
freeview_cmd = sprintf('%s%s &', fvCmd, cmd);
fprintf('Launching freeview with command:\n%s\n', freeview_cmd);
system(freeview_cmd);

end
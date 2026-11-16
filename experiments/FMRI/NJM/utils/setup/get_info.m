function info = get_info(experimentDir, mode, opts)
% GET_INFO - Ask for subject, session and run, and build the output file names
%
% Inputs:
%   experimentDir - NJM folder
%   mode          - 'task' (default) or 'practice'
%   opts          - optional struct; if it has subjectID, sessionID and runID
%                   the dialog is skipped (used by the test scripts).
%                   opts.overwrite = true keeps going when the run exists.
%
% Output:
%   info - subjectID, sessionID, runID, runNumber, taskName, dataDir and the
%          file names (BIDS order sub-ses-task-run):
%            fullPath (.mat), fullPathTSV / fullPathJSON (events),
%            designPath (the participant's randomised design, shared by all runs),
%            eyeFileBase (EDF name on the EyeLink host, 8 characters max)

if nargin < 2 || isempty(mode), mode = 'task'; end
if nargin < 3 || isempty(opts), opts = struct(); end

if strcmp(mode, 'practice'), taskName = 'njmpractice'; else, taskName = 'njm'; end

if all(isfield(opts, {'subjectID', 'sessionID', 'runID'}))
    answer = {char(opts.subjectID), char(opts.sessionID), char(opts.runID)};
else
    prompt = {'Subject ID (e.g., 0201):', 'Session ID (e.g., 01):', 'Run (1 to 4):'};
    definput = {'9999', '01', '1'};
    if strcmp(mode, 'practice'), prompt{3} = 'Practice run number:'; end
    answer = inputdlg(prompt, sprintf('NJM %s', mode), [1 50], definput);
    if isempty(answer)
        error('User cancelled');
    end
end

info.subjectID = regexprep(strtrim(answer{1}), '^sub-', '');
info.sessionID = regexprep(strtrim(answer{2}), '^ses-', '');
runStr = regexprep(strtrim(answer{3}), '^run-', '');
info.runNumber = str2double(runStr);
if isnan(info.runNumber) || info.runNumber < 1 || info.runNumber ~= round(info.runNumber)
    error('get_info:run', 'Run must be a whole number (got "%s")', runStr);
end
info.runID = sprintf('%02d', info.runNumber);
info.taskName = taskName;
info.mode = mode;

dataDir = fullfile(experimentDir, 'data', 'exp', sprintf('sub-%s', info.subjectID), sprintf('ses-%s', info.sessionID));
if ~exist(dataDir, 'dir'), mkdir(dataDir); end
info.dataDir = dataDir;

% BIDS entity order: sub - ses - task - run
stem = sprintf('sub-%s_ses-%s_task-%s', info.subjectID, info.sessionID, taskName);
fileName = sprintf('%s_run-%s', stem, info.runID);
info.fileName = fileName;
info.fullPath = fullfile(dataDir, [fileName '.mat']);
info.fullPathTSV = fullfile(dataDir, [fileName '_events.tsv']);
info.fullPathJSON = fullfile(dataDir, [fileName '_events.json']);
info.designPath = fullfile(dataDir, [stem '_design.csv']);

% EyeLink host file name: 8 characters max, letters and digits only
tag = regexprep(info.subjectID, '[^A-Za-z0-9]', '');
tag = tag(max(1, end - 3):end);
if strcmp(mode, 'practice'), letter = 'P'; else, letter = 'R'; end
info.eyeFileBase = sprintf('N%s%s%d', tag, letter, mod(info.runNumber, 10));

% Never lose data: an existing run is kept under a new name before running again
if exist(info.fullPath, 'file')
    if isfield(opts, 'overwrite') && opts.overwrite
        choice = 'Yes';
    else
        choice = questdlg(sprintf(['Run %s already exists for sub-%s ses-%s.\n\n' ...
            'Run it again? The existing files are kept with "_old-<time>" added to their names.'], ...
            info.runID, info.subjectID, info.sessionID), 'Run exists', 'Yes', 'No', 'No');
    end
    if ~strcmp(choice, 'Yes')
        error('User chose not to overwrite');
    end
    stamp = datestr(now, 'yyyymmddTHHMMSS');
    old = {info.fullPath, info.fullPathTSV, info.fullPathJSON};
    for i = 1:numel(old)
        if exist(old{i}, 'file')
            [p, f, e] = fileparts(old{i});
            movefile(old{i}, fullfile(p, sprintf('%s_old-%s%s', f, stamp, e)));
        end
    end
end

end

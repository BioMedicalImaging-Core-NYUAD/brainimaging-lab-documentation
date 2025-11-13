function info = get_info(experimentDir, taskName)
% GET_INFO - Prompt user for subject, session, run, and task info
%
% Input:
%   experimentDir - Root directory of the experiment
%   taskName      - Optional task name
%
% Output:
%   info - Structure with subjectID, sessionID, runID, taskName, 
%          dataDir, fullPath, fullPathTSV, fullPathJSON

if nargin < 2
    taskName = '';
end

prompt = {'Subject ID (e.g., 0201):', ...
          'Session ID (e.g., 01):', ...
          'Run ID (e.g., 01):', ...
          'Task Name (optional):'};
answer = inputdlg(prompt, 'BIDS Information', [1 50], {'', '', '', taskName});

if isempty(answer)
    error('User cancelled');
end

info.subjectID = strtrim(answer{1});
info.sessionID = strtrim(answer{2});
info.runID = strtrim(answer{3});
info.taskName = strtrim(answer{4});

% Remove prefixes if present
info.subjectID = regexprep(info.subjectID, '^sub-', '');
info.sessionID = regexprep(info.sessionID, '^ses-', '');
info.runID = regexprep(info.runID, '^run-', '');

% Create directory structure
dataDir = fullfile(experimentDir, 'data');
if ~exist(dataDir, 'dir')
    mkdir(dataDir);
end
subDir = fullfile(dataDir, sprintf('sub-%s', info.subjectID));
if ~exist(subDir, 'dir')
    mkdir(subDir);
end
sesDir = fullfile(subDir, sprintf('ses-%s', info.sessionID));
if ~exist(sesDir, 'dir')
    mkdir(sesDir);
end

info.dataDir = sesDir;

% Build filename
fileName = sprintf('sub-%s_ses-%s_run-%s', info.subjectID, info.sessionID, info.runID);
if ~isempty(info.taskName)
    fileName = sprintf('%s_task-%s', fileName, info.taskName);
end

info.fullPath = fullfile(sesDir, [fileName '.mat']);
info.fullPathTSV = fullfile(sesDir, [fileName '_events.tsv']);
info.fullPathJSON = fullfile(sesDir, [fileName '_events.json']);

% Check if file exists
if exist(info.fullPath, 'file')
    choice = questdlg(sprintf('File exists:\n%s\n\nOverwrite?', info.fullPath), ...
        'File Exists', 'Yes', 'No', 'No');
    if ~strcmp(choice, 'Yes')
        error('User chose not to overwrite');
    end
end

end


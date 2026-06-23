function info = get_info(experimentDir, taskName)
% GET_INFO - Prompt user for subject, session, run, and task info.

if nargin < 2
    taskName = 'bh';
end

prompt = {'Subject ID (e.g., 0872):', ...
          'Session ID (e.g., 01):', ...
          'Run ID (e.g., 01):', ...
          'Task Name:'};
definput = {'9999', '01', '01', taskName};
answer = inputdlg(prompt, 'BIDS Information', [1 50], definput);

if isempty(answer)
    error('User cancelled');
end

info.subjectID = regexprep(strtrim(answer{1}), '^sub-', '');
info.sessionID = regexprep(strtrim(answer{2}), '^ses-', '');
info.runID = regexprep(strtrim(answer{3}), '^run-', '');
info.taskName = strtrim(answer{4});

dataDir = fullfile(experimentDir, 'data', 'exp', ...
    sprintf('sub-%s', info.subjectID), sprintf('ses-%s', info.sessionID));
if ~exist(dataDir, 'dir')
    mkdir(dataDir);
end
info.dataDir = dataDir;

fileName = sprintf('sub-%s_ses-%s_task-%s_run-%s', ...
    info.subjectID, info.sessionID, info.taskName, info.runID);

info.fullPath = fullfile(dataDir, [fileName '.mat']);
info.fullPathTSV = fullfile(dataDir, [fileName '_events.tsv']);
info.fullPathJSON = fullfile(dataDir, [fileName '_events.json']);
info.fullPathDM = fullfile(dataDir, [fileName '_dm.csv']);

if exist(info.fullPath, 'file')
    choice = questdlg(sprintf('File exists:\n%s\n\nOverwrite?', info.fullPath), ...
        'File Exists', 'Yes', 'No', 'No');
    if ~strcmp(choice, 'Yes')
        error('User chose not to overwrite');
    end
end

end

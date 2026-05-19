function datafiles = load_dataLog(dataLog, space, bidsDir)
% Load functional data from fMRIPrep output
% Inputs:
%   dataLog - table with columns: subject, session, task, run
%   space - surface space (e.g., 'fsnative')
%   bidsDir - path to BIDS directory
% Outputs:
%   datafiles - cell array of concatenated L+R hemisphere data

fsHome = '/Applications/freesurfer/8.1.0';  % <-- **CHANGE THIS to your actual path**
fullPathToConvert = fullfile(fsHome, 'bin', 'mri_convert');

% Set FreeSurfer environment variables (required for mri_convert to run)
setenv('FREESURFER_HOME', fsHome);8

% Set the license file path -- update this if your license is elsewhere
% FreeSurfer looks for $FREESURFER_HOME/.license by default,
% but you can override with FS_LICENSE
if exist(fullfile(fsHome, 'license.txt'), 'file')
    setenv('FS_LICENSE', fullfile(fsHome, 'license.txt'));
elseif exist(fullfile(fsHome, '.license'), 'file')
    % default location, no need to set FS_LICENSE
else
    warning('FreeSurfer license file not found in %s. mri_convert may fail.', fsHome);
end

nRuns = size(dataLog, 1);
datafiles = cell(1, nRuns);
hemi = {'L'; 'R'};

for iRun = 1:nRuns
    % Build file path
    subDir = sprintf('%s/derivatives/fmriprep/%s/%s/func', ...
        bidsDir, dataLog.subject{iRun}, dataLog.session{iRun});

    func = cell(2, 1); % Initialize for 2 hemispheres

    for iH = 1:numel(hemi)
        % Build filename for this run
        fileName = sprintf('%s/%s_%s_task-%s_run-%02d_hemi-%s_space-%s_bold.func', ...
            subDir, dataLog.subject{iRun}, dataLog.session{iRun}, ...
            dataLog.task{iRun}, dataLog.run(iRun), hemi{iH}, space);

        inputFile = [fileName '.gii'];
        outputFile = [fileName '.mgh'];

        % Check if MGH file exists, if not convert from GIFTI
        if ~exist(outputFile, 'file')
            if ~exist(inputFile, 'file')
                error('Neither .mgh nor .gii file found: %s', fileName);
            end
            fprintf('Converting %s to .mgh format...\n', inputFile);
            command = [fullPathToConvert ' ' inputFile ' ' outputFile];
            [status, result] = system(command);
            if status ~= 0
                error('mri_convert failed (exit code %d):\n%s', status, result);
            end
        end

        fprintf('Loading: %s\n', outputFile);

        % Load MGH file using FreeSurfer function
        tmp = MRIread(outputFile);
        func{iH} = squeeze(tmp.vol); % Extract data (vertices x timepoints)
    end

    % Concatenate left and right hemispheres
    datafiles{iRun} = cat(1, func{:});
end

end
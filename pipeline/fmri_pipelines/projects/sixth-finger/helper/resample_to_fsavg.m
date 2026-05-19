function resample_to_fsavg(subID, ses, task, bidsDir, fsHome)
% Resample per-finger beta .mgz files from fsnative to fsaverage space
% using mri_surf2surf.
%
% Inputs:
%   subID   - e.g. 'sub-0872'
%   ses     - e.g. 'ses-01'
%   task    - 'Execution' or 'Imagery'
%   bidsDir - root project directory
%   fsHome  - path to FreeSurfer install, e.g. '/Applications/freesurfer/8.1.0'

% --- FreeSurfer environment setup  ---
setenv('FREESURFER_HOME', fsHome);
setenv('SUBJECTS_DIR', fullfile(bidsDir, 'derivatives', 'freesurfer'));
if exist(fullfile(fsHome, 'license.txt'), 'file')
    setenv('FS_LICENSE', fullfile(fsHome, 'license.txt'));
end
surf2surf = fullfile(fsHome, 'bin', 'mri_surf2surf');

% --- Finger names per task ---
if strcmp(task, 'Imagery')
    fingerNames = {'thumb', 'index', 'middle', 'ring', 'pinky', 'sixth'};
else
    fingerNames = {'thumb', 'index', 'middle', 'ring', 'pinky'};
end

hemis = {'lh', 'rh'};

srcDir = fullfile(bidsDir, 'derivatives', task,            subID, ses);
tgtDir = fullfile(bidsDir, 'derivatives', [task '_fsavg'], subID, ses);

if ~exist(tgtDir, 'dir')
    mkdir(tgtDir);
end

% Resample both beta and t-stat maps
suffixes = {'', '_tstat'};  % '' -> lh.thumb.mgz, '_tstat' -> lh.thumb_tstat.mgz

for iH = 1:numel(hemis)
    hemi = hemis{iH};
    h    = hemi(1); % 'l' or 'r' for mri_surf2surf --hemi flag

    for iF = 1:numel(fingerNames)
        finger = fingerNames{iF};

        for iSuf = 1:numel(suffixes)
            suffix  = suffixes{iSuf};
            srcFile = fullfile(srcDir, [hemi '.' finger suffix '.mgz']);
            tgtFile = fullfile(tgtDir, [hemi '.' finger suffix '.mgz']);

            % Skip if already done (caching)
            if exist(tgtFile, 'file')
                fprintf('  [skip] %s %s %s %s.%s%s (already exists)\n', subID, ses, task, hemi, finger, suffix);
                continue
            end

            if ~exist(srcFile, 'file')
                warning('Source file not found, skipping: %s', srcFile);
                continue
            end

            cmd = sprintf('%s --srcsubject %s --trgsubject fsaverage --hemi %sh --sval %s --tval %s', ...
                surf2surf, subID, h, srcFile, tgtFile);

            fprintf('  Resampling %s %s %s %s.%s%s ...\n', subID, ses, task, hemi, finger, suffix);

            % Retry up to 3 times — mri_surf2surf can segfault intermittently
            % under memory pressure (e.g. Box sync running in background)
            maxAttempts = 3;
            for attempt = 1:maxAttempts
                [status, result] = system(cmd);
                if status == 0
                    break
                end
                fprintf('  Attempt %d failed, retrying...\n', attempt);
                pause(2);
            end
            if status ~= 0
                error('mri_surf2surf failed after %d attempts for %s %s %s %s.%s%s:\n%s', ...
                    maxAttempts, subID, ses, task, hemi, finger, suffix, result);
            end
        end
    end
end

end

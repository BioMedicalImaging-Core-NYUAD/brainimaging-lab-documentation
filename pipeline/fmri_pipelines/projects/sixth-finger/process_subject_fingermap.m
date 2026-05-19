% This is a function that runs the entire pipeline for ONE subject + session
function process_subject_fingermap(subID, ses, dmNum, dmBaseDir, bidsDir, codeDir)
    
    % --- 1. Setup ---
    fprintf('--- Processing Subject: %s | Session: %s | dmNum: %d ---\n', subID, ses, dmNum);

    % --- 2. Subject configuration ---
    sub = subID; 
    space = 'fsnative';
    
    % --- 3. Create dataLog table ---
    imageryRuns = 1:5;
    executionRuns = 1:3;
    nImagery = length(imageryRuns);
    nExecution = length(executionRuns);
    nRuns = nImagery + nExecution; % Total 8 runs
    
    subject = repmat({sub}, nRuns, 1);
    session = repmat({ses}, nRuns, 1);
    
    % Create taskList: 5 'Imagery' then 3 'Execution'
    taskList = [repmat({'Imagery'}, nImagery, 1); repmat({'Execution'}, nExecution, 1)];
    
    % Create runNum: [1, 2, 3, 4, 5, 1, 2, 3]'
    runNum = [imageryRuns'; executionRuns'];
    
    dataLog = table(subject, session, taskList, runNum, ...
        'VariableNames', {'subject', 'session', 'task', 'run'});

    % --- 4. Load functional data (loads all 8 runs) ---
    fprintf('Loading functional data for %s...\n', sub);
    datafiles = load_dataLog(dataLog, space, bidsDir);
   

    % --- 5. Load design matrices (loads all 8 runs) ---
    fprintf('Loading design matrices and noise regressors for %s...\n', sub);
    [dsm, myNoise] = load_dsm(dataLog, dmBaseDir, dmNum, bidsDir);

    % --- 6. Get beta values and t-statistics (computes for all 8 runs) ---
    fprintf('Computing beta values and t-statistics for %s...\n', sub);
    [data, betas, tstats, R2] = get_beta(datafiles, dsm, myNoise);
    % 'betas' and 'tstats' are 1x8 cell arrays.
    % Cells 1-5 are for Imagery
    % Cells 6-8 are for Execution

    % --- 7. Finger names (task-dependent: Imagery has 6th finger) ---
    fingerNames_imagery  = {'thumb', 'index', 'middle', 'ring', 'pinky', 'sixth'};
    fingerNames_execution = {'thumb', 'index', 'middle', 'ring', 'pinky'};
    
    % --- 8. Get FreeSurfer paths (MODIFIED LOGIC) ---
    if startsWith(sub, 'sub-')
        fsSubDir = fullfile(bidsDir, 'derivatives', 'freesurfer');
        tmp = strsplit(sub, '-');
        subID_num = tmp{2};
    else
        subjectFolder = sprintf('%s_%s', sub, ses);
        fsSubDir = fullfile(bidsDir, subjectFolder, 'resources', 'freesurfer');
        tmp = strsplit(sub, '_');
        subID_num = tmp{2};
    end
    
    subfolder = dir(sprintf('%s/*%s*', fsSubDir, subID_num));
    if isempty(subfolder)
        fprintf('ERROR: Could not find FreeSurfer folder for %s in %s\n', sub, fsSubDir);
        return; 
    end
    subfolderName = subfolder([subfolder.isdir]).name;
    fspth = fullfile(fsSubDir, subfolderName);

    % --- 9. Load surfaces and MGZ template (Loaded once) ---
    lcurv = read_curv(fullfile(fspth, 'surf', 'lh.curv'));
    rcurv = read_curv(fullfile(fspth, 'surf', 'rh.curv'));
    leftidx = 1:numel(lcurv);
    rightidx = (1:numel(rcurv)) + numel(lcurv);
    mgz = MRIread(fullfile(fspth, 'mri', 'orig.mgz'));
    
    % --- 10. Process and save maps for EACH TASK (MODIFIED) ---
    
    tasksToProcess = {'Imagery', 'Execution'};
    
    for iTask = 1:length(tasksToProcess)
        currentTask = tasksToProcess{iTask};
        
        % --- A. Find the runs for this task ---
        % 'taskIndices' will be [1 2 3 4 5] for Imagery
        % and [6 7 8] for Execution
        taskIndices = find(strcmp(dataLog.task, currentTask));
        
        % Select only the beta cells for this task
        betas_for_task = betas(taskIndices);
        
        % Determine finger names for this task (Imagery has 6th finger)
        if strcmp(currentTask, 'Imagery')
            fingerNames = fingerNames_imagery;   % 6 fingers
        else
            fingerNames = fingerNames_execution;  % 5 fingers
        end
        nFingers = numel(fingerNames);
        
        % --- B. Average betas and t-stats across runs for this task ---
        fprintf('Computing finger maps for TASK: %s (%d conditions)...\n', currentTask, nFingers);

        % Select t-stat cells for this task
        tstats_for_task = tstats(taskIndices);

        fingerBetas  = cell(1, nFingers);
        fingerTstats = cell(1, nFingers);
        for iFinger = 1:nFingers
            fingerBetas{iFinger}  = mean(cell2mat(cellfun(@(x) x(:, iFinger), betas_for_task,  'UniformOutput', false)), 2);
            fingerTstats{iFinger} = mean(cell2mat(cellfun(@(x) x(:, iFinger), tstats_for_task, 'UniformOutput', false)), 2);
        end

        % --- C. Save results for this task ---
        fprintf('Saving results for TASK: %s...\n', currentTask);

        % Create a task-specific output folder
        resultsDir = fullfile(bidsDir, 'derivatives', currentTask, sub, ses);
        if ~exist(resultsDir, 'dir')
            mkdir(resultsDir);
        end

        for iFinger = 1:nFingers
            fingerName = fingerNames{iFinger};

            % Save beta maps
            mgz.vol = fingerBetas{iFinger}(leftidx);
            MRIwrite(mgz, fullfile(resultsDir, ['lh.' fingerName '.mgz']));
            mgz.vol = fingerBetas{iFinger}(rightidx);
            MRIwrite(mgz, fullfile(resultsDir, ['rh.' fingerName '.mgz']));

            % Save t-stat maps
            mgz.vol = fingerTstats{iFinger}(leftidx);
            MRIwrite(mgz, fullfile(resultsDir, ['lh.' fingerName '_tstat.mgz']));
            mgz.vol = fingerTstats{iFinger}(rightidx);
            MRIwrite(mgz, fullfile(resultsDir, ['rh.' fingerName '_tstat.mgz']));

            fprintf('Saved %s beta and t-stat maps for %s\n', fingerName, currentTask);
        end
    end % End of loop over tasks
    
    fprintf('--- Successfully completed processing for %s ---\n\n', sub);

end
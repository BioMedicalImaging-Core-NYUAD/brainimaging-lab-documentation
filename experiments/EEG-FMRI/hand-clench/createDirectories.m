%%
%FILE HANDLING
function createDirectories(subNum, ALL_SUB,SUB_DIR,RESULTS_DIR,TASK_MAPS,LOG_DIR)
    %create "SubjectData" dir that will contain all the data for all subjects
    if exist(ALL_SUB,'dir')~=7
        mkdir(ALL_SUB);
    end

    %create a "SubNum" dir inside the "SubjectData" dir 
    if exist(SUB_DIR,'dir')~=7 %if the "subNum" directory doesn't exist, create one
        mkdir(SUB_DIR);
    end

     %create a "Results" dir inside the "SubNum" dir
    if exist(RESULTS_DIR,'dir')~=7 %if the "Results" directory doesn't exist, create one
        mkdir(RESULTS_DIR);
        fprintf('making new results directory for subject %s...\n',num2str(subNum))
    end
    
    %create a "TaskMaps" dir inside the "SubNum" dir
    if exist(TASK_MAPS,'dir')~=7 %if the "TaskMaps" directory doesn't exist, create one
        mkdir(TASK_MAPS);
        fprintf('making new task map directory for subject %s...\n',num2str(subNum))
    end

    %create a "logs" dir inside the "SubNum" dir
    if exist(LOG_DIR,'dir')~=7 %if the "TaskMaps" directory doesn't exist, create one
        mkdir(LOG_DIR);
        fprintf('making new log file directory for subject %s...\n',num2str(subNum))
    end
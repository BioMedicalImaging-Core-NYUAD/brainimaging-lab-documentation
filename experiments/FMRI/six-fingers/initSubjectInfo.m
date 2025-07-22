function initSubjectInfo()
    global parameters;
    runNumber = parameters.runNumber;
    currentStudy = parameters.currentStudy;
    currentStudyVersion = parameters.currentStudyVersion;
    
    %subNum = input('Please type subject number: ');  
    %session = input('Please type session number: ');
    subNum = checkCorrectInput('Please type subject number: ');
    session = checkCorrectInput('Please type session number: ');
    
    
    parameters.subjectId = subNum;
    parameters.session = session;
    
    
    % Create all necessary directiries (a directory for each subject, containg Results and TaskMaps)
    %--------------------------------------------------------------------------------------------------------------------------------------%
    % specify the directories to be used
    CWD = [pwd '/']; %current working dir
    ALL_SUB = [CWD 'SubjectData/']; % create "SubjectData" dir that will contain all the data for all subjects
    SUB_DIR = [ALL_SUB num2str(subNum) '/']; % create a "SubNum" dir inside the "SubjectData" dir
    TASK_MAPS = [SUB_DIR 'TaskMaps/'];  % create a "TaskMaps" dir inside the "SubNum" dir
    RESULTS_DIR = [SUB_DIR 'Results/']; % create a "Results" dir inside the "SubNum" dir
    LOG_DIR = [SUB_DIR 'Logs/']; % create a "Logs" dir inside the "SubNum" dir
    
    createDirectories(subNum, ALL_SUB,SUB_DIR,RESULTS_DIR,TASK_MAPS,LOG_DIR);
    
    % Initialize the files to write in
    %--------------------------------------------------------------------------------------------------------------------------------------%
    %specify naming format for the data file
    currentDateVector = datevec(date);
    currentYear = currentDateVector(1)-2000;
    currentMonth =currentDateVector(2);
    currentDay = currentDateVector(3);
    
    dateStr = [num2str(currentYear) int2strz(currentMonth,2) int2strz(currentDay,2)]; 


	subNumStr=int2strz(subNum,2);
	runNumberStr = int2strz(runNumber,2);

    datafile = [RESULTS_DIR currentStudy num2str(currentStudyVersion) subNumStr  num2str(session) '_' runNumberStr '_' dateStr '.csv'];
    matfile = [RESULTS_DIR currentStudy num2str(currentStudyVersion) subNumStr  num2str(session) '_' runNumberStr '_' dateStr '.mat'];
    taskMapFile = [TASK_MAPS currentStudy num2str(currentStudyVersion) subNumStr  num2str(session) '_' runNumberStr '_' dateStr '_taskMap.mat'];
    logFile = [LOG_DIR currentStudy num2str(currentStudyVersion) subNumStr  num2str(session) '_' runNumberStr '_' dateStr '_log.txt'];
    
    parameters.datafile = datafile;
   
    % check for existing result file to prevent accidentally overwriting
    % files from a previous subject/session (except for subject numbers > 99):
    if subNum>0 && subNum<99 && fopen(datafile, 'rt')~=-1
        fclose('all');
        error('ERROR! Result data file already exists! Choose a different subject/session number.');
    end

end
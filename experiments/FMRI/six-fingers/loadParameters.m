%   loads experimental parameters
function loadParameters()
    global parameters;
    %---------------------------------------------------------------------%
    % 
    %---------------------------------------------------------------------%
    %   show/hide cursor on probe window
    parameters.hideCursor = true;
    
    %   to set the demo mode with half-transparent screen
    parameters.isDemoMode = false;
    
    %   screen transparency in demo mode
    parameters.transparency = 0.6;
    
    %   to make screen background darker (close to 0) or lighter (close to 1)
    parameters.greyFactor = 0.6; 
    
 
    parameters.viewDistance = 60;%default
    
    %---------------------------------------------------------------------%
    % study parameters
    %---------------------------------------------------------------------%
    %    set the name of your study
    parameters.currentStudy = 'sixFingers';
    
    %    set the version of your study
    parameters.currentStudyVersion = 1;
    
    %    set the number of current run
    parameters.runNumber = 1;
    
    %    set the name of current session (modifiable in the command prompt)
    parameters.session = 1;
    
    %    set the subject id (modifiable in the command prompt)
    parameters.subjectId = 0;
    
    %---------------------------------------------------------------------%
    % data and log files parameters
    %---------------------------------------------------------------------%
    
    %   default name for the datafiles -- no need to modify. The program 
    %   will set the name of the data file in the following format:
    %   currentStudy currentStudyVersion subNumStr  session '_' runNumberStr '_' currentDate '.csv'
    parameters.datafile = 'unitled.csv';
    parameters.datafile_dm = 'unitled_2.csv';
    parameters.matfile = 'untitled.csv';
  
    %---------------------------------------------------------------------%
    % experiment  parameters
    %---------------------------------------------------------------------%

    
    %   set the number of blocks in your experiment
    parameters.meNumberOfBlocks = 4;
    parameters.meTrials = 5;

    parameters.fingerList = {'thumb', 'index', 'middle', 'ring', 'pinky'};
    parameters.imageMap = containers.Map(...
        parameters.fingerList, ...
        {'hand-01.png', 'hand-02.png', ...
         'hand-03.png', 'hand-04.png', ...
         'hand-05.png'} ...
    );

    parameters.miTrials = 20;
    parameters.miNumberOfBlocks = 3;

    parameters.NT_fingers = {'thumb', 'index', 'middle', 'ring', 'pinky'};
    parameters.ST_finger  = 'sixth';
     parameters.miImageMap = containers.Map(...
        [parameters.NT_fingers, parameters.ST_finger], ...
        {'hand-01.png', 'hand-02.png', ...
         'hand-03.png', 'hand-04.png', ...
         'hand-05.png', 'hand-06.png'} ...
    );

    
    %---------------------------------------------------------------------%
    % tasks durations ( in seconds)
    %---------------------------------------------------------------------%
    
    %   sample task duration
    parameters.blockDuration = 5;

    parameters.fixationDuration = 5;
    parameters.stimulusDuration = 5;
    
    %   eoe task duration
    parameters.eoeTaskDuration = 2;
    
    %---------------------------------------------------------------------%
    % Some string resources 
    %---------------------------------------------------------------------%

    parameters.welcomeMsg = sprintf('Please wait until the experimenter sets up parameters.');
    parameters.ttlMsg = sprintf('Waiting for trigger...');
    parameters.thankYouMsg = sprintf('Thank you for your participation!!!');
    % % parameters.blockOneMsg = sprintf('Stop');
    % % parameters.blockTwoMsg = sprintf('Move tongue');

    %---------------------------------------------------------------------%
    % Some geometry parameters
    %---------------------------------------------------------------------%
    
    %	set the font size
    parameters.textSizeDeg = 0.8;
    
    %	default value for the font size -- no need to modify
    parameters.textSize = 80;

end

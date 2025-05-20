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
    parameters.transparency = 0.8;
    
    %   to make screen background darker (close to 0) or lighter (close to 1)
    parameters.greyFactor = 0.6;
     
    parameters.viewDistance = 60;%default
    
    %---------------------------------------------------------------------%
    % study parameters
    %---------------------------------------------------------------------%
    %    set the name of your study
    parameters.currentStudy = 'restingstate';
    
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
    parameters.matfile = 'untitled.mat';
  
    %---------------------------------------------------------------------%
    % experiment  parameters
    %---------------------------------------------------------------------%

    
    %   set the number of blocks in your experiment
    %parameters.numberOfBlocks = 20;
    % 10 blocks for each finger tapping alternated by 10 blocks of no-tapping
    
    % To regenerate the finger stimulus sequence
%     [~,idx] = sort(rand(5,5));
%     dsm = idx(:)
%   save dsm finger_stimulus_sequence


  
    parameters.numberOfBlocks = 25;
    %---------------------------------------------------------------------%
    % tasks durations ( in seconds)
    %---------------------------------------------------------------------%
    
    %   sample task duration
    parameters.blockDuration = 12;
    
    %   eoe task duration
    parameters.eoeTaskDuration = 2;
    
    %---------------------------------------------------------------------%
    % Some string resources 
    %---------------------------------------------------------------------%

    parameters.welcomeMsg = sprintf('Please wait until the experimenter sets up parameters.');
    parameters.ttlMsg = sprintf('Initializing Scanner...');
    parameters.thankYouMsg = sprintf('Thank you for your participation!!!');
    parameters.blockOneMsg = sprintf('Close your eyes');
    parameters.blockTwoMsg = sprintf('Open your eyes');
 

    %---------------------------------------------------------------------%
    % Some geometry parameters
    %---------------------------------------------------------------------%
    
    %	set the font size
    parameters.textSizeDeg = 4;
    
    %	default value for the font size -- no need to modify
    parameters.textSize = 70;

end

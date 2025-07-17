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
    parameters.currentStudy = 'fingerTap';
    
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
    parameters.datafile = 'untitled.csv';
    parameters.matfile = 'untitled.mat';
  
    %---------------------------------------------------------------------%
    % experiment  parameters
    %---------------------------------------------------------------------%

    %   set the number of blocks in your experiment
    parameters.numberOfBlocks = 20;

    %---------------------------------------------------------------------%
    % tasks durations ( in seconds)
    %---------------------------------------------------------------------%

    %   sample task duration
    parameters.blockDuration = 10;

    %   eoe task duration
    parameters.eoeTaskDuration = 2;

    %---------------------------------------------------------------------%
    % Some string resources 
    %---------------------------------------------------------------------%

       parameters.welcomeMsg = sprintf('Please wait until the experimenter sets up parameters.');
    parameters.ttlMsg = sprintf('Initializing Scanner...');
    parameters.thankYouMsg = sprintf('Thank you for your participation!!!');
    parameters.blockOneMsg = sprintf('X');

    % Load your grayscale image
    parameters.blockTwoImage = imread('clenched_fist.jpg');

    % Desired on-screen dimensions (for display purposes)
    parameters.blockTwoImageWidth = 300;  % Width in pixels
    parameters.blockTwoImageHeight = 300; % Height in pixels

    %---------------------------------------------------------------------%
    % Some geometry parameters
    %---------------------------------------------------------------------%

    parameters.textSizeDeg = 4;
    parameters.textSize = 90;

end

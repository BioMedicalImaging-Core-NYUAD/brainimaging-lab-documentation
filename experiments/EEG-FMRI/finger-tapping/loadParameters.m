%   loads experimental parameters
function loadParameters()
    global parameters;
    %---------------------------------------------------------------------%
    % 
    %---------------------------------------------------------------------%
    
    % Load the trigger dictionary

    load('../general/trig_dict.mat', 'trig_dict');
    
    %   show/hide cursor on probe window
    parameters.hideCursor = true;
    
    %   to set the demo mode with half-transparent screen
    parameters.isDemoMode = true;
    parameters.useVpixx = false;
    
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
    parameters.datafile = 'unitled.csv';
    parameters.matfile = 'untitled.mat';
  
    %---------------------------------------------------------------------%
    % experiment  parameters
    %---------------------------------------------------------------------%

    
    %   set the number of blocks in your experiment
    %parameters.numberOfBlocks = 20;

    
    % To regenerate the finger stimulus sequence
    
    
    % numberOfBlocks is 15 for a real run
    parameters.numberOfBlocks = 15;
    
    [~,idx] = sort(rand(5,parameters.numberOfBlocks/5));
    parameters.blocktype = idx(:);

    %parameters.blocktype = temp.dsm;
    
    parameters.maxRandWaitTime = 2;
    
    parameters.IBW = 0:0.2:parameters.maxRandWaitTime; % Inter-block random wait time (seconds)


    %---------------------------------------------------------------------%
    % tasks durations ( in seconds)
    %---------------------------------------------------------------------%
    
    %   sample task duration
    %parameters.blockDuration = 12;
    % blockDuration = 20
    parameters.blockDuration = 20;
    
    %   eoe task duration
    parameters.eoeTaskDuration = 2;
    
    
    parameters.tapduration = 1.2;
    parameters.pauseduration = 0.8;

    %---------------------------------------------------------------------%
    % Some string resources 
    %---------------------------------------------------------------------%

    parameters.welcomeMsg = sprintf('Please wait until the experimenter sets up parameters.');
    parameters.ttlMsg = sprintf('Initializing Scanner...');
    parameters.thankYouMsg = sprintf('Thank you for your participation!!!');
    
    parameters.blockOneMsg = sprintf('Tap THUMB');
    parameters.blockOneTrig = trig_dict('S1');
    
    parameters.blockTwoMsg = sprintf('Tap INDEX');
    parameters.blockTwoTrig = trig_dict('S2');
    
    parameters.blockThreeMsg = sprintf('Tap MIDDLE');
    parameters.blockThreeTrig = trig_dict('S3');
    
    parameters.blockFourMsg = sprintf('Tap RING');
    parameters.blockFourTrig = trig_dict('S4');
    
    parameters.blockFiveMsg = sprintf('Tap PINKIE');
    parameters.blockFiveTrig = trig_dict('S5');
    
    parameters.stopTap = sprintf('WAIT');

    %---------------------------------------------------------------------%
    % Some geometry parameters
    %---------------------------------------------------------------------%
    
    %	set the font size
    parameters.textSizeDeg = 4;
    
    %	default value for the font size -- no need to modify
    parameters.textSize = 70;

end

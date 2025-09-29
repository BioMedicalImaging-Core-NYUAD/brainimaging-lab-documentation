
% EEG-FMRI experiment for alpha-blocking
% fingertapping: tap each finger then rest
% Author: Hadi Zaatiti <hadi.zaatiti@nyu.edu>

% 25 blocks of 12 seconds duration each
% first block is eyes open then second block is eyes closed
% a .csv is saved with the sequence of the blocks and the time for each block
% an S1 marker is synchronised on the EEG data at the beginning of each block

clear all
close all

global parameters;
global screen;
global tc;
global isTerminationKeyPressed;
global resReport;
global totalTime;

% datapixx = 1 means w're actually listening for the scanner to send us a
% trigger
% datapixx = 0 means w're in demo mode
global datapixx;

Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'Verbosity', 0);

timingsReport = {};

clear map
map = struct('block',0,...
    'startTime',0,...
    'endTime',0,...
    'totalBlockDuration',0);

timingsReport=cell2mat(timingsReport);
addpath('supportFiles');   

%   Load parameters
%--------------------------------------------------------------------------------------------------------------------------------------%
loadParameters();
 
%   Initialize the subject info
%--------------------------------------------------------------------------------------------------------------------------------------%
initSubjectInfo();

% %  Hide Mouse Cursor

if parameters.hideCursor
    HideCursor()
end

%   Initialize screen
%--------------------------------------------------------------------------------------------------------------------------------------%


initScreen(); %change transparency of screen from here

%   Convert values from visual degrees to pixels
%--------------------------------------------------------------------------------------------------------------------------------------%
visDegrees2Pix();

%   Initialize Datapixx
%-------------------------------------------------------------------------- ------------------------------------------------------------%

if ~parameters.isDemoMode
    % datapixx init              
    AssertOpenGL;   % We use PTB-3;
    isReady =  Datapixx('Open');
    Datapixx('StopAllSchedules');
    Datapixx('RegWrRd');    % Synchronize DATAPixx registers to local register cache
end

 

%% Experiment design notes:

% have 25 blocks,  5 blocks for each finger
% pseudo-randomly permute the blocks by:
% ensuring we are getting all the possible sequences of 


%%
%  run the experiment
%--------------------------------------------------------------------------------------------------------------------------------------%
%  

% % %To suspend the output of keyboard to command line
ListenChar(2); 
% 
%  init start of experiment procedures 
%--------------------------------------------------------------------------------------------------------------------------------------%
% 
 %  init scanner
%--------------------------------------------------------------------------------------------------------------------------------------%
% 
if parameters.isDemoMode
    showTTLWindow_1();
else
    showTTLWindow_2();
end

%  iterate over all blocks 
%--------------------------------------------------------------------------------------------------------------------------------------%
%  
timing.soeDuration = 0;
isTerminationKeyPressed = false;

tic
for   tc =  1 : parameters.numberOfBlocks
    
    block_type = mod(tc,2)
    
    switch block_type
        case 0
            % blocktype = 0 means closed eyes
            blockText = parameters.blockOneMsg;
        case 1
            % blocktype = 1 means eyes open
            blockText = parameters.blockTwoMsg;
    end

    
    [blockStartTime, blockEndTime] = showBlockWindow(blockText, block_type);

    %% Putti says: if we are moving the right hand, this means the right hemisphere is not being used
    % in this case, we can use all the signals from the right hemisphere as a baseline
    % According to the paper https://pmc.ncbi.nlm.nih.gov/articles/PMC3713710/pdf/HBM-33-1594.pdf
    % it is best to have a random permutation of the finger order to get a better spatial accuracy
    % according to Putti: we should correct for the MRI artifact (causing higher signal amplitudes with time) that has an upward trend with time (this is done by adding a linear drift vector at the end of the design matrix)
    % Add a first vector of constant values in order to take the average of the BOLD signals from all fingers as a baseline
    % In the paper the block duration is 3 seconds, however we can then take 12 seconds per finger

    timingsReport(:,tc).trial = tc;
    timingsReport(:,tc).startTime =  blockStartTime;
    timingsReport(:,tc).endTime =  blockEndTime;
    timingsReport(:,tc).totalBlockDuration = blockEndTime - blockStartTime;
    timingsReport(:,tc).blocktype = block_type;
end
%  init end of experiment procedures 
%--------------------------------------------------------------------------------------------------------------------------------------%
%
startEoeTime = showEoeWindow();

% 
%  save the data
%--------------------------------------------------------------------------------------------------------------------------------------%
% 

writetable(struct2table(timingsReport),parameters.datafile);


%   To allow the output of keyboard to command line
ListenChar(1);

% Show cursor back
ShowCursor('Arrow');
 
sca;

if ~parameters.isDemoMode
    % datapixx shutdown
    Datapixx('RegWrRd');
    Datapixx('StopAllSchedules');
    Datapixx('Close');
end


%% What do we need to save?

% We need the stimulus finger sequence
% The ID of the subject
% Beginning and end of each block

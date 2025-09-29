%fingertapping- this one for haidee only stop and tap 

clear all
close all

global parameters;
global screen;
global tc;
global isTerminationKeyPressed;
global resReport;
global totalTime;
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
    datapixx = 0;               
    AssertOpenGL;   % We use PTB-3;
    isReady =  Datapixx('Open');
    Datapixx('StopAllSchedules');
    Datapixx('RegWrRd');    % Synchronize DATAPixx registers to local register cache
end

 


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


for   tc =  1 : parameters.numberOfBlocks
    if mod(tc,2) ~= 0
        blockText = parameters.blockOneMsg;
    else
        blockText = parameters.blockTwoMsg;
    end
    
    [blockStartTime, blockEndTime] = showBlockWindow(blockText);
    
    timingsReport(:,tc).trial = tc;
    timingsReport(:,tc).startTime =  blockStartTime;
    timingsReport(:,tc).endTime =  blockEndTime;
    timingsReport(:,tc).totalBlockDuration = blockEndTime - blockStartTime;
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

% Trigger test for EEG-FMRI
% Author: Hadi Zaatiti <hadi.zaatiti@nyu.edu>
% Authors: Hadi Zaatiti <hadi.zaatiti@nyu.edu>, Haidee Paterson
% <haidee.paterson@nyu.edu>

%fingertapping- this one for haidee only stop and tap 
% big font

clear all
close all

global parameters;
global screen;
global tc;
global isTerminationKeyPressed;
global resReport;
global totalTime;
global datapixx;
global datapixx; 
global PSYCHTOOLBOX;
global VPIXX_USE;

VPIXX_USE = false;
VPIXX_USE = true;
PSYCHTOOLBOX = false;

% Pinout of the trigger socket (digital port) on USB2 Adapter on the
% EEG-FMRI trigger box

% +-----------------------------------------------------+
% | Pin on 26-pin HD D-Sub    | Function   | 25-pin D-Sub/LPT on  | BNC connector on |
% | trigger socket (digital   |            | trigger cable        | trigger cable     |
% | port)                     |            |                      |                  |
% +-----------------------------------------------------+
% |  1                        | Ground     | 25                   | Ground           |
% |  2                        | D01 (S 2)  | 3                    |                  |
% |  3                        | D03 (S 8)  | 5                    |                  |
% |  4                        | D05 (S 32) | 7                    |                  |
% |  5                        | D07 (S128) | 9                    |                  |
% |  6                        | D09 (R 2)  |                      |                  |
% |  7                        | D11 (R 8)  |                      |                  |
% |  8                        | D13 (R 32) |                      |                  |
% |  9                        | D15 (R128) |                      | Signal           |
% | 10                        | Unused     |                      |                  |
% | 11                        | Unused     |                      |                  |
% | 12                        | VCC +3.3 V |                      |                  |
% | 13                        | Unused     |                      |                  |
% | 14                        | D00 (S 1)  | 2                    |                  |
% | 15                        | D02 (S 4)  | 4                    |                  |
% | 16                        | D04 (S 16) | 6                    |                  |
% | 17                        | D06 (S 64) | 8                    |                  |
% | 18                        | D08 (R 1)  |                      |                  |
% | 19                        | D10 (R 4)  |                      |                  |
% | 20                        | D12 (R 16) |                      |                  |
% | 21                        | D14 (R 64) |                      |                  |
% | 22                        | Ground     | 1                    |                  |
% | 23                        | Block+     |                      |                  |
% | 24                        | Block-     |                      |                  |
% | 25                        | 5 kHz out  |                      |                  |
% | 26                        | Unused     |                      |                  |
% +-----------------------------------------------------+


% Table 3: Digital output pin assignment from Vpixx system towards EEG-FMRI
% trigger Box

% +--------------------+--------------------+--------------------+-------------------+
% |        Pin          |     Description    |        Pin          |    Description    |
% +--------------------+--------------------+--------------------+-------------------+
% |         1           |   Digital Out 0    |         14          |   Digital Out 1   |
% |         2           |   Digital Out 2    |         15          |   Digital Out 3   |
% |         3           |   Digital Out 4    |         16          |   Digital Out 5   |
% |         4           |   Digital Out 6    |         17          |   Digital Out 7   |
% |         5           |   Digital Out 8    |         18          |   Digital Out 9   |
% |         6           |   Digital Out 10   |         19          |   Digital Out 11  |
% |         7           |   Digital Out 12   |         20          |   Digital Out 13  |
% |         8           |   Digital Out 14   |         21          |   Digital Out 15  |
% |         9           |   Digital Out 16   |         22          |   Digital Out 17  |
% |        10           |   Digital Out 18   |         23          |   Digital Out 19  |
% |        11           |   Digital Out 20   |         24          |   Digital Out 21  |
% |        12           |   Digital Out 22   |         25          |   Digital Out 23  |
% |        13           |        GND         |      Shield *       |        Shield     |
% +--------------------+--------------------+--------------------+-------------------+

% * Shield is tied to the GND by a 0 Ohm resistor inside the DATAPixx system.



if PSYCHTOOLBOX
    Screen('Preference', 'SkipSyncTests', 1);
    Screen('Preference', 'Verbosity', 0);
end
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

if PSYCHTOOLBOX
    if parameters.hideCursor
        HideCursor()
    end

%   Initialize screen
%--------------------------------------------------------------------------------------------------------------------------------------%
initScreen(); %change transparency of screen from here
    %   Initialize screen
    %--------------------------------------------------------------------------------------------------------------------------------------%
    initScreen(); %change transparency of screen from here


%   Convert values from visual degrees to pixels
%--------------------------------------------------------------------------------------------------------------------------------------%
visDegrees2Pix();
    %   Convert values from visual degrees to pixels
    %--------------------------------------------------------------------------------------------------------------------------------------%
    visDegrees2Pix();
end
%   Initialize Datapixx
%-------------------------------------------------------------------------- ------------------------------------------------------------%

if VPIXX_USE
    if ~parameters.isDemoMode
        % datapixx init
        datapixx = 1;               
        AssertOpenGL;   % We use PTB-3;
        isReady =  Datapixx('Open');
        Datapixx('StopAllSchedules');
        Datapixx('RegWrRd');    % Synchronize DATAPixx registers to local register cache
    end
end

        if ~parameters.isDemoMode
            % datapixx init
            datapixx = 1;               
            AssertOpenGL;   % We use PTB-3;
            isReady =  Datapixx('Open');
            Datapixx('StopAllSchedules');
            Datapixx('RegWrRd');    % Synchronize DATAPixx registers to local register cache
        end


% Show how many TTL output bits are in the Datapixx
nBits = Datapixx('GetDoutNumBits');
fprintf('\nDATAPixx has %d TTL output bits\n\n', nBits);
    % Show how many TTL output bits are in the Datapixx
    nBits = Datapixx('GetDoutNumBits');
    fprintf('\nDATAPixx has %d TTL output bits\n\n', nBits);

% Bring 1 output high
HitKeyToContinue('\nHit any key to bring digital output bit 0 high:');
Datapixx('SetDoutValues', 1);
Datapixx('RegWrRd');
    % Bring 1 output high
    %HitKeyToContinue('\nHit any key to bring digital output bit 0 high:');
    Datapixx('SetDoutValues', 1);
    Datapixx('RegWrRd');


% In MRI we have a 25-pin D-Sub cable so we care about this column
% Trigger S2 marker by activating the 3rd pin of the 25-pin D-sub cable
% The 3rd pin corresponds to digital output 4 on the vpixx system
% 4 in binary is 0100
    % In MRI we have a 25-pin D-Sub cable so we care about this column
    % Trigger S2 marker by activating the 3rd pin of the 25-pin D-sub cable
    % The 3rd pin corresponds to digital output 4 on the vpixx system
    % 4 in binary is 0100
    

% Should trigger S2 marker on EEG
% SetDoutValues will activate the bits according to the value taken as
% input
% The input value is a decimal which when converted to binary, the 1's will
% be the activated pins and the 0's will be deactivated pins
% For example if we set provide as input the value 2^24 -1 = 16777215
% in binary that is: 111111111111111111111111, on 24 bits
% In this case we are settings all the pins to 1
% Takes a decimal  that if you write in binary represents
% Example 1: 
% - To activate the S2 marker, this corresponds to the pin number 3 on the
% 25-pin sub cable according to BP sheet, to activate pin number 3, this
% corresponds to Digital Out 4, according to Vpixx
% - 4 = 2^2 = 100
% 
% Example 2:
% - To activate the S1 marker, this corresponds to pin number 2 according
% to BP
% - Pin number 2 is on the Digital Out 2
% - attempt to send 2 on digital out to activate S1
HitKeyToContinue('\nHit any key to bring the EEG S2 marker on:');
Datapixx('SetDoutValues', (2^nBits) - 1);
Datapixx('RegWrRd');
    
% Should trigger S2 marker on EEG
%HitKeyToContinue('\nHit any key to bring the EEG S2 marker on:');

% Set total duration (in seconds) to run the loop
totalDuration = 500; % e.g., 30 seconds

% Set pause duration (in seconds) between each instruction
pauseDuration = 2; % e.g., 2 seconds


    
    
    
    %Activate Current State
    
    
    
    % We can only control bits 0 to 7
    
    % Binary numbers with a single 1 over 8 bits and their decimal equivalents:
% 00000001 -> 1
% 00000010 -> 2
% 00000100 -> 4
% 00001000 -> 8
% 00010000 -> 16
% 00100000 -> 32
% 01000000 -> 64
% 10000000 -> 128

    
    % Current State = 0

    % Example 1: 
% - To activate the S2 marker, this corresponds to the pin number 3 on the
% 25-pin sub cable according to BP sheet, to activate pin number 3, this
% corresponds to Digital Out 4, according to Vpixx
% - 4 = 2^2 = 100

    % Start the timer
    tic;
    Datapixx('SetDoutValues', 0);
    Datapixx('RegWrRd');

    while toc < totalDuration
        
        % Should trigger the S2 marker on EEG
        %Datapixx('SetDoutValues', 4);
        %Datapixx('RegWrRd');
        
        Datapixx('SetDoutValues', 2);
        Datapixx('RegWrRd');
        disp('all triggers on');
        pause(2);

        Datapixx('SetDoutValues', 0);
        Datapixx('RegWrRd');
        disp('all triggers off');
        % Wait for the specified pause duration
        pause(pauseDuration);
        
    end
    
    % Current State = 0 on all the pins
    % Test S1 marker on EEG

% Example 2:
% - To activate the S1 marker, this corresponds to pin number 2 according
% to BP
% - Pin number 2 is on the Digital Out 2 according to Vpixx
% - 2 = 2^1 = 010
% - attempt to send 2 on digital out to activate S1
    
    tic;
    Datapixx('SetDoutValues', 0);
    Datapixx('RegWrRd');

    while toc < totalDuration
   
        Datapixx('SetDoutValues', 2);
        Datapixx('RegWrRd');
        disp('all triggers on');
        pause(2);

        Datapixx('SetDoutValues', 0);
        Datapixx('RegWrRd');
        disp('all triggers off');
        % Wait for the specified pause duration
        pause(pauseDuration);
        
    end
    
    
    % Current State = 0
 %Example 3: Set the S3 marker
 %
    while toc < totalDuration
        
        % Should trigger the S2 marker on EEG
        %Datapixx('SetDoutValues', 4);
        %Datapixx('RegWrRd');
%         
        Datapixx('SetDoutValues', 4);
        Datapixx('RegWrRd');
        disp('all triggers on');
        pause(2);

        Datapixx('SetDoutValues', 0);
        Datapixx('RegWrRd');
        disp('all triggers off');
        % Wait for the specified pause duration
        pause(pauseDuration);
        
    end
    
    
    
    % Current State = 1
    while toc < totalDuration
        
        % Should trigger the S2 marker on EEG
        %Datapixx('SetDoutValues', 4);
        %Datapixx('RegWrRd');
        
%         
        Datapixx('SetDoutValues', 2);
        Datapixx('RegWrRd');
        disp('all triggers on');
        pause(2);

        Datapixx('SetDoutValues', 0);
        Datapixx('RegWrRd');
        disp('all triggers off');
        % Wait for the specified pause duration
        pause(pauseDuration);
    end
    
    
    %Let us trigger one bit by one bit and send markers:
    
    
    
    
    

    % When the loop finishes
    disp('Finished repeating instructions.');


% Bring all the outputs high
HitKeyToContinue('\nHit any key to bring all the digital outputs high:');
Datapixx('SetDoutValues', (2^nBits) - 1);
Datapixx('RegWrRd');
    
    % Bring all the outputs high
    %HitKeyToContinue('\nHit any key to bring all the digital outputs high:');
    Datapixx('SetDoutValues', (2^nBits) - 1);
    Datapixx('RegWrRd');

% Bring all the outputs low
HitKeyToContinue('\nHit any key to bring all the digital outputs low:');
Datapixx('SetDoutValues', 0);
Datapixx('RegWrRd');

    % Bring all the outputs low
    %HitKeyToContinue('\nHit any key to bring all the digital outputs low:');
    Datapixx('SetDoutValues', 0);
    Datapixx('RegWrRd');
    

if VPIXX_USE
    if ~parameters.isDemoMode
        % datapixx shutdown
        Datapixx('RegWrRd');
        Datapixx('StopAllSchedules');
        Datapixx('Close');
    end
        if ~parameters.isDemoMode
            % datapixx shutdown
            Datapixx('RegWrRd');
            Datapixx('StopAllSchedules');
            Datapixx('Close');
        end
end

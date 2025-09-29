% Trigger test for EEG-FMRI BrainProducts system using NYUAD Vpixx system
% Author: Hadi Zaatiti <hadi.zaatiti@nyu.edu>


% A dictionary in the first cell gives all the codes for each type of
% marker, you can use this dictionary in your experiment script


clear all
close all


global screen;
global tc;
global isTerminationKeyPressed;
global resReport;
global totalTime;


global VPIXX_USE;


VPIXX_USE = true;

%%

% To make a marker S2 appear on the EEG data we must activate pin number 3
% on the 25-pin D-Sub as in Table 1 below
% To activate the pin number 3, we need to activate the Digital Out 4 on
% the Datapixx
% To activate the Digital Out 4, we need to send this combination 00000100 -> 4

% Using Datapixx('SetDoutValues', 4);


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


%% Summary dictionary of trigger code

trig_dict = containers.Map;

trig_dict('S1') = 2^2;  
trig_dict('S2') = 2^4;  
trig_dict('S3') = 2^4+2^2;  
trig_dict('S4') = 2^6; 
trig_dict('S5') = 2^6+2^2;  
trig_dict('S8') = 2^8; 
trig_dict('S16') = 2^10;
trig_dict('S32') = 2^12;
trig_dict('S64') = 2^14;
trig_dict('S128') = 2^16;
trig_dict('S255') = 2^24-1;


%% Saving for global use in other script of the trigger dictionary

% Save the dictionary to a .mat file after any modification of the above or
% adding new marker
save('trig_dict.mat', 'trig_dict');

%% Disable Vpixx Pixel Model incase it is already enabled

Datapixx('Open')
Datapixx('SetPropixxDlpSequenceProgram', 0)
Datapixx('DisablePixelMode')
Datapixx('RegWr')


%%



if VPIXX_USE

        % datapixx init
        datapixx = 1;               
        AssertOpenGL;   % We use PTB-3;
        isReady =  Datapixx('Open');
        Datapixx('StopAllSchedules');
        Datapixx('RegWrRd');    % Synchronize DATAPixx registers to local register cache

end


%% Get  TTL number of bits it should be 24 bits

% Show how many TTL output bits are in the Datapixx
HitKeyToContinue('Press any key to see the Datapixx TTL output number of bits');
nBits = Datapixx('GetDoutNumBits');
fprintf('\nDATAPixx has %d TTL output bits\n\n', nBits);

Datapixx('SetDoutValues', 0);
Datapixx('RegWrRd');


%% All Triggers test

% Bring 1 output high
HitKeyToContinue('Hit any key to bring all digital output to 1:');

Datapixx('SetDoutValues', (2^nBits) - 1);
Datapixx('RegWrRd');


% Bring 1 output high
HitKeyToContinue('Hit any key to bring all digital output to 0:');

Datapixx('SetDoutValues', 0);
Datapixx('RegWrRd');



% In MRI we have a 25-pin D-Sub cable so we care about this column
% Trigger S2 marker by activating the 3rd pin of the 25-pin D-sub cable
% The 3rd pin corresponds to digital output 4 on the vpixx system
% 4 in binary is 0100
    % In MRI we have a 25-pin D-Sub cable so we care about this column
    % Trigger S2 marker by activating the 3rd pin of the 25-pin D-sub cable
    % The 3rd pin corresponds to digital output 4 on the vpixx system
    % 4 in binary is 0100
    


    % Binary numbers with a single 1 over 8 bits and their decimal equivalents:
% 00000001 -> 1
% 00000010 -> 2
% 00000100 -> 4
% 00001000 -> 8
% 00010000 -> 16
% 00100000 -> 32
% 01000000 -> 64
% 10000000 -> 128



% EEG Marker trigger script


% DOUTValues = 0
% DOUTValues = 1
% DOUTValues = 2 --> nothing active
% DOUTValues = 4 --> bit number 0 is activated
% DOUTValues = 5 --> bit number 0 is activated coz 5 = 101
% DOUTValues = 8 --> nothing active
% DOUTVALUES = 16 --> bit 1 is activated


% Bits on Vpixx
% Bit 0 on BP needs bit 2 on Vpixx
% Bit 1 on BP needs bit 4 on Vpixx
% Bit 2 on BP needs bit 6 on Vpixx
% Bit 3 on BP needs bit 8 on Vpixx
% Bit 4 on BP needs bit 10 on Vpixx
% Bit 5 on BP needs bit 12 on Vpixx
% Bit 6 on BP needs bit 14 on Vpixx
% Bit 7 on BP needs bit 16 on Vpixx



%% Marker test


% Set total duration (in seconds) to run the loop
totalDuration = 10; % e.g., 30 seconds

% Set pause duration (in seconds) between each instruction
pauseDuration = 2; % e.g., 2 seconds

%% S1 Marker Works

% Should trigger S1 marker on EEG
%HitKeyToContinue('\nHit any key to bring the EEG S2 marker on:');



tic;
Datapixx('SetDoutValues', 0);
Datapixx('RegWrRd');

while toc < totalDuration

    Datapixx('SetDoutValues', trig_dict('S1'));
    Datapixx('RegWrRd');
    disp('S1 Marker On');
    pause(pauseDuration);

    Datapixx('SetDoutValues', 0);
    Datapixx('RegWrRd');
    disp('triggers off');

    pause(pauseDuration);

end




%% S2 Marker Works



tic;
Datapixx('SetDoutValues', 0);
Datapixx('RegWrRd');

while toc < totalDuration

    Datapixx('SetDoutValues', trig_dict('S2'));
    Datapixx('RegWrRd');
    disp('S2 Marker On');
    pause(pauseDuration);

    Datapixx('SetDoutValues', 0);
    Datapixx('RegWrRd');
    disp('triggers off');

    pause(pauseDuration);

end




%% S3 Marker Works



tic;
Datapixx('SetDoutValues', 0);
Datapixx('RegWrRd');

while toc < totalDuration

    Datapixx('SetDoutValues', trig_dict('S3'));
    Datapixx('RegWrRd');
    disp('S3 Marker On');
    pause(pauseDuration);

    Datapixx('SetDoutValues', 0);
    Datapixx('RegWrRd');
    disp('triggers off');

    pause(pauseDuration);

end




%% S4 Marker Works



tic;
Datapixx('SetDoutValues', 0);
Datapixx('RegWrRd');

while toc < totalDuration

    Datapixx('SetDoutValues', trig_dict('S4'));
    Datapixx('RegWrRd');
    disp('S4 Marker On');
    pause(pauseDuration);

    Datapixx('SetDoutValues', 0);
    Datapixx('RegWrRd');
    disp('triggers off');

    pause(pauseDuration);

end


%% S5 Marker Works



tic;
Datapixx('SetDoutValues', 0);
Datapixx('RegWrRd');

while toc < totalDuration

    Datapixx('SetDoutValues', trig_dict('S5'));
    Datapixx('RegWrRd');
    disp('S5 Marker On');
    pause(pauseDuration);

    Datapixx('SetDoutValues', 0);
    Datapixx('RegWrRd');
    disp('triggers off');

    pause(pauseDuration);

end





%% S8 Marker Works



tic;
Datapixx('SetDoutValues', 0);
Datapixx('RegWrRd');

while toc < totalDuration

    Datapixx('SetDoutValues', trig_dict('S8'));
    Datapixx('RegWrRd');
    disp('S8 Marker On');
    pause(pauseDuration);

    Datapixx('SetDoutValues', 0);
    Datapixx('RegWrRd');
    disp('triggers off');

    pause(pauseDuration);

end






%% S16 Marker Works



tic;
Datapixx('SetDoutValues', 0);
Datapixx('RegWrRd');

while toc < totalDuration

    Datapixx('SetDoutValues', trig_dict('S16'));
    Datapixx('RegWrRd');
    disp('S16 Marker On');
    pause(pauseDuration);

    Datapixx('SetDoutValues', 0);
    Datapixx('RegWrRd');
    disp('triggers off');

    pause(pauseDuration);

end



%% S32 Marker Works



tic;
Datapixx('SetDoutValues', 0);
Datapixx('RegWrRd');

while toc < totalDuration

    Datapixx('SetDoutValues', trig_dict('S32'));
    Datapixx('RegWrRd');
    disp('S32 Marker On');
    pause(pauseDuration);

    Datapixx('SetDoutValues', 0);
    Datapixx('RegWrRd');
    disp('triggers off');

    pause(pauseDuration);

end



%% S64 Marker Works



tic;
Datapixx('SetDoutValues', 0);
Datapixx('RegWrRd');

while toc < totalDuration

    Datapixx('SetDoutValues', trig_dict('S64'));
    Datapixx('RegWrRd');
    disp('S64 Marker On');
    pause(pauseDuration);

    Datapixx('SetDoutValues', 0);
    Datapixx('RegWrRd');
    disp('triggers off');

    pause(pauseDuration);

end



%% S128 Marker Works




tic;
Datapixx('SetDoutValues', 0);
Datapixx('RegWrRd');

while toc < totalDuration

    Datapixx('SetDoutValues', trig_dict('S128'));
    Datapixx('RegWrRd');
    disp('S128 Marker On');
    pause(pauseDuration);

    Datapixx('SetDoutValues', 0);
    Datapixx('RegWrRd');
    disp('triggers off');

    pause(pauseDuration);

end




%% S255 Marker Working



tic;
Datapixx('SetDoutValues', 0);
Datapixx('RegWrRd');

while toc < totalDuration

    Datapixx('SetDoutValues', trig_dict('S255'));
    Datapixx('RegWrRd');
    disp('S255 Marker On');
    pause(pauseDuration);

    Datapixx('SetDoutValues', 0);
    Datapixx('RegWrRd');
    disp('triggers off');

    pause(pauseDuration);

end





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

function NYUAD_MRI_trigger_Datapixx()

% Step 1 intialize the System (Open, set up screen)
Datapixx('Open');
Datapixx('StopAllSchedules');
Datapixx('RegWrRd');

% USEFUL INFORMATION: Default state of Digital Input
% defaultValues = Datapixx('GetDinValues');

% Variables to be used (digital out values, express in binary for understanding)
mri_trigger_value = bin2dec('0000 0100 0000 0000'); % Din10

%% Step 1
% Setting up digital input log (logs all changes in Din with exact timing)
Datapixx('SetDinLog');

% Send the changes to the device, right now.
Datapixx('RegWrRd');

mri_triggered=0;
while ~KbCheck % Added KbCheck here in order to be able to exit the script in case no MRI trigger ever.
    Datapixx('RegWrRd'); % Update the local information
    status = Datapixx('GetDinStatus'); % Get the status of the digital Inputs
    if (status.newLogFrames > 0)
        [data tt] = Datapixx('ReadDinLog');
        for i = 1:status.newLogFrames
            fprintf('Digital out changed: %s\n', dec2bin(data(i)));
            if (bitand(data(i), mri_trigger_value))
                fprintf('MRI Trigger\n timetag: %f\n', tt(i));
                mri_triggered = 1;
                break;
            else
                fprintf('Trigger but not MRI\n');
            end
        end
    end
    if (mri_triggered)
        break;
    end
end

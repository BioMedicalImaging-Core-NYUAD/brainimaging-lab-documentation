isReady =  Datapixx('Open');
Datapixx('StopAllSchedules');
Datapixx('RegWrRd');    % Synchronize DATAPixx registers to local register cache
disp('Connection to datapixx Open')


while true 
    fprintf('Initial digital input states = ');
    Datapixx('RegWrRd');
    initialValues = Datapixx('GetDinValues');
    
    for bit = nBits-1:-1:0 % Easier to understand if we show in binary
        if (bitand(initialValues, 2^bit) > 0)
            fprintf('1');
        else
            fprintf('0');
        end
    end
    
    fprintf('\n');
end



%% 

mri_triggered=0;

% Setting up digital input log (logs all changes in Din with exact timing)
Datapixx('SetDinLog');

% Send the changes to the device, right now.
Datapixx('RegWrRd');
nBits = Datapixx('GetDinNumBits');
mri_trigger_value = bin2dec('0000 0100 0000 0000');

while true
    Datapixx('RegWrRd'); % Update the local information
    status = Datapixx('GetDinStatus'); % Get the status of the digital Input
    if (status.newLogFrames > 0)
        disp(['new log frames' status]);
        [data tt] = Datapixx('ReadDinLog');
        for i = 1:status.newLogFrames
            disp(['data', data(i)]);
            fprintf('Digital out changed: %s\n', dec2bin(data(i)));
            if (bitand(data(i), mri_trigger_value))
                fprintf('MRI Trigger\n timetag: %f\n', tt(i));
                mri_triggered = 1;
                disp('MRI triggered');
                break;
            else
                fprintf('Trigger but not MRI\n');
            end
        end
    end
    if (mri_triggered)
        disp('MRI triggered');
        break;
    end
end

Datapixx('RegWrRd');
Datapixx('StopAllSchedules');
Datapixx('Close');
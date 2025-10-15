


Datapixx('Open');

Datapixx('DisablePixelMode');
Datapixx('RegWr');

Datapixx('SetPropixxDlpSequenceProgram', 0);
Datapixx('RegWr');


while true

    [response, time] = getButton();
    
    disp(['Response number', int2str(response),'at time', time])
    WaitSecs(1);
end

%datapixx shutdown

Datapixx('RegWrRd');
Datapixx('StopAllSchedules');
Datapixx('Close');

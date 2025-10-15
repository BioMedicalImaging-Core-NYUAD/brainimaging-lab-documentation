% Get any button press from Vpixx responsepixx

function [resp, time] = getButton()

while true
    Datapixx('RegWrRd');
    kbcheck = dec2bin(Datapixx('GetDinValues'));
    if kbcheck(end) == '1' || kbcheck(end-1) == '1' || kbcheck(end-2) == '1' || kbcheck(end-3) == '1' || kbcheck(end-5) == '1' || kbcheck(end-6)  == '1' || kbcheck(end-7) == '1' || kbcheck(end-8)  == '1'
        for i_but = 1:9
            buttonBox(i_but) = str2num(kbcheck(end-9+i_but));
        end
        
        resp = find(buttonBox);
        time = GetSecs;
        if length(resp) == 1
            break;
        end
    end
end



function var = checkCorrectInput(mainText, altText, correctValues)
    while true
        var = input(sprintf(mainText),'s');
        var  = str2num(var);
        if isempty(var)
            disp('A numeric value is expected.');
        else
            if nargin < 3
                break;
            else
                if isempty(find(correctValues==var))
                    disp(altText);
                else
                    break;
                end
            end
        end
    end
end



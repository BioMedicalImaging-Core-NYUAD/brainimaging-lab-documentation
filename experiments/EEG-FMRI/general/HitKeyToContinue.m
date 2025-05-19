function HitKeyToContinue(message)
    if nargin < 1
        message = 'Press any key to continue...';
    end
    disp(message);
    pause;  % Wait for user input
end



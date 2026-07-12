function runDisplay(scr,const,my_key,textExp)
% ----------------------------------------------------------------------
% runTrials(scr,const,expDes,my_key,textExp,button)
% ----------------------------------------------------------------------
% Goal of the function :
% Main trial function, display the trial function and save the experi-
% -mental data in different files.
% ----------------------------------------------------------------------
% Input(s) :
% scr : window pointer
% const : struct containing all the constant configurations.
% my_key : keyboard keys names
% textExp : struct contanining all instruction text.
% ----------------------------------------------------------------------
% Output(s):
% none
% ----------------------------------------------------------------------

%% General instructions:

% eyetracking
if const.EL_mode
    if 1==1 %(const.run==1) % just for the first run
        % expects T input to start (change this later)
        [~, exitFlag] = initEyelinkStates('calibrate', const.window, const.EL);
        if exitFlag, vpixxShutdown(const); return, end
    end
    err = Eyelink('CheckRecording');
    if err ~= 0
        initEyelinkStates('startrecording', const.window, const.EL);
        disp('Eyelink now recording .. ')
    end
end

HideCursor(scr.scr_num);

% first wait for operator (manual input so calibration can occur early
[~] = instructions(scr,const,my_key,textExp.msg4operator,1);

% now wait for trigger
keyCode = instructions(scr,const,my_key,textExp.instruction,0);

if keyCode(my_key.escape), vpixxShutdown(const); return, end

FlushEvents('KeyDown');

%% Main Loop
frameCounter=1;
const.expStop = 0;
blinkCounter = 0; % initiate at 0
blinkFrameThresh = (1/scr.ifi)*const.blinkSecThresh; % frame rate * 5 seconds

tic
vbl = Screen('Flip',const.window);

while ~const.expStop
    
    try
        waitframes = 1;
        %vbl = Screen('Flip',const.window);
        vblendtime = vbl + const.totalduration; % 352 sec
    
        if const.EL_mode, Eyelink('message', 'DISPLAY START'); end

        while vbl <= vblendtime  
    
            % draw stimuli here, better at the start of the drawing loop
            Screen('DrawDots', const.window, scr.windCenter_px, ...
                const.fixationRadius_px, const.white, [], 2);

            Screen('DrawingFinished',const.window); % small ptb optimisation
            vbl = Screen('Flip',const.window, vbl + (waitframes - 0.5) * scr.ifi);
    
            %[~, exitFlag] = initEyelinkStates('fixcheck', const.window, const.EL);
            evt = Eyelink('newestfloatsample');
            xPos = evt.gx;
            yPos = evt.gy;


            % if tracked eye returns same standard value as non tracked eye
            % for both x and y:
            if isequal(xPos(1), xPos(2), yPos(1), yPos(2))
                blinkCounter=blinkCounter+1; % blink

                if blinkCounter>=blinkFrameThresh
                    % play alarm
                    Beeper(400, 0.8, 1);
                end

            else
                blinkCounter=0; % reset when eye is open
            end
            
            frameCounter=frameCounter+1;
        end
        
        % exit loop
        if const.EL_mode, Eyelink('message', 'DISPLAY END'); end
        const.expStop = 1;
    
    catch
        vpixxShutdown(const); 
    end
    
end
toc

vpixxShutdown(const);

% save eyetracking file
if const.EL_mode
    disp("Please wait, saving EYELINK file..")
    if ~exist(const.eyeDataDir, 'dir'), mkdir(const.eyeDataDir); end
    initEyelinkStates('eyestop', scr.scr_num, {const.eyeFileName, const.eyeDataDir})  
end


end
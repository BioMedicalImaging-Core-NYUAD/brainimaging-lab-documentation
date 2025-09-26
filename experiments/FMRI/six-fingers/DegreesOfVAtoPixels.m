function [viewDist, screenNumber, screenXpixels, screenYpixels, screenWidth, screenHeight, pixWidth, pixHeight, Hperdegree, Wperdegree] = DegreesOfVAtoPixels() 
    global parameters;
    %STANDARD SCREEN SIZES
    %Mac 27" ThunderBolt Display = [33.5, 59.6]
    %Eyetracking Display = [28.7, 51.2]
    
    format short
    viewDist = parameters.viewDistance;
    mainText = sprintf('Is the Viewing Distance -- %0.1fcm (Yes = 1, No = 0)  ',viewDist); 
    viewDist = checkCorrectInput(mainText, 'Please enter either  0 or  1: ', [0,1]);
    
    if viewDist == 0;
        viewDist = input('Please enter the Vieweing Distance in CM:  ','s'); 
        viewDist  = str2num(viewDist);
        while isempty(viewDist)
            disp('A numeric value is expected.');
            viewDist = input('Please enter the Vieweing Distance in CM:  ','s'); 
            viewDist  = str2num(viewDist);
        end
    elseif viewDist ==1;
        viewDist = 60;
    end

    screenNumber = max(Screen('Screens')); %get the screen 

    [screenXpixels, screenYpixels] = Screen('WindowSize', screenNumber); %get x and y pixels of screen
    [screenWidth, screenHeight] = Screen('DisplaySize',screenNumber); %get screen width and height in mm

    screenWidth = screenWidth/10; %mm to cm
    screenHeight = screenHeight/10; %mm to cm

    
    Hperdegree = viewDist * tan(deg2rad(1)); %height for one degree in cm
    Wperdegree = Hperdegree; %width for one degree in cm

    pixWidth = screenWidth/screenXpixels; %cm/pixel
    pixHeight = screenHeight/screenYpixels; %cm/pixel
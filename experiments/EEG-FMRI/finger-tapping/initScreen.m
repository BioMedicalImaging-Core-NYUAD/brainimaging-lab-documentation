function initScreen()
    global screen;
    global parameters;
    %   To make it transparent for working in demo mode
%     if parameters.isDemoMode
%         PsychDebugWindowConfiguration(0, parameters.transparency);
%     end
    % degree of VA to pixel calculation
   
    [screen.viewDist, screen.screenNumber, screen.screenXpixels, screen.screenYpixels, screen.screenWidth, screen.screenHeight, screen.pixWidth, screen.pixHeight, screen.Hperdegree, screen.Wperdegree] = DegreesOfVAtoPixels(); 

    screen.deg_width = atand(screen.screenWidth/2 / screen.viewDist) * 2;
    screen.deg_height = atand(screen.screenHeight/2 / screen.viewDist) * 2;

    % screen init for PC and MAC
    screen.white = WhiteIndex(screen.screenNumber);
    screen.black = BlackIndex(screen.screenNumber);
    screen.grey = screen.white*0.5;
    AssertOpenGL;
    % Set blend function for alpha blending

    [screen.win, screen.screenRect] = PsychImaging('OpenWindow', screen.screenNumber,screen.grey, [], 32, 2, [], [], kPsychNeed32BPCFloat);
    screen.ifi = Screen('GetFlipInterval', screen.win);

    % Retreive the maximum priority number
    topPriorityLevel = MaxPriority(screen.win);
    Screen('BlendFunction', screen.win, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
    screen.pixels_per_deg_width = screen.screenXpixels/screen.deg_width; 
    screen.pixels_per_deg_height = screen.screenYpixels/screen.deg_height;

end
%fingertapping- this one for haidee only stop and tap 

clear all; close all;

global parameters screen tc isTerminationKeyPressed resReport totalTime datapixx;

Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'Verbosity', 0);
addpath('supportFiles');   

% Load parameters
loadParameters();

% Initialize subject info
initSubjectInfo();

% Hide cursor if required
if parameters.hideCursor
    HideCursor();
end

% Initialize screen
initScreen(); % ensure screen.win is set here
% Load clenched fist image
blockTwoImage = imread('clenched_fist.jpg');

% Convert to grayscale if needed
if size(blockTwoImage, 3) == 3
    blockTwoImage = rgb2gray(blockTwoImage);
end

% Estimate background grey from image
backgroundGrey = median(blockTwoImage(:));

% Get screen resolution
screenRes = Screen('WindowSize', screen.win); % [width, height]

% Create texture for the full-screen image
parameters.blockTwoTexture = Screen('MakeTexture', screen.win, blockTwoImage);

% % Load and prepare sca
% image
% blockTwoImage = imread('clenched_fist.jpg');
% if size(blockTwoImage, 3) == 3
%     blockTwoImage = rgb2gray(blockTwoImage);
% end
% parameters.blockTwoTexture = Screen('MakeTexture', screen.win, blockTwoImage);

% Convert visual degrees to pixels
visDegrees2Pix();

% Initialize Datapixx if not demo
if ~parameters.isDemoMode
    datapixx = 0;               
    AssertOpenGL;
    isReady = Datapixx('Open');
    Datapixx('StopAllSchedules');
    Datapixx('RegWrRd');
end

ListenChar(2); % Suspend keyboard output

% Scanner initialization
if parameters.isDemoMode
    showTTLWindow_1();
else
    showTTLWindow_2();
end

% Main experimental loop
for tc = 1 : parameters.numberOfBlocks
    if mod(tc, 2) ~= 0
        DrawFormattedText(screen.win, parameters.blockOneMsg, 'center', 'center', [255 255 255]);
    else
        Screen('DrawTexture', screen.win, parameters.blockTwoTexture);
    end
    
    % Flip and record timing
    blockStartTime = Screen('Flip', screen.win);
    WaitSecs(parameters.blockDuration);
    blockEndTime = GetSecs();
    
    % Record timings
    timingsReport(tc).trial = tc;
    timingsReport(tc).startTime = blockStartTime;
    timingsReport(tc).endTime = blockEndTime;
    timingsReport(tc).totalBlockDuration = blockEndTime - blockStartTime;
end

% End-of-experiment procedures
startEoeTime = showEoeWindow();

% Save timings
writetable(struct2table(timingsReport), parameters.datafile);

ListenChar(1); % Allow keyboard output again
ShowCursor('Arrow');
sca;

% Close Datapixx if used
if ~parameters.isDemoMode
    Datapixx('RegWrRd');
    Datapixx('StopAllSchedules');
    Datapixx('Close');
end
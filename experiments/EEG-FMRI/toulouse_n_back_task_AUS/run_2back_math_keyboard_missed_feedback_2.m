function run_2back_math_keyboard_missed_feedback_2(Sujet)
% 2-back math task using additions (0–10), feedback, and keyboard input.
% Shows "Correct", "Incorrect", or "Missed".
% Saves results to 'C:\Users\roroy\Documents\MATLAB\nback_results'.

Screen('Preference','SkipSyncTests', 1);
PsychDefaultSetup(2);
screens = Screen('Screens');
screenNumber = max(screens);
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);
grey = white / 2;

[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);
Screen('TextSize', window, 60);
ifi = Screen('GetFlipInterval', window);
HideCursor;

stimDuration = 2.5;
isi = 0.5;
feedbackDuration = 0.5;
numTrials = 108;
numMatches = round(0.4 * (numTrials - 2));  % ensure ~50% matches (exclude first 2)

% Generate random problems
A = randi([0 10], numTrials, 1);
B = randi([0 10], numTrials, 1);
answers = A + B;

% Enforce 2-back matches
match_trials = randperm(numTrials - 2, numMatches) + 2;  % avoid trials 1 and 2
for idx = 1:length(match_trials)
    t = match_trials(idx);
    answers(t) = answers(t - 2);
    val = answers(t);
    a = randi([0 min(val, 10)]);
    b = val - a;
    if b >= 0 && b <= 10
        A(t) = a;
        B(t) = b;
    else
        A(t) = val; B(t) = 0;
    end
end

% Setup variables
responses = zeros(numTrials, 1);
RTs = NaN(numTrials, 1);
matches = zeros(numTrials, 1);
matches(match_trials) = 1;
corrects = zeros(numTrials, 1);
missed = zeros(numTrials, 1);

KbName('UnifyKeyNames');
keyYes = KbName('RightArrow');
keyQuit = KbName('ESCAPE');

DrawFormattedText(window, ...
    '2-BACK MATH TASK\n\nSolve each addition.\n\nPress RIGHT ARROW if the result equals the result from 2 trials ago.\n\nPress any key to begin.', ...
    'center', 'center', white);
Screen('Flip', window);
KbStrokeWait;

% Trial loop
for trial = 1:numTrials
    if mod(trial-1, 12) == 0 && trial > 1
    % Show 00+00 for 24 seconds
     Screen('TextSize', window, 100);
     DrawFormattedText(window, '00 + 00', 'center', 'center', white);
     Screen('Flip', window);
     WaitSecs(24);
    end
    
    expr = sprintf('%d + %d', A(trial), B(trial));
    Screen('TextSize', window, 100);  % Increase font size
    DrawFormattedText(window, expr, 'center', 'center', white);
    Screen('Flip', window);
    tStart = GetSecs;
    responded = false;

    while GetSecs - tStart < stimDuration
        [keyIsDown, tNow, keyCode] = KbCheck;
        if keyIsDown && ~responded
            if keyCode(keyQuit)
                sca;
                return;
            elseif keyCode(keyYes)
                responses(trial) = 1;
                RTs(trial) = tNow - tStart;
                responded = true;
            end
        end
        % === DRAW STIMULUS ===
    Screen('TextSize', window, 100);  % math expression
    DrawFormattedText(window, expr, 'center', 'center', white);

    % === DRAW PROGRESS BAR ===
    elapsed = GetSecs - tStart;
    progress = max(0, 1 - (elapsed / stimDuration));  % goes from 1 → 0

    % Bar dimensions
    barHeight = 20;
    margin = 50;
    fullWidth = windowRect(3) - 2 * margin;
    barWidth = fullWidth * progress;

    % Rectangle coordinates [x1 y1 x2 y2]
    barRect = [margin, 2 * barHeight, margin + barWidth, 3 * barHeight];
    Screen('FillRect', window, white, barRect);

    % Flip screen
    Screen('Flip', window);
    end

    isMatch = matches(trial);

        % Feedback logic
    if responded
        isCorrect = isMatch == 1;
        corrects(trial) = isCorrect;

        if isCorrect
            feedback = 'Correct!';
            feedbackColor = [0 180 0];  % Green
        else
            feedback = 'Incorrect!';
            feedbackColor = [255 0 0];  % Red
        end
        Screen('TextStyle', window, 1); % Bold
        DrawFormattedText(window, feedback, 'center', 'center', feedbackColor);
        Screen('Flip', window);
        WaitSecs(feedbackDuration);
    elseif isMatch && ~responded
        missed(trial) = 1;
        Screen('TextStyle', window, 1); % Bold
        DrawFormattedText(window, 'Missed!', 'center', 'center', [255 140 0]);  % Orange
        Screen('Flip', window);
        WaitSecs(feedbackDuration);
    end

    Screen('Flip', window);
    WaitSecs(isi);
end

% Accuracy calculation
num_matches = sum(matches);
num_correct_presses = sum(corrects & responses);
if num_matches > 0
    accuracy = (num_correct_presses / num_matches) * 100;
else
    accuracy = NaN;
end

DrawFormattedText(window, ...
    sprintf('Task Complete!\n\nMatch Accuracy: %.1f%%\n\nPress any key to exit.', accuracy), ...
    'center', 'center', black);
Screen('Flip', window);
KbStrokeWait;
sca;

% Save results
results = table((1:numTrials)', A, B, answers, matches, responses, corrects, missed, RTs, ...
    'VariableNames', {'Trial', 'A', 'B', 'Answer', 'IsMatch', 'Response', 'Correct', 'Missed', 'RT'});

saveDir = 'C:\\Users\\roroy\\Documents\\MATLAB\\nback_results';
if ~exist(saveDir, 'dir')
    mkdir(saveDir);
end
filename = sprintf('Sujet%d_2back_math_missed_feedback.mat', Sujet);
fullpath = fullfile(saveDir, filename);
save(fullpath, 'results');
end

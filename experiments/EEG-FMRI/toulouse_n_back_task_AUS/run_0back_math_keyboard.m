% Modified version of the 2-back math task to implement 0-back logic
% Instead of matching to 2-back, participant presses RIGHT ARROW if current
% addition result matches a fixed target shown at the beginning of each block.

function run_0back_math_keyboard(Sujet)

Screen('Preference','SkipSyncTests', 1);
PsychDefaultSetup(2);
screens = Screen('Screens');
screenNumber = max(screens);
white = WhiteIndex(screenNumber);
black = BlackIndex(screenNumber);

[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);
Screen('TextSize', window, 60);
HideCursor;

stimDuration = 2.5;
isi = 0.5;
feedbackDuration = 0.5;
numTrials = 108;
blockLength = 12;
matchRatio = 0.4;

% Generate random problems
A = randi([0 10], numTrials, 1);
B = randi([0 10], numTrials, 1);
answers = A + B;

% Setup response tracking
responses = zeros(numTrials, 1);
RTs = NaN(numTrials, 1);
matches = zeros(numTrials, 1);
corrects = zeros(numTrials, 1);
missed = zeros(numTrials, 1);

KbName('UnifyKeyNames');
keyYes = KbName('RightArrow');
keyQuit = KbName('ESCAPE');

DrawFormattedText(window, ...
    '0-BACK MATH TASK\n\nSolve each addition.\n\nPress RIGHT ARROW if the result equals the TARGET.\n\nPress any key to begin.', ...
    'center', 'center', white);
Screen('Flip', window);
KbStrokeWait;

% === Trial loop ===
for trial = 1:numTrials
    % Start new block every 12 trials
    if mod(trial-1, blockLength) == 0
        if trial > 1
            Screen('TextSize', window, 100);
            DrawFormattedText(window, '00 + 00', 'center', 'center', white);
            Screen('Flip', window);
            WaitSecs(24);
        end

        % New target
        targetAnswer = randi([0 20]);

        % Show new target
        Screen('TextSize', window, 60);
        DrawFormattedText(window, sprintf('New Target = %d', targetAnswer), 'center', 'center', white);
        Screen('Flip', window);
        WaitSecs(2);
    end

    % Determine if trial should be a match
    if rand < matchRatio
        answers(trial) = targetAnswer;
        val = targetAnswer;
        a = randi([0 min(val, 10)]);
        b = val - a;
        if b >= 0 && b <= 10
            A(trial) = a;
            B(trial) = b;
        else
            A(trial) = val; B(trial) = 0;
        end
    end

    matches(trial) = answers(trial) == targetAnswer;
    expr = sprintf('%d + %d', A(trial), B(trial));
    tStart = GetSecs;
    responded = false;

    while GetSecs - tStart < stimDuration
        [keyIsDown, tNow, keyCode] = KbCheck;
        if keyIsDown && ~responded
            if keyCode(keyQuit)
                sca; return;
            elseif keyCode(keyYes)
                responses(trial) = 1;
                RTs(trial) = tNow - tStart;
                responded = true;
            end
        end

        % Draw problem and progress bar
        Screen('TextSize', window, 100);
        DrawFormattedText(window, expr, 'center', 'center', white);

        elapsed = GetSecs - tStart;
        progress = max(0, 1 - (elapsed / stimDuration));
        barHeight = 20;
        margin = 50;
        fullWidth = windowRect(3) - 2 * margin;
        barWidth = fullWidth * progress;
        barRect = [margin, 2 * barHeight, margin + barWidth, 3 * barHeight];
        Screen('FillRect', window, white, barRect);
        Screen('Flip', window);
    end

    % Evaluate feedback
    isMatch = matches(trial);
    if responded
        isCorrect = isMatch == 1;
        corrects(trial) = isCorrect;
        if isCorrect
            feedback = 'Correct!';
            feedbackColor = [0 180 0];
        else
            feedback = 'Incorrect!';
            feedbackColor = [255 0 0];
        end
        Screen('TextStyle', window, 1);
        DrawFormattedText(window, feedback, 'center', 'center', feedbackColor);
        Screen('Flip', window);
        WaitSecs(feedbackDuration);
    elseif isMatch && ~responded
        missed(trial) = 1;
        Screen('TextStyle', window, 1);
        DrawFormattedText(window, 'Missed!', 'center', 'center', [255 140 0]);
        Screen('Flip', window);
        WaitSecs(feedbackDuration);
    end

    Screen('Flip', window);
    WaitSecs(isi);
end

% === Accuracy calculation ===
num_matches = sum(matches);
num_correct = sum(corrects & responses);
accuracy = (num_matches > 0) * (num_correct / num_matches) * 100;

DrawFormattedText(window, sprintf('Task Complete!\n\nMatch Accuracy: %.1f%%\n\nPress any key to exit.', accuracy), 'center', 'center', white);
Screen('Flip', window);
KbStrokeWait;
sca;

% Save results
results = table((1:numTrials)', A, B, answers, matches, responses, corrects, missed, RTs, ...
    'VariableNames', {'Trial', 'A', 'B', 'Answer', 'IsMatch', 'Response', 'Correct', 'Missed', 'RT'});
saveDir = 'C:\\Users\\roroy\\Documents\\MATLAB\\nback_results';
if ~exist(saveDir, 'dir'); mkdir(saveDir); end
filename = sprintf('Sujet%d_0back_math.mat', Sujet);
save(fullfile(saveDir, filename), 'results');
end

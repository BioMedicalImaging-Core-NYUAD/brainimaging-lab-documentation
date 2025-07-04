function StroopTask(trialDuration, trialBlockDuration, restDuration, numBlocks)
    %This function runs the SCWT task with visual and audio feedback. 
    %Each trial has its own countdown timer.
    %The experiment is organized into blocks of SCWT trials, each followed by a rest period.

    % trialDuration: seconds per trial
    % trialBlockDuration: seconds per block of trials 
    % restDuration: seconds rest between blocks 
    % numBlocks: number of blocks 

    %setting default values if inputs not provided.

    if nargin < 1 || isempty(trialDuration)
        trialDuration = 3;
    end
    if nargin < 2 || isempty(trialBlockDuration)
        trialBlockDuration = 40;
    end
    if nargin < 3 || isempty(restDuration)
        restDuration = 20;
    end
    if nargin < 4 || isempty(numBlocks)
        numBlocks = 10;
    end

    % Generating the trials
    trials = GenerateSCWTTrials();  
    numTrialsTotal = length(trials);

    % Setting up the Psychtoolbox screen
    Screen('Preference', 'SkipSyncTests', 1);
    AssertOpenGL;
    KbName('UnifyKeyNames');
    [win, winRect] = PsychImaging('OpenWindow', max(Screen('Screens')), [255 255 255]);
    [xCenter, yCenter] = RectCenter(winRect);
    HideCursor;

    % Prepare buttons layout
    buttonW = 150; buttonH = 100;
    gapX = 30; gapY = 30;
    buttonRects = zeros(4, 10);

    %calculating start positions to center buttons
    startX = xCenter - (5 * buttonW + 4 * gapX) / 2;
    startY = yCenter + 100;
    %defining the button positions in 2 rows and 5 columns (2x5 grid)
    for i = 1:10
        col = mod(i-1, 5);
        row = floor((i-1) / 5);
        left = startX + col * (buttonW + gapX);
        top = startY + row * (buttonH + gapY);
        buttonRects(:, i) = [left; top; left + buttonW; top + buttonH];
    end

    % Colors names and their RGB values
    colorNames = {'red', 'blue', 'green', 'yellow', 'purple', 'cyan', ...
                  'orange', 'magenta', 'pink', 'brown'};
    colorRGBs = {
        [255, 0, 0], [0, 0, 255], [0, 128, 0], [255, 255, 0], [128, 0, 128], ...
        [0, 255, 255], [255, 165, 0], [255, 0, 255], [255, 192, 203], [165, 42, 42]
    };
    validKeys = {'1','2','3','4','5','6','7','8','9','0'};

    % Loading the audio feedback sounds
    InitializePsychSound(1);
    [corrSnd, freq1] = audioread('correct2.mp3');
    [wrongSnd, freq2] = audioread('wrong2.mp3');
    if freq1 ~= freq2
        error('Both sound files must have the same sampling rate.');
    end

    %open the audio device
    pahandle = PsychPortAudio('Open', [], [], 0, freq1, size(corrSnd, 2));
    PsychPortAudio('Volume', pahandle, 1);

    % Calculate trials per block based on trial duration and block duration
    trialsPerBlock = floor(trialBlockDuration / trialDuration);

    % to iterate over the trials
    trialIdx = 1;

    % --------------------- Main Loop ---------------------- %

    for block = 1:numBlocks
%         blockStartTime = GetSecs;

        for t = 1:trialsPerBlock  %run trials until one block ends before the rest period
            trial = trials(trialIdx);

            % Shuffling labels/text and colors of the buttons (mitigating
            % adaptability)
            idx = randperm(10);
            shuffledNames = colorNames(idx);
            shuffledFillRGBs = cell(1,10);
            for i = 1:10
                labelIdx = find(strcmp(colorNames, shuffledNames{i}));
                otherIdx = setdiff(1:10, labelIdx);
                chosenIdx = otherIdx(randi(length(otherIdx)));
                shuffledFillRGBs{i} = colorRGBs{chosenIdx};
            end

            startTime = GetSecs;
            keyPressed = '';
            rt = NaN;

            % time-limited trials - showing trial until a key is pressed or
            % trial duration ends
            while isempty(keyPressed) && (GetSecs - startTime < trialDuration)
                elapsed = GetSecs - startTime;
                remaining = max(0, trialDuration - elapsed);

                % show stimulus on screen
                Screen('FillRect', win, [255 255 255]);
                Screen('TextSize', win, 75);
                DrawFormattedText(win, upper(trial.word), 'center', yCenter - 250, trial.fontRGB);

                % countdown timer below stimulus word
                Screen('TextSize', win, 40);
                timerText = sprintf('Time left: %.1f s', remaining);
                DrawFormattedText(win, timerText, 'center', yCenter - 180, [0 0 0]);

                % drawing the 10 response buttons with labels and key
                % numbers
                for i = 1:10
                    rect = buttonRects(:, i);
                    fillColor = shuffledFillRGBs{i};
                    Screen('FillRect', win, fillColor, rect);
                    lum = 0.299*fillColor(1) + 0.587*fillColor(2) + 0.114*fillColor(3);
                    textColor = [0 0 0]; if lum <= 128, textColor = [255 255 255]; end
                    Screen('TextSize', win, 22);
                    labelText = upper(shuffledNames{i});
                    bounds = Screen('TextBounds', win, labelText);
                    textX = rect(1) + (rect(3)-rect(1))/2 - (bounds(3)-bounds(1))/2;
                    textY = rect(2) + (rect(4)-rect(2))/2 - (bounds(4)-bounds(2))/2;
                    Screen('DrawText', win, labelText, textX, textY, textColor);
                    Screen('DrawText', win, validKeys{i}, rect(1)+10, rect(2)+10, textColor);
                end

                %update screen

                Screen('Flip', win);

                % Check the keyboard for response
                [keyIsDown, secs, keyCode] = KbCheck;
                if keyIsDown
                    keys = KbName(keyCode);
                    if iscell(keys), keys = keys{1}; end
                    if any(strcmp(keys, validKeys))
                        keyPressed = keys;
                        rt = secs - startTime;
                    elseif strcmp(keys, 'ESCAPE')
                        ShowCursor; sca; PsychPortAudio('Close', pahandle); return
                    end
                    KbReleaseWait;
                end
            end

            % Timeout handling if no response within the trial duration
            if isempty(keyPressed)
                trials(trialIdx).response = 'NoResponse';
                trials(trialIdx).rt = NaN;
                trials(trialIdx).correct = false;
                Screen('TextSize', win, 100);
                DrawFormattedText(win, 'Time Out!', 'center', 'center', [255 165 0]);
                Screen('Flip', win);

                % playing the feedback sound on timeout
                PsychPortAudio('FillBuffer', pahandle, wrongSnd');
                PsychPortAudio('Start', pahandle, 1, 0, 1);
                PsychPortAudio('Stop', pahandle, 1);

                WaitSecs(1);
            else
                % if within time limit
                respIdx = find(strcmp(validKeys, keyPressed));
                trials(trialIdx).response = shuffledNames{respIdx};
                trials(trialIdx).rt = rt;

                % checking if correct
                correctIdx = find(cellfun(@(x) isequal(x, trial.fontRGB), colorRGBs));
                isCorrect = strcmpi(trials(trialIdx).response, colorNames{correctIdx});
                trials(trialIdx).correct = isCorrect;

                % showing the visual feedback and playing the feedback
                % sound
                Screen('TextSize', win, 100);
                if isCorrect
                    DrawFormattedText(win, 'Correct', 'center', 'center', [0 150 0]);
                    PsychPortAudio('FillBuffer', pahandle, corrSnd');
                else
                    DrawFormattedText(win, 'Incorrect', 'center', 'center', [255 0 0]);
                    PsychPortAudio('FillBuffer', pahandle, wrongSnd');
                end
                Screen('Flip', win);
                PsychPortAudio('Start', pahandle, 1, 0, 1);
                PsychPortAudio('Stop', pahandle, 1);
                WaitSecs(0.7);
            end

            % Update trial index, cycle if needed
            trialIdx = trialIdx + 1;
            if trialIdx > numTrialsTotal
                trialIdx = 1;
            end
        end

        % Rest period after the block of trials
        if block < numBlocks
            restStart = GetSecs;
            while (GetSecs - restStart) < restDuration
                elapsed = GetSecs - restStart;
                remaining = max(0, restDuration - elapsed);

                Screen('FillRect', win, [255 255 255]);
                Screen('TextSize', win, 150);
                DrawFormattedText(win, '+', 'center', 'center', [0 0 0]);
                Screen('TextSize', win, 40);
                restText = sprintf('Rest: %.1f s', remaining);
                DrawFormattedText(win, restText, 'center', yCenter + 150, [0 0 0]);

                Screen('Flip', win);

                % terminate the experiment anytime (pressing Esc)
                [keyIsDown, ~, keyCode] = KbCheck;
                if keyIsDown
                    if keyCode(KbName('ESCAPE'))
                        ShowCursor; sca; PsychPortAudio('Close', pahandle);
                        return;
                    end
                end
            end
        end
    end
    ShowCursor;
    sca;
    PsychPortAudio('Close', pahandle);
    save('stroop_results_keyboard_feedback.mat', 'trials');
end

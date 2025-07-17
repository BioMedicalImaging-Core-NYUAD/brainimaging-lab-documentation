function trials = GenerateSCWTTrials()
%This function generates the congurent and incongruent stroop trials

    % color names and their RGB values
    colorNames = {'red', 'blue', 'green', 'yellow', 'purple', 'cyan', ...
                  'orange', 'magenta', 'pink', 'brown'};

    % corresponding RGB vals
    colorRGBs = {
        [255, 0, 0],        % red
        [0, 0, 255],        % blue
        [0, 128, 0],        % green
        [255, 255, 0],      % yellow
        [128, 0, 128],      % purple
        [0, 255, 255],      % cyan
        [255, 165, 0],      % orange
        [255, 0, 255],      % magenta
        [255, 192, 203],    % pink
        [165, 42, 42]       % brown
    };

    colorMap = containers.Map(colorNames, colorRGBs);

    trials = [];  

    % Generate 10 congruent trials
    for i = 1:length(colorNames)
        word = colorNames{i};
        fontColor = word;
        trials(end+1).word = word;
        trials(end).fontColor = fontColor;
        trials(end).fontRGB = colorMap(fontColor);
        trials(end).correctResponse = fontColor;
        trials(end).type = 'congruent';
    end

    %generate 90 incongruent trials
    for i = 1:length(colorNames)
        word = colorNames{i};
        for j = 1:length(colorNames)
            if i ~= j
                fontColor = colorNames{j};
                trials(end+1).word = word;
                trials(end).fontColor = fontColor;
                trials(end).fontRGB = colorMap(fontColor);
                trials(end).correctResponse = fontColor;
                trials(end).type = 'incongruent';
            end
        end
    end

    % Randomize trial order
    trials = trials(randperm(length(trials)));

end
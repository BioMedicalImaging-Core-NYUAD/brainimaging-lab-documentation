function create_bids_events(pa, info)
% CREATE_BIDS_EVENTS - Create BIDS events.tsv and events.json files

if isempty(info) || ~isfield(info, 'fullPathTSV')
    return;
end

trialDuration = pa.stimulusDuration + pa.responseWindow + pa.feedbackDuration + pa.itiDuration;
nTrials = pa.trialCounter;

if nTrials == 0
    return;
end

onset = pa.data.trialStartTime(1:nTrials);
duration = repmat(trialDuration, nTrials, 1);
trial_type = pa.data.targetColor(1:nTrials);
response_time = pa.data.reactionTime(1:nTrials);
response = pa.data.response(1:nTrials);
correct = double(pa.data.correct(1:nTrials));

% Ensure all are column vectors
onset = onset(:);
duration = duration(:);
trial_type = trial_type(:);
response_time = response_time(:);
response = response(:);
correct = correct(:);

% Convert NaN to 'n/a'
response_time_str = cell(nTrials, 1);
for i = 1:nTrials
    if isnan(response_time(i))
        response_time_str{i} = 'n/a';
    else
        response_time_str{i} = sprintf('%.6f', response_time(i));
    end
end

eventsTable = table(onset, duration, trial_type, response_time_str, response, correct, ...
    'VariableNames', {'onset', 'duration', 'trial_type', 'response_time', 'response', 'correct'});

writetable(eventsTable, info.fullPathTSV, 'FileType', 'text', 'Delimiter', '\t');

% Create JSON
eventsJSON = struct();
eventsJSON.onset.Description = 'Onset (in seconds) of the event';
eventsJSON.onset.Units = 'seconds';
eventsJSON.duration.Description = 'Duration of the event in seconds';
eventsJSON.duration.Units = 'seconds';
eventsJSON.trial_type.Description = 'Trial type (target color)';
eventsJSON.response_time.Description = 'Response time in seconds (n/a for missed)';
eventsJSON.response_time.Units = 'seconds';
eventsJSON.response.Description = 'Participant response';
eventsJSON.correct.Description = 'Correct (1) or incorrect (0)';

jsonStr = jsonencode(eventsJSON, 'PrettyPrint', true);
fid = fopen(info.fullPathJSON, 'w');
if fid ~= -1
    fprintf(fid, '%s', jsonStr);
    fclose(fid);
end

end


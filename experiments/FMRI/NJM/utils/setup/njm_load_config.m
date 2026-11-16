function cfg = njm_load_config(experimentDir, mode)
% NJM_LOAD_CONFIG - Read the NJM parameter file, lookup tables and trial set
%
% Inputs:
%   experimentDir - NJM folder (the one that contains main.m and stimuli_data/)
%   mode          - 'task' (default, the 48 scanner trials) or 'practice'
%
% Output:
%   cfg.P      - everything in stimuli_data/njm_fmri_parameters.json
%   cfg.trials - trial set (table): design/njm_fmri_trials.csv or njm_practice_trials.csv
%   cfg.faces  - face inventory (table): faces/face_inventory.csv
%   cfg.codes  - event name -> marker code (struct), from physio_trigger_codes.csv
%   cfg.mode, cfg.stimDir, cfg.experimentDir

if nargin < 2 || isempty(mode), mode = 'task'; end
if ~ismember(mode, {'task', 'practice'})
    error('njm_load_config:mode', 'mode must be ''task'' or ''practice''');
end

stimDir = fullfile(experimentDir, 'stimuli_data');
jsonFile = fullfile(stimDir, 'njm_fmri_parameters.json');
if ~exist(jsonFile, 'file')
    error('njm_load_config:missingFile', 'Parameter file not found: %s', jsonFile);
end

cfg = struct();
cfg.P = jsondecode(fileread(jsonFile));
cfg.mode = mode;
cfg.stimDir = stimDir;
cfg.experimentDir = experimentDir;

if strcmp(mode, 'practice')
    trialFile = fullfile(stimDir, 'design', 'njm_practice_trials.csv');
else
    trialFile = fullfile(stimDir, 'design', 'njm_fmri_trials.csv');
end
cfg.trials = njm_read_csv(trialFile);
cfg.trials.dominant_profile = njm_cellstr(cfg.trials.dominant_profile);

cfg.faces = njm_read_csv(fullfile(stimDir, strrep(cfg.P.faces.inventory, '/', filesep)));

codes = njm_read_csv(fullfile(stimDir, 'physio_trigger_codes.csv'));
cfg.codes = struct();
for i = 1:height(codes)
    cfg.codes.(codes.event{i}) = codes.code(i);
end

end

%--------------------------------------------------------------------------
function T = njm_read_csv(file)
if ~exist(file, 'file')
    error('njm_load_config:missingFile', 'File not found: %s\n(run stimuli_data/generate_njm_design.py or prepare_faces.py)', file);
end
T = readtable(file, 'Delimiter', ',', 'TextType', 'char');
end

%--------------------------------------------------------------------------
function c = njm_cellstr(col)
% A text column that is empty in every row is read as NaN; make it a cell of ''.
if iscell(col)
    c = col;
    for i = 1:numel(c)
        if ~ischar(c{i}), c{i} = ''; end
    end
else
    c = repmat({''}, numel(col), 1);
end
end

function main()
% MAIN - Six-fingers motor execution task, template-style QC version
%
% This version keeps the original ME design but follows the MRI-center
% template structure:
%   - debugConfig controls scanner/laptop/debug behavior.
%   - VP stores display/viewing parameters.
%   - pa stores experiment timing, design, and data.
%   - kb stores keyboard mappings.

clear all; close all; sca;

scriptDir = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(scriptDir, 'utils')));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEBUG CONFIGURATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
debugConfig = struct();
debugConfig.enabled = 1;              % 1 = debug mode, 0 = production mode
debugConfig.useVPixx = 0;             % 1 = use VPixx/Datapixx hardware
debugConfig.fullscreen = 0;           % 1 = fullscreen, 0 = windowed mode
debugConfig.skipSyncTests = 1;        % 1 = skip sync tests, 0 = run sync tests
debugConfig.displayMode = 2;          % 1 = NYUAD lab/projector, 2 = laptop
debugConfig.manualTrigger = 1;        % 1 = keyboard trigger, 0 = scanner trigger
debugConfig.buttonbox = 0;            % Kept for template consistency
debugConfig.eyetracking = 0;          % Not used in this QC task

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GET BIDS INFORMATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
experimentDir = scriptDir;
try
    debugConfig.bidsInfo = get_info(experimentDir, 'Execution');
catch ME
    if contains(ME.message, 'cancelled') || contains(ME.message, 'not to overwrite')
        fprintf('Exiting.\n');
        return;
    end
    rethrow(ME);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% SETUP DISPLAY AND EXPERIMENT PARAMETERS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[VP, debugConfig] = setup_display(debugConfig);
[VP, pa] = setup_param(VP, debugConfig);
kb = setup_keyboard();

try
    wait_trigger(VP, debugConfig.manualTrigger);

    experimentStartTime = GetSecs;
    pa.experimentStartTime = experimentStartTime;
    fprintf('\n=== %s ===\n', pa.experimentName);

    for blockIdx = 1:pa.nBlocks
        trialList = pa.blockFingerOrder{blockIdx};
        fprintf('Block %d/%d order: %s\n', blockIdx, pa.nBlocks, strjoin(trialList, ', '));

        for trialInBlock = 1:pa.trialsPerBlock
            pa.trialCounter = pa.trialCounter + 1;
            fingerName = trialList{trialInBlock};

            [pa, exitFlag] = s1_rest(VP, pa, kb, experimentStartTime, blockIdx, trialInBlock);
            if exitFlag, break; end

            [pa, exitFlag] = s2_executionCue(VP, pa, kb, experimentStartTime, blockIdx, trialInBlock, fingerName);
            if exitFlag, break; end
        end

        if exist('exitFlag', 'var') && exitFlag
            break;
        end
    end

    if ~exist('exitFlag', 'var') || ~exitFlag
        [pa, ~] = s1_rest(VP, pa, kb, experimentStartTime, pa.nBlocks + 1, 0);
    end

    s3_endScreen(VP, pa);

catch ME
    fprintf('\n!!! ERROR OCCURRED !!!\n');
    fprintf('Error message: %s\n', ME.message);
    if ~isempty(ME.stack)
        fprintf('Error in: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
    end
end

if exist('experimentStartTime', 'var')
    cleanup_experiment(VP, pa, kb, experimentStartTime);
else
    cleanup_experiment(VP, pa, kb, GetSecs);
end

end

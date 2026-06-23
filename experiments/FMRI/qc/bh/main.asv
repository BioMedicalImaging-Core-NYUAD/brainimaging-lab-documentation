function main()
% MAIN - Breath-hold cerebrovascular reactivity QC task
%
% Participants follow paced breathing cues:
%   1. Breathe in slowly for 4 seconds.
%   2. Hold breath for 16 seconds.
%   3. Breathe normally for 40 seconds.
%
% The sequence repeats 4 times, followed by an additional 20 seconds of
% normal breathing after the final breath-hold. This matches the BH CVR
% timing described by Pillai and Mikulis: 4 s inspiration, 16 s breath-hold,
% 40 s normal breathing, repeated 4 times, plus final 20 s normal breathing.

clear all; close all; sca; %#ok<CLALL>

scriptDir = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(scriptDir, 'utils')));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% DEBUG CONFIGURATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
debugConfig = struct();
debugConfig.enabled = 1;              % 1 = debug mode, 0 = production mode
debugConfig.useVPixx = 0;             % 1 = use VPixx trigger hardware
debugConfig.fullscreen = 0;           % 1 = fullscreen, 0 = windowed mode
debugConfig.skipSyncTests = 1;        % 1 = skip sync tests, 0 = run sync tests
debugConfig.displayMode = 2;          % 1 = NYUAD lab/projector, 2 = laptop
debugConfig.manualTrigger = 1; 5       % 1 = keyboard trigger, 0 = scanner trigger

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% GET BIDS INFORMATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
experimentDir = scriptDir;
try
    debugConfig.bidsInfo = get_info(experimentDir, 'bh');
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

    for cycleIdx = 1:pa.nCycles
        pa.cycleCounter = cycleIdx;
        fprintf('Cycle %d/%d\n', cycleIdx, pa.nCycles);

        [pa, exitFlag] = s1_inhale(VP, pa, kb, experimentStartTime, cycleIdx);
        if exitFlag, break; end

        [pa, exitFlag] = s2_hold(VP, pa, kb, experimentStartTime, cycleIdx);
        if exitFlag, break; end

        [pa, exitFlag] = s3_rest(VP, pa, kb, experimentStartTime, cycleIdx, pa.restDuration);
        if exitFlag, break; end
    end

    if (~exist('exitFlag', 'var') || ~exitFlag) && pa.finalRestDuration > 0
        [pa, exitFlag] = s3_rest(VP, pa, kb, experimentStartTime, pa.nCycles + 1, pa.finalRestDuration);
    end

    if ~exist('exitFlag', 'var') || ~exitFlag
        s4_endScreen(VP, pa);
    end

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

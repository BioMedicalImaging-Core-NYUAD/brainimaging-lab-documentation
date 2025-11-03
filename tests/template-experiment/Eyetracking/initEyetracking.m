function EL = initEyetracking(VP, pa)

%% Initialize Eyetracker
% Adapted from vri_restingstate to work with VP and pa structure instead of const

[EL, exitFlag] = initEyelinkStates('eyestart', VP.window, {pa.eyeFileBase, pa});
if exitFlag, EL = []; return, end

EL.eyeDataDir = pa.eyeDataDir;
EL.eyeFile = pa.eyeFileBase;


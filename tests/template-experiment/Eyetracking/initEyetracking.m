function EL = initEyetracking(VP, pa)

%% Initialize Eyetracker
% Adapted to work with our VP and pa structure instead of const

% Create a screen struct compatible with reference implementation
% initEyelinkStates expects {eyeFile, screen} where screen has .gray
screen.gray = VP.gray;

[EL, exitFlag] = initEyelinkStates('eyestart', VP.window, {pa.eyeFileBase, screen});
if exitFlag, EL = []; return, end

EL.eyeDataDir = pa.eyeDataDir;
EL.eyeFile = pa.eyeFileBase;


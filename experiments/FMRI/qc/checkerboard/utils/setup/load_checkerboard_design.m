function design = load_checkerboard_design(designID)
% LOAD_CHECKERBOARD_DESIGN - Return a fixed 4-minute A/B/C HRF design.

if nargin < 1 || isempty(designID)
    designID = 'A';
end

designID = upper(strtrim(designID));
designIDs = {'A', 'B', 'C'};
designSeeds = [1101, 2202, 3303];
seedIndex = find(strcmp(designID, designIDs), 1);

if isempty(seedIndex)
    error('load_checkerboard_design:invalidDesign', ...
        'Invalid design ID "%s". Choose A, B, or C.', designID);
end

design = struct();
design.designID = designID;
design.designSeed = designSeeds(seedIndex);
design.targetRunDuration = 238;       % seconds, excluding end screen
design.stimDuration = 1.000;          % seconds
design.flickerHz = 8;                 % contrast reversals per second
design.isiMin = 4;                    % seconds
design.isiMax = 12;                   % seconds
design.nEvents = 27;
design.initialBaselineDuration = 10;  % seconds
design.finalBaselineDuration = 10;    % seconds
design.dimDuration = 0.3;             % seconds
design.dimFraction = 0.3;

targetIsiSum = design.targetRunDuration - ...
    design.initialBaselineDuration - design.finalBaselineDuration - ...
    design.nEvents * design.stimDuration;

minIsiSum = design.nEvents * design.isiMin;
maxIsiSum = design.nEvents * design.isiMax;
if targetIsiSum < minIsiSum || targetIsiSum > maxIsiSum
    error('load_checkerboard_design:invalidTiming', ...
        'Target run duration cannot be reached with current ISI limits.');
end

rng(design.designSeed, 'twister');
isiSequence = design.isiMin + ...
    (design.isiMax - design.isiMin) * rand(1, design.nEvents);

delta = targetIsiSum - sum(isiSequence);
if delta >= 0
    headroom = design.isiMax - isiSequence;
    isiSequence = isiSequence + delta * headroom / sum(headroom);
else
    slack = isiSequence - design.isiMin;
    isiSequence = isiSequence + delta * slack / sum(slack);
end

design.isiSequence = isiSequence;
design.plannedOnsets = design.initialBaselineDuration + ...
    [0, cumsum(design.stimDuration + design.isiSequence(1:end-1))];
design.totalDesignDuration = design.initialBaselineDuration + ...
    sum(design.isiSequence) + design.nEvents * design.stimDuration + ...
    design.finalBaselineDuration;

design.dimSchedule = zeros(1, design.nEvents);
dimTrials = randperm(design.nEvents, round(design.nEvents * design.dimFraction));
for i = dimTrials
    maxDimOnset = max(0.5, design.isiSequence(i) - design.dimDuration - 0.5);
    design.dimSchedule(i) = 0.5 + (maxDimOnset - 0.5) * rand();
end
design.dimTrials = dimTrials;

end

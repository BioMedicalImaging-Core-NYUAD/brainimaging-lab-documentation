function fingermap = compute_fingermap(betaAvg, task, hemi, bidsDir)
% Compute a continuous finger preference map and mask it to the ROI.
%
% Betas are demeaned across fingers per vertex before computing the
% weighted average, to avoid the midpoint bias (a vertex responding
% equally to all fingers would otherwise score 3.0 = middle finger).
%
% Inputs:
%   betaAvg - [nVerts x nFingers] group-averaged betas on fsaverage6
%   task    - 'Execution' (fingers 1-5) or 'Imagery' (fingers 1-6)
%   hemi    - 'lh' or 'rh'
%   bidsDir - root project directory
%
% Output:
%   fingermap - [nVerts x 1] continuous finger preference (0 outside ROI)

% --- Finger IDs ---
if strcmp(task, 'Imagery')
    fingerIDs = [1 2 3 4 5 6];
else
    fingerIDs = [1 2 3 4 5];
end

% --- Demean betas across fingers per vertex ---
betaDemeaned = betaAvg - mean(betaAvg, 2);  % [nVerts x nFingers]

% Only above-average responses vote
bPos = max(betaDemeaned, 0);  % [nVerts x nFingers]

weightedSum = bPos * fingerIDs';       % [nVerts x 1]
totalWeight = sum(bPos, 2);            % [nVerts x 1]

fingermap = weightedSum ./ totalWeight;
fingermap(isnan(fingermap)) = 0;       % untuned vertices -> 0

% --- Load HCP-MMP1 annotation on fsaverage6 ---
annotFile = fullfile(bidsDir, 'derivatives', 'freesurfer', 'fsaverage6', 'label', ...
    [hemi '.HCP-MMP1.annot']);
if ~exist(annotFile, 'file')
    error('HCP-MMP1 annot not found: %s', annotFile);
end

[~, label, colortable] = read_annotation(annotFile);

% --- Find the target ROI ---
if strcmp(task, 'Execution')
    roiName = [upper(hemi(1)) '_4_ROI'];    % M1
else
    roiName = [upper(hemi(1)) '_3b_ROI'];   % Primary somatosensory cortex
end

roiIdx = find(strcmp(colortable.struct_names, roiName));
if isempty(roiIdx)
    error('ROI "%s" not found in HCP-MMP1 annotation', roiName);
end

roiColor = colortable.table(roiIdx, 1) + ...
           colortable.table(roiIdx, 2) * 2^8 + ...
           colortable.table(roiIdx, 3) * 2^16;

roiMask = (label == roiColor);  % [nVerts x 1]

% --- Apply mask ---
fingermap(~roiMask) = 0;

end

function fingermap = compute_fingermap_WTA(betaAvg, task, hemi, bidsDir)
% Compute a winner-takes-all finger preference map and mask it to the ROI.
%
% For each vertex, the finger with the highest beta is assigned as the
% preference. No threshold is applied — the anatomical ROI mask is the
% only filter. Vertices outside the ROI are set to 0.
%
% This follows the approach in Kikkert et al. (2021, HBM):
%   "each voxel was labeled as representing the hand region whose
%    stimulation elicited the highest t-score (against rest)"
% Here we use group-averaged betas instead of single-subject t-scores.
%
% Inputs:
%   betaAvg - [nVerts x nFingers] group-averaged betas on fsaverage
%   task    - 'Execution' (fingers 1-5) or 'Imagery' (fingers 1-6)
%   hemi    - 'lh' or 'rh'
%   bidsDir - root project directory
%
% Output:
%   fingermap - [nVerts x 1] integer finger label (1-5 or 1-6), 0 outside ROI

% --- Winner-takes-all ---
% For each vertex, find which finger has the highest beta
[~, winnerIdx] = max(betaAvg, [], 2);  % [nVerts x 1], values 1..nFingers
fingermap = double(winnerIdx);

% --- Load HCP-MMP1 annotation on fsaverage ---
annotFile = fullfile(bidsDir, 'derivatives', 'freesurfer', 'fsaverage', 'label', ...
    [hemi '.HCP-MMP1.annot']);
if ~exist(annotFile, 'file')
    error('HCP-MMP1 annot not found: %s', annotFile);
end

[~, label, colortable] = read_annotation(annotFile);

% --- Find the target ROI ---
if strcmp(task, 'Execution')
    roiName = [upper(hemi(1)) '_4_ROI'];    % L_4_ROI or R_4_ROI  (M1)
else
    roiName = [upper(hemi(1)) '_6mp_ROI'];  % L_6mp_ROI or R_6mp_ROI (SMA proper)
end

roiIdx = find(strcmp(colortable.struct_names, roiName));
if isempty(roiIdx)
    error('ROI "%s" not found in HCP-MMP1 annotation', roiName);
end

roiColor = colortable.table(roiIdx, 1) + ...
           colortable.table(roiIdx, 2) * 2^8 + ...
           colortable.table(roiIdx, 3) * 2^16;

roiMask = (label == roiColor);  % logical [nVerts x 1]

% --- Apply mask ---
fingermap(~roiMask) = 0;

end

function fingermap = compute_fingermap_WTA(tstatAvg, task, hemi, bidsDir)
% Winner-takes-all finger preference map, masked to the ROI.
%
% Each vertex is assigned the finger with the highest group-averaged
% t-statistic. Follows Kikkert et al. (2021, HBM).
%
% Inputs:
%   tstatAvg - [nVerts x nFingers] group-averaged t-stats on fsaverage6
%   task     - 'Execution' (fingers 1-5) or 'Imagery' (fingers 1-6)
%   hemi     - 'lh' or 'rh'
%   bidsDir  - root project directory
%
% Output:
%   fingermap - [nVerts x 1] integer finger label (1-5 or 1-6), 0 outside ROI

% --- Winner-takes-all ---
[~, winnerIdx] = max(tstatAvg, [], 2);  % [nVerts x 1]
fingermap = double(winnerIdx);

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

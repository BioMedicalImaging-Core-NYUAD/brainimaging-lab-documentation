function fingermap = compute_fingermap(betaAvg, task, hemi, bidsDir)
% Compute a continuous finger preference map and mask it to the ROI.
%
% At each vertex, betas are first demeaned across fingers (subtract the
% vertex's mean beta), then a weighted average of finger identities is
% computed using only above-average (positive demeaned) responses:
%   fingermap = (1*b_thumb + 2*b_index + ... + N*b_last) / (b_thumb + ... + b_last)
%   where b_i = max(beta_i - mean(betas), 0)
% Demeaning prevents the midpoint bias: a vertex responding equally to all
% fingers gets fingermap=0 (excluded) rather than 3 (false middle preference).
% A vertex with equal thumb and index above-average response gets 1.5; pure thumb gets 1.0.
%
% Inputs:
%   betaAvg - matrix of size [nVerts x nFingers], group-averaged betas on fsaverage
%   task    - 'Execution' (fingers 1-5) or 'Imagery' (fingers 1-6, sixth=6)
%   hemi    - 'lh' or 'rh'
%   bidsDir - root project directory (used to locate HCP-MMP1 annot on fsaverage)
%
% Output:
%   fingermap - [nVerts x 1] continuous finger preference, masked to ROI (0 outside)

% --- Finger IDs ---
if strcmp(task, 'Imagery')
    fingerIDs = [1 2 3 4 5 6];  % thumb=1 ... pinky=5, sixth=6
else
    fingerIDs = [1 2 3 4 5];    % thumb=1 ... pinky=5
end

% --- Weighted average of finger identity ---
% Demean betas across fingers per vertex before computing preference.
% This removes the global response level so that only relative finger
% preference contributes. A vertex responding equally to all fingers
% gets demeaned values of zero and is excluded (totalWeight=0 → fingermap=0),
% avoiding the false "middle finger" bias that arises from the midpoint of
% the finger ID scale (1-5 midpoint = 3 = middle finger).
betaDemeaned = betaAvg - mean(betaAvg, 2);  % [nVerts x nFingers]

% Zero out negative demeaned betas — only above-average finger responses vote
bPos = max(betaDemeaned, 0);  % [nVerts x nFingers]

weightedSum = bPos * fingerIDs';       % [nVerts x 1]
totalWeight = sum(bPos, 2);            % [nVerts x 1]

fingermap = weightedSum ./ totalWeight; % [nVerts x 1], NaN where no finger is above average
fingermap(isnan(fingermap)) = 0;        % unresponsive / untuned vertices → 0

% --- Load HCP-MMP1 annotation on fsaverage ---
annotFile = fullfile(bidsDir, 'derivatives', 'freesurfer', 'fsaverage', 'label', ...
    [hemi '.HCP-MMP1.annot']);
if ~exist(annotFile, 'file')
    error('HCP-MMP1 annot not found: %s', annotFile);
end

[~, label, colortable] = read_annotation(annotFile);

% --- Find the target ROI ---
if strcmp(task, 'Execution')
    roiName = [upper(hemi(1)) '_4_ROI'];   % L_4_ROI or R_4_ROI  (M1)
else
    % roiName = [upper(hemi(1)) '_6mp_ROI']; % L_6mp_ROI or R_6mp_ROI (SMA proper)
    roiName = [upper(hemi(1)) '_3b_ROI']; % L_3b_ROI	(Primary Somatosensory area)
end

roiIdx = find(strcmp(colortable.struct_names, roiName));
if isempty(roiIdx)
    error('ROI "%s" not found in HCP-MMP1 annotation', roiName);
end

% colortable encodes each parcel as a single integer: R + G*2^8 + B*2^16
roiColor = colortable.table(roiIdx, 1) + ...
           colortable.table(roiIdx, 2) * 2^8 + ...
           colortable.table(roiIdx, 3) * 2^16;

roiMask = (label == roiColor);  % logical [nVerts x 1]

% --- Apply mask ---
fingermap(~roiMask) = 0;

end

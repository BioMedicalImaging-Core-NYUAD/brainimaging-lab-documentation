# Sixthfinger fMRI Pipeline — `code/test/` Report

This document describes the analysis pipeline implemented in `code/test/`. It covers every stage from raw fMRIPrep output through per-subject GLM, run combination, group averaging, and fingermap computation.

---

## Overview

The test pipeline processes fMRI data to produce **per-finger cortical activation maps** (beta weights and t-statistics) on the `fsaverage6` surface, and then computes **center-of-gravity (CoG) fingermaps** that summarise which part of cortex is most strongly tuned to each finger. It handles two task types:

- **Execution** — physical finger tapping, 5 fingers (thumb, index, middle, ring, pinky), 3 runs per session
- **Imagery** — motor imagery, 6 fingers (thumb, index, middle, ring, pinky, sixth), 5 runs per session

The pipeline is organised as flat scripts; `xxx.m` and `yyy.m` are the entry points for Execution and Imagery respectively, with three shared helper functions (`test_load_dataLog`, `test_load_dsm`, `test_get_beta`) and two post-processing scripts (`average_subjects.m`, `average_subjects_fsavg6.m`, `compute_fingermap.m`).

---

## Scripts and Responsibilities

| Script | Role |
|---|---|
| `xxx.m` | Batch Execution GLM for all subjects, fsaverage6 space |
| `yyy.m` | Batch Imagery GLM for all subjects, fsaverage6 space |
| `xxx_native.m` | Single-subject Execution GLM in native FreeSurfer space |
| `test_load_dataLog.m` | Load BOLD surface data from fMRIPrep output |
| `test_load_dsm.m` | Load design matrices and noise regressors |
| `test_get_beta.m` | Fit GLM per run, return contrast betas and SEs |
| `average_subjects.m` | Threshold-then-average across subjects, compute group CoG fingermap (reads from `Execution6/`) |
| `average_subjects_fsavg6.m` | Same logic, reads from `Execution_fsavg6/` |
| `compute_fingermap.m` | Recompute CoG fingermaps from existing group t-stat files |
| `check_maps.m` | Commented-out freeview visualisation command |

---

## Subject and Session Configuration

All subject IDs, session labels, and design matrix numbers are read from `code/map.json`:

```json
{
  "subjects": [
    { "subID": "sub-0457", "dmNum": 102, "sessions": ["ses-01", "ses-02", "ses-03"] },
    ...
  ],
  "sessionDirs": [
    { "session": "ses-01", "dmDir": "fmri_pre_dm/ses-01" },
    ...
  ]
}
```

The `dmNum` field identifies which design matrix folder to use for that subject. This mapping handles the fact that different subjects may have different design matrix numbering schemes.

---

## Stage 1 — Loading BOLD Data (`test_load_dataLog`)

### Input

fMRIPrep GIFTI surface files in **fsaverage6** space:

```
derivatives/fmriprep/sub-XXXX/ses-XX/func/
    sub-XXXX_ses-XX_task-Execution_run-01_hemi-L_space-fsaverage6_bold.func.gii
    sub-XXXX_ses-XX_task-Execution_run-01_hemi-R_space-fsaverage6_bold.func.gii
    ...
```

### Conversion

If the `.mgh` version of a file does not already exist, `mri_convert` is called to convert from `.gii` to `.mgh`. This is cached — if the `.mgh` already exists it is loaded directly, avoiding repeated conversion. FreeSurfer environment variables (`FREESURFER_HOME`, `FS_LICENSE`) are set programmatically before calling `mri_convert`.

### Output

A cell array `datafiles{r}` where each element is a `[nVerts × nTimepoints]` matrix for run `r`. Left and right hemispheres are concatenated row-wise:

- Vertices `1:40962` — left hemisphere
- Vertices `40963:81924` — right hemisphere

fsaverage6 has **40,962 vertices per hemisphere** (~3 mm spatial resolution), matching typical 3 mm fMRI acquisition. Total: 81,924 vertices.

---

## Stage 2 — Loading Design Matrices (`test_load_dsm`)

### Design Matrix Files

Per-run CSV files from the experimental stimulus log, located in:

```
code/fmri_pre_dm/<dmNum>/Results/
    sixFingers1_ME_<dmNum>_<runFileNum>_*_dm.csv   (Execution)
    sixFingers1_MI_<dmNum>_<runFileNum>_*_dm.csv   (Imagery)
```

The run-to-file-number mapping is hard-coded:
- Imagery runs 1–5 → file numbers `[1, 3, 5, 7, 8]`
- Execution runs 1–3 → file numbers `[2, 4, 6]`

Each CSV contains one column per finger condition (5 for Execution, 6 for Imagery) encoding the stimulus onset times as a binary or boxcar time series.

### HRF Convolution

Each design matrix column is convolved with the canonical HRF. The function attempts to use SPM's `spm_hrf(TR)` (TR = 1 s) and falls back to a simple double-gamma HRF if SPM is not available:

```matlab
hrf = gampdf(t, 6) - gampdf(t, 16) / 6;
hrf = hrf' / sum(hrf);
```

Convolution is done with MATLAB's `conv()`, truncated to the original number of timepoints.

### Noise Regressors

Confound regressors are loaded from fMRIPrep's confounds TSV:

```
derivatives/fmriprep/sub-XXXX/ses-XX/func/
    sub-XXXX_ses-XX_task-Execution_run-01_desc-confounds_timeseries.tsv
```

The following columns are extracted:

| Regressor | Description |
|---|---|
| `trans_x`, `trans_y`, `trans_z` | Head translation (3 parameters) |
| `rot_x`, `rot_y`, `rot_z` | Head rotation (3 parameters) |
| `global_signal` | Mean signal across all brain voxels |
| `white_matter` | Mean signal in white matter mask |
| `csf` | Mean signal in CSF mask |

Any NaN values (common in the first row for derivative regressors) are replaced with 0. A constant (intercept) and linear drift term are appended:

```
myNoise = [ones(nTimepoints,1), (1:nTimepoints)', trans_x, trans_y, trans_z, rot_x, rot_y, rot_z, global_signal, white_matter, csf]
```

Total noise regressors per run: **11** (2 drift + 9 physiology/motion).

---

## Stage 3 — GLM Per Run (`test_get_beta`)

### Percent Signal Change Normalisation

Raw BOLD signal is converted to percent signal change (PSC) before entering the GLM:

```
Y_psc = (Y / mean(Y, time) − 1) × 100
```

This normalises each vertex by its own mean, removing baseline differences between vertices and making beta weights interpretable in units of % signal change.

### OLS Estimation

The full design matrix is assembled by concatenating finger regressors and noise regressors:

```
X = [dsm{r}, myNoise{r}]   % [nTimepoints × (nFingers + 11)]
```

Beta weights are estimated via ordinary least squares:

```
β = (X'X)⁻¹ X' Y    % [nVerts × nRegressors]
```

The finger-only fitted response is also saved (noise regressors excluded):

```
Y_fit = X(:, 1:nFingers) × β(:, 1:nFingers)'
```

### Contrast Betas

Unlike `code-test/get_beta.m` which returns raw betas, `test_get_beta` applies a **contrast** for each finger before returning:

```
c = [-1/(nFingers-1), ..., 1, ..., -1/(nFingers-1)]
```

For finger `f`, the contrast vector has `1` at position `f` and `-1/(nFingers-1)` at all other finger positions, then zeros for the noise regressors. This encodes "activation for this finger relative to the mean of all other fingers".

For 5 fingers, `c = [1, -0.25, -0.25, -0.25, -0.25]` for the thumb contrast (positions rotated per finger).

The contrast beta and its SE are:

```
c_beta[v, f]  = c_full × β[v, :]'            % [nVerts × 1]
VIF           = c_full × (X'X)⁻¹ × c_full'  % scalar — variance inflation factor
c_SE[v, f]    = √(σ²[v] × VIF)               % [nVerts × 1]
```

Where `σ²[v] = RSS[v] / (n − p)` is the residual variance per vertex.

**Key distinction from `code-test`:** The VIF term `c × (X'X)⁻¹ × c'` uses the full contrast vector and captures the covariance between finger regressors. `code-test` uses only the diagonal element `(X'X)⁻¹[f,f]`, which ignores inter-regressor covariance.

### Outputs Per Run

- `c_betas{r}` — `[nVerts × nFingers]` contrast beta weights
- `c_SEs{r}` — `[nVerts × nFingers]` contrast standard errors
- No p-values are computed at this stage

---

## Stage 4 — Combining Runs (Precision Weighting)

Runs are combined using **inverse-variance (precision) weighting**, giving more weight to low-noise runs:

```matlab
all_betas = cat(3, c_betas{:});   % [nVerts × nFingers × nRuns]
all_SEs   = cat(3, c_SEs{:});     % [nVerts × nFingers × nRuns]
W         = 1 ./ (all_SEs .^ 2);  % inverse variance weights

beta_combined  = sum(all_betas .* W, 3) ./ sum(W, 3);  % [nVerts × nFingers]
se_combined    = 1 ./ sqrt(sum(W, 3));                  % [nVerts × nFingers]
t_stat_combined = beta_combined ./ se_combined;          % [nVerts × nFingers]
```

No p-values are computed. Degrees of freedom are not tracked.

---

## Stage 5 — ROI Masking (M1 + S1)

Before saving, all vertices outside the ROI are zeroed out. The mask is the **union of M1 and full S1**, defined by the HCP-MMP1 parcellation on fsaverage6.

### Label Files Used

```
derivatives/freesurfer/fsaverage6/label/HCP-MMP1/
    lh.L_4_ROI.label      ← M1 (primary motor cortex)
    lh.L_1_ROI.label      ← S1 area 1
    lh.L_2_ROI.label      ← S1 area 2
    lh.L_3a_ROI.label     ← S1 area 3a (deep pressure / proprioception)
    lh.L_3b_ROI.label     ← S1 area 3b (primary cutaneous)
    rh.R_4_ROI.label
    rh.R_1_ROI.label
    rh.R_2_ROI.label
    rh.R_3a_ROI.label
    rh.R_3b_ROI.label
```

Labels are read with FreeSurfer's `read_label()`, which returns 0-indexed vertex indices. These are converted to 1-indexed MATLAB indices (`ld(:,1) + 1`) and unioned into a single binary mask per hemisphere.

**Important:** The same combined M1+S1 mask is applied to **both** Execution and Imagery. This is different from `code-test/`, which uses a task-specific ROI (M1 only for Execution, area 3b only for Imagery).

### For `xxx_native.m` (native space)

The equivalent labels come from the **Glasser2016** parcellation in the subject's native FreeSurfer directory:

```
derivatives/freesurfer/sub-XXXX/label/Glasser2016/
    lh.4.label, lh.3a.label, lh.3b.label, lh.1.label, lh.2.label
    rh.4.label, rh.3a.label, rh.3b.label, rh.1.label, rh.2.label
```

Same five regions, same union logic.

---

## Stage 6 — Per-Subject Outputs

Saved to `derivatives/Execution6/sub-XXXX/ses-XX/` (or `Imagery6/`):

```
lh.thumb.mgz           ← combined contrast beta, left hemisphere
lh.thumb_tstat.mgz     ← combined t-statistic
rh.thumb.mgz
rh.thumb_tstat.mgz
... (index, middle, ring, pinky; + sixth for Imagery)
```

Execution: 5 fingers × 2 hemis × 2 types = **20 files per session**
Imagery:   6 fingers × 2 hemis × 2 types = **24 files per session**

No p-value maps are saved (unlike `code-test/`).

For `xxx_native.m`, the fingermap is also computed and saved at the subject level immediately after the GLM (no separate group step needed for the native-space variant).

---

## Stage 7 — Group Averaging (`average_subjects.m` / `average_subjects_fsavg6.m`)

These two scripts are functionally identical in logic. `average_subjects.m` reads from `Execution6/` and `average_subjects_fsavg6.m` reads from `Execution_fsavg6/`. The description below applies to both.

### Part 1: Per-Subject CoG Fingermaps

Before group averaging, a CoG fingermap is computed for each subject/session/hemisphere and saved back to the subject's output directory. This uses the per-subject t-stat maps already on disk.

### Part 2: Thresholded Group Averaging

The key design decision is **individual-level thresholding before accumulation**. Rather than averaging every vertex across all subjects, only vertices where the subject shows a selective response (max t-stat > 1.96, i.e. p < 0.05 uncorrected) contribute to the group average.

For each session and hemisphere:

1. **Load** all finger t-stat and beta maps for each subject
2. **Threshold** per subject: compute `max_t[v] = max over fingers of t[v, f]`. A vertex is "selective" if `max_t > 1.96`
3. **Accumulate**: only selective vertices are added to the running sum; a counter `countMap[v]` tracks how many subjects contributed at each vertex
4. **Average**: divide the accumulated sum by `countMap` to get the per-vertex mean across contributing subjects

```matlab
maxT       = max(tdata, [], 2);         % [nVerts × 1]
selective  = maxT > tThreshold;         % logical mask

sumTstat(selective, :) = sumTstat(selective, :) + tdata(selective, :);
sumBeta(selective, :)  = sumBeta(selective, :)  + bdata(selective, :);
countMap(selective)    = countMap(selective) + 1;
```

This approach means the group map reflects only vertices that are reliably active at the individual level, reducing noise from vertices that show no selectivity in a given subject. The tradeoff is that the effective sample size varies per vertex — a vertex with low `countMap` is noisier.

### Outputs

Saved to `derivatives/Execution6/fsaverage6/ses-XX/`:

```
lh.thumb.mgz           ← group-averaged (thresholded) beta
lh.thumb_tstat.mgz     ← group-averaged (thresholded) t-stat
lh.nsubjects.mgz       ← number of subjects that contributed at each vertex
lh.fingermap.mgz       ← group CoG fingermap
rh.thumb.mgz
... (all fingers)
rh.nsubjects.mgz
rh.fingermap.mgz
```

Execution: 5 fingers × 2 hemis × 2 types + 2 nsubjects + 2 fingermaps = **24 files per session**

---

## Stage 8 — CoG Fingermap Computation

The `compute_cog` function (defined locally within each script) computes a continuous finger preference map via center-of-gravity weighting.

### Algorithm

```
1. threshold: selective[v] = (max_f t[v,f]) > tThreshold
2. rectify:   tRect[v,f]   = max(t[v,f], 0)          (negative t-stats don't contribute)
3. weights:   W[v,f]       = tRect[v,f]               for selective vertices
4. CoG:       fingermap[v] = Σ_f (f × W[v,f]) / Σ_f W[v,f]
```

Where `f` is the finger label (1=thumb, 2=index, ..., 5=pinky or 6=sixth).

The result is a continuous value in `[1, 5]` (or `[1, 6]` for Imagery) where the value reflects the "center of mass" of finger selectivity. A vertex tuned primarily to the thumb scores near 1; a vertex tuned primarily to the pinky scores near 5. A vertex with equal weight on all fingers scores at the midpoint (~3). Vertices below the threshold score 0.

**tThreshold values used:**
- `average_subjects.m` / `average_subjects_fsavg6.m`: `tThreshold = 1.96` (p < 0.05)
- `compute_fingermap.m`: `tThreshold = 0` (no threshold — all vertices contribute)
- `xxx_native.m`: `tThreshold = 1.96`

### Difference from `code-test/compute_fingermap.m`

`code-test` **demeanes** betas across fingers per vertex before weighting:

```
β̃[v,f] = β[v,f] − mean_f(β[v,:])
```

This removes the "midpoint bias": without demeaning, a vertex that responds equally to all fingers (flat tuning profile) would score at the midpoint (3.0 for 5 fingers), as if it were tuned to the middle finger. With demeaning, its above-average weights are all zero and it scores 0 (untuned).

The `test/` CoG approach using t-stats with a selectivity threshold (`tThreshold = 1.96`) partially addresses this differently: vertices with no selective response are simply excluded by the threshold, so they score 0 regardless.

---

## Summary of Differences vs. `code-test/`

| Aspect | `test/` | `code-test/` |
|---|---|---|
| **GLM output** | Contrast betas (each finger vs. mean of others) | Raw betas per finger regressor |
| **SE computation** | Full VIF: `c × (X'X)⁻¹ × c'` | Diagonal only: `(X'X)⁻¹[f,f]` |
| **P-values** | Not computed or saved | Saved per finger (`_pval.mgz`) |
| **ROI** | Combined M1 + full S1 (areas 4, 1, 2, 3a, 3b) for both tasks | Task-specific: M1 (area 4) for Execution; S1 area 3b for Imagery |
| **ROI source** | Individual `.label` files | Single `.HCP-MMP1.annot` annotation |
| **Group averaging** | Thresholded: only selective vertices contribute; per-vertex subject count | Simple mean across all subjects |
| **Fingermap type** | CoG on t-stats with threshold | Demeaned CoG on betas (+ WTA variant) |
| **Bias correction** | None (threshold excludes flat vertices) | Explicit demeaning |
| **Both tasks in one pass** | Separate scripts (`xxx.m`, `yyy.m`) | Single `process_subject_fingermap.m` |
| **Architecture** | Flat scripts | Modular: entry script calls functions |
| **Native space** | `xxx_native.m` (single subject) | Not implemented |

---

## Output Folder Summary

| Folder | Contents | Created by |
|---|---|---|
| `derivatives/Execution6/sub-XXXX/ses-XX/` | Per-subject contrast beta + t-stat maps | `xxx.m` |
| `derivatives/Imagery6/sub-XXXX/ses-XX/` | Per-subject contrast beta + t-stat maps | `yyy.m` |
| `derivatives/Execution_native/sub-XXXX/ses-XX/` | Native-space beta, t-stat, fingermap | `xxx_native.m` |
| `derivatives/Execution6/fsaverage6/ses-XX/` | Group-averaged beta, t-stat, nsubjects, CoG fingermap | `average_subjects.m` |
| `derivatives/Execution_fsavg6/fsaverage6/ses-XX/` | Same as above (reads from `Execution_fsavg6/`) | `average_subjects_fsavg6.m` |

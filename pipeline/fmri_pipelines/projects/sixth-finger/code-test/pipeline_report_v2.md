# Sixthfinger fMRI Pipeline — Version 2 Report

This document describes the updated analysis pipeline (`code/code-test/`). The key differences from the original pipeline are: (1) no resampling step — data is loaded directly from fMRIPrep in fsaverage6 space, (2) runs are combined via inverse-variance weighting rather than simple averaging, and (3) proper p-values are computed and saved per finger.

---

## Overview of Changes vs. Original Pipeline

| | Original (`code/`) | Version 2 (`code/code-test/`) |
|---|---|---|
| Input space | fsnative → resampled to fsaverage | fsaverage6 directly from fMRIPrep |
| Surface vertices | 163,842 per hemi (fsaverage) | 40,962 per hemi (fsaverage6) |
| Run combination | Simple mean of betas and t-stats | Inverse-variance weighted average |
| T-statistics | Averaged across runs (invalid) | Derived from combined β and SE |
| P-values | Not saved | Saved per finger per hemisphere |
| Imagery ROI | SMA (6mp) | Primary somatosensory cortex (3b) |

---

## Part 1 — `run_main.m`: First-Level GLM Per Subject

### Step 1.1 — Load BOLD Data (fsaverage6)

fMRIPrep outputs the preprocessed BOLD signal on two surface spaces. Version 2 loads the **fsaverage6** files directly:

```
derivatives/fmriprep/sub-XXXX/ses-XX/func/
    sub-XXXX_ses-XX_task-Execution_run-01_hemi-L_space-fsaverage6_bold.func.gii
    sub-XXXX_ses-XX_task-Execution_run-01_hemi-R_space-fsaverage6_bold.func.gii
    ...
```

fsaverage6 has **40,962 vertices per hemisphere** (81,924 total), matching the actual spatial resolution of the fMRI data (~3 mm voxels). The original fsaverage had 163,842 vertices per hemisphere — oversampling the data. Left and right hemispheres are concatenated into a single `[81924 × nTimepoints]` matrix per run. The hemisphere split is fixed: vertices `1:40962` = left, `40963:81924` = right.

No `mri_surf2surf` resampling is needed at any stage.

---

### Step 1.2 — GLM Per Run

The GLM is fit independently at every vertex (mass-univariate). For each run:

```
Y = X · β + ε
```

Where:
- `Y` — BOLD signal in percent signal change (PSC): `(signal/mean − 1) × 100`
- `X` — design matrix `[nTimepoints × (nFingers + nNoise)]`
- `β` — beta weights estimated via OLS: `β = (X'X)⁻¹ X' Y`

The standard error of each finger beta is computed directly from the residuals:

```
RSS         = Σ (Y − X·β)²             residual sum of squares
σ²          = RSS / (n − p)            residual variance, df = timepoints − regressors
SE(βⱼ)      = √(σ² · (X'X)⁻¹ⱼⱼ)      standard error of finger regressor j
```

`get_beta.m` returns per run:
- `betas{r}` — `[nVerts × nRegressors]`
- `SEs{r}`   — `[nVerts × nFingers]` (finger regressors only)
- `dfs(r)`   — scalar degrees of freedom for run r

---

### Step 1.3 — Combining Runs via Inverse-Variance Weighting

Runs are combined within each task (5 Imagery runs, 3 Execution runs). Simple averaging of betas ignores the fact that some runs are noisier than others, and simple averaging of t-stats is statistically invalid. Instead, runs are combined using **inverse-variance weighting**, which gives more weight to reliable (low-noise) runs.

**Where does SE_r come from?**
For each run, `get_beta.m` computes the SE directly from the OLS residuals of that run's GLM:

```
residuals    = Y − X · β                            model residuals for this run
σ²           = Σ(residuals²) / (n − p)              residual variance per vertex
SE_r[v, f]   = √(σ²[v] · (X'X)⁻¹[f,f])             SE at vertex v for finger f
```

This gives a `[nVerts × nFingers]` matrix of standard errors per run — one SE value per vertex per finger, reflecting how noisy the beta estimate was in that specific run. Runs with more head motion, signal dropout, or generally poor model fit will have larger residuals, larger σ², and therefore larger SE — automatically down-weighted in the combination step.

**Combining across runs:**

For each finger at each vertex, across runs `r = 1 … R`:

```
weight_r     = 1 / SE_r²                               reliability weight for run r

β_combined   = Σ_r (β_r × weight_r) / Σ_r weight_r    weighted average beta

SE_combined  = 1 / √(Σ_r weight_r)                     combined standard error

t_combined   = β_combined / SE_combined                 t-statistic

df_total     = Σ_r (n_r − p_r)                         total degrees of freedom

p_value      = 2 × (1 − tcdf(|t_combined|, df_total))  two-tailed p-value
```

**Why inverse-variance weighting?**
A run with small SE (low noise, reliable estimate) gets a large weight; a noisy run gets a small weight. This is the statistically correct way to combine independent estimates — it is equivalent to what SPM's fixed-effects model achieves by concatenating all runs in one GLM.

**Numerical example (one vertex, one finger, 2 runs):**

```
Run 1:  β = 0.8,  SE = 0.4  →  weight = 1/0.16 = 6.25
Run 2:  β = 0.6,  SE = 0.2  →  weight = 1/0.04 = 25.0

β_combined  = (0.8×6.25 + 0.6×25.0) / (6.25 + 25.0) = 20.0 / 31.25 = 0.64
SE_combined = 1 / √31.25 = 0.179
t_combined  = 0.64 / 0.179 = 3.57
p_value     = 2 × (1 − tcdf(3.57, df1+df2))
```

The combined beta (0.64) is pulled toward the more reliable run 2 (0.60) rather than splitting the difference equally.

---

### Step 1.4 — Outputs Per Subject

Saved to `derivatives/Execution_fsavg6/sub-XXXX/ses-XX/` and `derivatives/Imagery_fsavg6/sub-XXXX/ses-XX/`:

```
lh.thumb.mgz          ← combined beta, left hemisphere
lh.thumb_tstat.mgz    ← combined t-statistic
lh.thumb_pval.mgz     ← two-tailed p-value
rh.thumb.mgz
rh.thumb_tstat.mgz
rh.thumb_pval.mgz
... (repeated for index, middle, ring, pinky; + sixth for Imagery)
```

Execution: 5 fingers × 2 hemis × 3 types = **30 files**
Imagery:   6 fingers × 2 hemis × 3 types = **36 files**

---

## Part 2 — `run_grouplevel.m`: Group Averaging and Fingermap

### Step 2.1 — Average Betas Across Subjects

For each task × session × hemisphere, per-subject combined betas are stacked and averaged:

```
betaAvg[v, f] = mean over subjects of β_combined[v, f]
```

T-stats are not used or saved at the group level — averaging t-stats across subjects is statistically invalid as each subject's t-stat depends on their own noise level and degrees of freedom. Sessions are kept separate throughout — no collapsing across sessions.

### Step 2.2 — Continuous Finger Preference Map

Betas are demeaned per vertex across fingers before computing the weighted average of finger IDs, preventing the midpoint bias (a vertex responding equally to all fingers scores 0, not 3):

```
β̃[v, f]      = β[v, f] − mean_f(β[v, :])       demean across fingers
bPos[v, f]    = max(β̃[v, f], 0)                 only above-average responses vote
fingermap[v]  = Σ_f (f · bPos[v,f]) / Σ_f bPos[v,f]   weighted average of finger IDs
```

### Step 2.3 — ROI Mask (HCP-MMP1 on fsaverage6)

The HCP-MMP1 annotation is loaded from `derivatives/freesurfer/fsaverage6/label/`. ROIs:
- **Execution** → `L_4_ROI` / `R_4_ROI` (primary motor cortex, M1)
- **Imagery**   → `L_3b_ROI` / `R_3b_ROI` (primary somatosensory cortex, S1)

### Step 2.4 — Outputs

Saved to `derivatives/group_fsavg6/Execution/ses-XX/` and `derivatives/group_fsavg6/Imagery/ses-XX/`:

```
lh.thumb.mgz            ← group-averaged beta
lh.index.mgz
lh.middle.mgz
lh.ring.mgz
lh.pinky.mgz
lh.fingermap.mgz        ← continuous finger preference map
rh.thumb.mgz
rh.index.mgz
rh.middle.mgz
rh.ring.mgz
rh.pinky.mgz
rh.fingermap.mgz
```

Execution: 5 fingers × 2 hemis + 2 fingermaps = **12 files per session**
Imagery:   6 fingers × 2 hemis + 2 fingermaps = **14 files per session**

---

## Part 3 — `run_grouplevel_WTA.m`: Winner-Takes-All Map

Reads group t-stats from `group_fsavg6/` and assigns each vertex the finger with the highest t-stat. Output saved to `derivatives/group_WTA_fsavg6/Task/ses-XX/lh.fingermap.mgz`.

---

## Visualisation

### View a single finger's beta map for one subject

```matlab
bidsDir = '/Users/hha243/Library/CloudStorage/Box-Box/sixthfinger-test';
fsHome  = '/Applications/freesurfer/8.1.0';

subID  = 'sub-0881';
ses    = 'ses-01';
task   = 'Execution';   % or 'Imagery'
finger = 'thumb';       % thumb, index, middle, ring, pinky (+ sixth for Imagery)
hemi   = 'lh';          % lh or rh

setenv('FREESURFER_HOME', fsHome);
setenv('SUBJECTS_DIR', fullfile(bidsDir, 'derivatives', 'freesurfer'));

surf    = fullfile(bidsDir, 'derivatives', 'freesurfer', 'fsaverage6', 'surf', [hemi '.inflated']);
overlay = fullfile(bidsDir, 'derivatives', [task '_fsavg6'], subID, ses, [hemi '.' finger '.mgz']);
fv      = fullfile(fsHome, 'bin', 'freeview');

cmd = sprintf('%s -f %s:overlay=%s:overlay_color=heat:overlay_threshold=0.5,3 &', fv, surf, overlay);
system(cmd);
```

### View a single finger's t-stat map for one subject

```matlab
overlay = fullfile(bidsDir, 'derivatives', [task '_fsavg6'], subID, ses, [hemi '.' finger '_tstat.mgz']);
cmd = sprintf('%s -f %s:overlay=%s:overlay_color=heat:overlay_threshold=2,8 &', fv, surf, overlay);
system(cmd);
```

### View a single finger's p-value map for one subject

P-values are stored as raw values (0 to 1). To show only significant vertices, threshold at 0.05:

```matlab
overlay = fullfile(bidsDir, 'derivatives', [task '_fsavg6'], subID, ses, [hemi '.' finger '_pval.mgz']);
% Note: threshold is inverted — show vertices where p < 0.05
% In FreeView, overlay_threshold hides values BELOW the min,
% so we need to view (1 - p) and threshold at 0.95, or view -log10(p)
% Easier: load in MATLAB and binarise
```

To visualise p-values it is easier to convert to `-log10(p)` first and view that:

```matlab
bidsDir = '/Users/hha243/Library/CloudStorage/Box-Box/sixthfinger-test';
fsHome  = '/Applications/freesurfer/8.1.0';
addpath(fullfile(fsHome, 'matlab'));

subID  = 'sub-0881';
ses    = 'ses-01';
task   = 'Execution';
finger = 'thumb';
hemi   = 'lh';

pvalFile = fullfile(bidsDir, 'derivatives', [task '_fsavg6'], subID, ses, [hemi '.' finger '_pval.mgz']);
outFile  = fullfile(bidsDir, 'derivatives', [task '_fsavg6'], subID, ses, [hemi '.' finger '_neglog10p.mgz']);

tmp     = MRIread(pvalFile);
pvals   = squeeze(tmp.vol);
neglogp = -log10(pvals);           % p=0.05 -> 1.3,  p=0.001 -> 3.0
tmp.vol = neglogp;
MRIwrite(tmp, outFile);

surf    = fullfile(bidsDir, 'derivatives', 'freesurfer', 'fsaverage6', 'surf', [hemi '.inflated']);
fv      = fullfile(fsHome, 'bin', 'freeview');
cmd = sprintf('%s -f %s:overlay=%s:overlay_color=heat:overlay_threshold=1.3,4 &', fv, surf, outFile);
system(cmd);
% overlay_threshold=1.3 corresponds to p < 0.05
% overlay_threshold=3.0 corresponds to p < 0.001
```

### View all five fingers' t-stat maps side by side (one subject)

```matlab
bidsDir = '/Users/hha243/Library/CloudStorage/Box-Box/sixthfinger-test';
fsHome  = '/Applications/freesurfer/8.1.0';

subID   = 'sub-0881';
ses     = 'ses-01';
task    = 'Execution';
hemi    = 'lh';
fingers = {'thumb', 'index', 'middle', 'ring', 'pinky'};

setenv('FREESURFER_HOME', fsHome);
setenv('SUBJECTS_DIR', fullfile(bidsDir, 'derivatives', 'freesurfer'));

surf = fullfile(bidsDir, 'derivatives', 'freesurfer', 'fsaverage6', 'surf', [hemi '.inflated']);
fv   = fullfile(fsHome, 'bin', 'freeview');

overlayStr = '';
for i = 1:numel(fingers)
    f = fingers{i};
    ovFile = fullfile(bidsDir, 'derivatives', [task '_fsavg6'], subID, ses, [hemi '.' f '_tstat.mgz']);
    overlayStr = [overlayStr sprintf(':overlay=%s:overlay_color=heat:overlay_threshold=2,8:overlay_name=%s', ovFile, f)];
end

cmd = sprintf('%s -f %s%s &', fv, surf, overlayStr);
system(cmd);
```

---

## Summary of Output Folders

| Folder | Contents | Created by |
|---|---|---|
| `derivatives/Execution_fsavg6/sub-XXXX/ses-XX/` | Per-subject beta, t-stat, p-value maps | `run_main.m` |
| `derivatives/Imagery_fsavg6/sub-XXXX/ses-XX/` | Per-subject beta, t-stat, p-value maps | `run_main.m` |
| `derivatives/group_fsavg6/Task/ses-XX/` | Group-averaged betas, t-stats, continuous fingermap | `run_grouplevel.m` |
| `derivatives/group_WTA_fsavg6/Task/ses-XX/` | Winner-takes-all fingermap | `run_grouplevel_WTA.m` |

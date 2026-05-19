# Sixthfinger fMRI Pipeline — Conceptual Report

A plain-English + formula reference for the full analysis pipeline, from raw BOLD data to group-level finger preference maps.

---

## Part 1 — `run_main.m`: First-Level GLM (Per Subject, Per Session)

### Goal
For each subject and session, estimate how strongly every point on the cortical surface responds to each individual finger, separately for Motor Execution and Motor Imagery tasks.

---

### Step 1.1 — Load BOLD Surface Data

fMRIPrep outputs the preprocessed BOLD signal as surface data — one value per cortical vertex (~150,000 vertices per hemisphere) per timepoint. Left and right hemispheres are stacked into a single matrix of ~300,000 vertices × ~300 timepoints per run. There are 8 runs total per session: 5 Imagery and 3 Execution, interleaved during scanning.

---

### Step 1.2 — Load Design Matrices and Noise Regressors

Two things are loaded per run:

**Design matrix** — a table with one row per timepoint and one column per finger, containing 1 when that finger was being used and 0 otherwise. This raw on/off signal is convolved with the **hemodynamic response function (HRF)** — a mathematical model of how the brain's blood flow responds to neural activity. Because blood flow peaks ~5 seconds after neural firing and decays over ~30 seconds, convolution "smears" the sharp on/off pattern into the expected slow BOLD shape.

**Noise regressors** — 11 columns of signals we want to remove: 6 rigid-body head motion parameters (3 translations, 3 rotations), global brain signal, white matter signal, CSF signal, a constant term, and a linear drift.

The scan order was interleaved (Imagery, Execution, Imagery, ...), so a mapping table is used to correctly pair each BOLD run with its corresponding design matrix file.

---

### Step 1.3 — General Linear Model (GLM)

The GLM is fit **independently at every vertex** (mass-univariate). At each vertex, the model states:

```
Y = X·β + ε
```

Where:
- `Y` — BOLD signal over time at this vertex [timepoints × 1], expressed as **percent signal change** (PSC): `(signal / mean − 1) × 100`. PSC normalization puts all vertices on the same scale regardless of baseline signal level.
- `X` — the full design matrix [timepoints × (nFingers + 11 noise regressors)]
- `β` — beta weights [one per column of X], the unknowns we solve for
- `ε` — residual error

Betas are estimated via **ordinary least squares (OLS)**:

```
β = (X'X)⁻¹ X' Y
```

The finger betas (first 5 or 6 columns) capture how strongly each finger drove the BOLD signal at this vertex. The noise betas capture variance explained by motion and physiological noise and are discarded.

---

### Step 1.4 — T-Statistics

A beta weight alone does not tell us how reliable the estimate is — a large beta from a noisy vertex is less trustworthy than a smaller beta from a clean vertex. The **t-statistic** normalises the beta by its standard error:

```
t = β / SE(β)
```

Where the standard error is derived from the residual variance of the model:

```
σ² = RSS / (n − p)         residual variance per vertex
SE(βⱼ) = √(σ² · (X'X)⁻¹ⱼⱼ)   standard error of the j-th beta
```

- `RSS` = sum of squared residuals (how much the model failed to explain)
- `n − p` = degrees of freedom (timepoints minus number of regressors)
- `(X'X)⁻¹ⱼⱼ` = the j-th diagonal of the model covariance matrix, reflecting how much information the data carries about that regressor

A t-statistic is computed for each finger at each vertex. Higher t = more reliable finger-specific activation.

---

### Step 1.5 — Averaging Across Runs and Saving

Beta weights and t-statistics are averaged across all runs of the same task (5 Imagery runs, 3 Execution runs). The result is one beta map and one t-stat map per finger per hemisphere, saved as compressed surface files (`.mgz`):

```
derivatives/
├── Execution/sub-XXXX/ses-XX/
│   ├── lh.thumb.mgz          ← average beta, left hemi
│   ├── lh.thumb_tstat.mgz    ← average t-stat, left hemi
│   └── ... (index, middle, ring, pinky × lh/rh)
└── Imagery/sub-XXXX/ses-XX/
    └── ... (thumb through sixth × lh/rh)
```

Execution has 5 fingers (thumb–pinky). Imagery has 6 (thumb–pinky + supernumerary sixth finger).

---

## Part 2 — `run_grouplevel.m`: Group Averaging and Continuous Finger Map

### Goal
Combine data across all subjects into a single group-level map per session, showing a **continuous** finger preference at each cortical vertex, visualizable on a common brain template.

---

### Step 2.1 — Resample to Common Space (fsnative → fsaverage)

Each subject's beta and t-stat maps live on their own cortical surface (fsnative) — a mesh of points specific to their brain shape. To average across subjects, everyone must be on the same surface. The standard template is **fsaverage** — a common spherical surface with 163,842 vertices per hemisphere.

Resampling uses FreeSurfer's `mri_surf2surf`, which aligns each subject's sphere to the fsaverage sphere and interpolates values accordingly. This is applied to both beta and t-stat maps for all fingers. The resampled files are saved in:

```
derivatives/Execution_fsavg/sub-XXXX/ses-XX/lh.thumb.mgz
derivatives/Execution_fsavg/sub-XXXX/ses-XX/lh.thumb_tstat.mgz
```

Sessions are kept separate throughout — no collapsing across sessions, so longitudinal changes remain visible.

---

### Step 2.2 — Average Across Subjects

For each task × session × hemisphere, all subjects' resampled beta maps are stacked and averaged:

```
betaAvg[v, f] = mean across subjects of β[v, f]
```

Where `v` = vertex (1…163,842), `f` = finger (1…5 or 6). Subjects missing a session (sub-0624 and sub-0883 have no ses-03) are simply excluded from that session's average.

Group-averaged t-stats are also computed and saved here — not for the continuous map, but as preparation for the WTA pipeline (Part 3), which reads them from the same `group/` folder:

```
tstatAvg[v, f] = mean across subjects of t[v, f]
```

Both are saved to `derivatives/group/Task/ses-XX/`.

---

### Step 2.3 — Continuous Finger Preference Map

Rather than assigning each vertex to a single finger (categorical), we compute a **continuous preference value** that reflects the relative tuning of the vertex across the finger space.

**Why not use raw betas directly?**
A vertex that responds equally to all fingers (noise or unspecific activation) would get a weighted average of `(1+2+3+4+5)/5 = 3.0` — the mathematical midpoint of the scale — which falsely appears as a "middle finger preference." To avoid this bias, betas are **demeaned per vertex** before computing the preference:

```
β̃[v, f] = β[v, f] − mean_f(β[v, :])
```

This removes the global response level, leaving only relative differences across fingers. A vertex responding equally to all fingers gets demeaned values of zero and is excluded from the map.

**Weighted average formula:**

```
bPos[v, f]    = max(β̃[v, f], 0)           only above-average responses vote
weightedSum   = Σ_f (f · bPos[v, f])       finger IDs: thumb=1, ..., pinky=5, sixth=6
totalWeight   = Σ_f bPos[v, f]
fingermap[v]  = weightedSum / totalWeight   continuous value in [1, 6]
```

A vertex that responds strongly to thumb and a little to index gets, for example:
```
weightedSum = 1×0.8 + 2×0.3 = 1.4
totalWeight = 0.8 + 0.3     = 1.1
fingermap   = 1.4 / 1.1     ≈ 1.27  (closer to thumb than index)
```

Vertices where all demeaned betas are zero or negative get `fingermap = 0` (excluded).

---

### Step 2.4 — Anatomical ROI Mask

The finger preference map is masked to the anatomically relevant region using the **HCP-MMP1 atlas (Glasser et al., 2016)**, which parcellates the cortex into 360 areas. The atlas is applied directly on fsaverage (no per-subject projection needed since the map is already in fsaverage space).

- **Execution** → masked to `L_4_ROI` / `R_4_ROI` — **primary motor cortex (M1)**
- **Imagery** → masked to `L_6mp_ROI` / `R_6mp_ROI` — **SMA proper** (posterior medial BA6)

All vertices outside the ROI are set to 0. The result captures only the finger layout within the cortical region of interest.

---

### Output

```
derivatives/group/Task/ses-XX/
├── lh.thumb.mgz            ← group-averaged beta
├── lh.thumb_tstat.mgz      ← group-averaged t-stat
├── ...
└── lh.fingermap.mgz        ← continuous finger preference map (weighted average)
```

---

## Part 3 — `run_grouplevel_WTA.m`: Winner-Takes-All Finger Map

### Goal
Produce an alternative finger preference map using a **winner-takes-all (WTA)** approach, following the method of Kikkert et al. (2021, *Human Brain Mapping*). Each vertex is assigned the single finger whose average t-statistic is highest — a discrete, categorical label rather than a continuous value.

---

### Method

For each vertex inside the ROI, the finger with the maximum group-averaged t-statistic wins:

```
fingermap[v] = argmax_f ( tstatAvg[v, f] )
```

Values are integer finger labels: 1 = thumb, 2 = index, 3 = middle, 4 = ring, 5 = pinky (6 = sixth for Imagery).

**Why t-statistics instead of betas?**
The t-statistic normalises the beta by its standard error. A vertex with a high beta but also high noise gets a lower t-score than a vertex with a slightly smaller but highly reliable beta. Using t-scores therefore gives more weight to reliable, consistent activations than to noisy peaks — which is especially important for WTA, where a single "winning" finger is assigned with no uncertainty expressed.

**Why no functional threshold?**
The paper used an F-contrast to pre-screen voxels that respond to at least one finger. We do not apply an equivalent threshold here because: (1) group-averaged betas and t-stats do not show a clear bimodal distribution separating noise from signal — averaging across subjects compresses the dynamic range; and (2) the anatomical ROI mask (M1 / SMA) already restricts the map to cortex expected to contain finger representations.

---

### Comparison with the Continuous Map

| | Weighted Average (`run_grouplevel.m`) | Winner-Takes-All (`run_grouplevel_WTA.m`) |
|---|---|---|
| Input | Group-averaged betas | Group-averaged t-stats |
| Output | Continuous value (e.g. 1.27) | Discrete integer (e.g. 1) |
| Sensitivity | Reflects graded tuning | Reflects dominant finger only |
| Bias | None after demeaning | None — takes max |
| Paper equivalent | Phase-encoding approaches | Kikkert et al. (2021) |

---

### Output

```
derivatives/group_WTA/Task/ses-XX/
├── lh.fingermap.mgz    ← integer finger label (1-5 or 1-6), 0 outside ROI
└── rh.fingermap.mgz
```

---

## Visualisation

Both maps are viewed on the fsaverage inflated surface in FreeView:

```
overlay_threshold = 1, 5       (or 1, 6 for Imagery)
overlay_color     = colorwheel, inverse
```

Expected color layout along the hand knob (lateral → medial along precentral gyrus):

| Finger | Value | Color |
|--------|-------|-------|
| Thumb  | 1 | Red |
| Index  | 2 | Yellow-orange |
| Middle | 3 | Green |
| Ring   | 4 | Cyan |
| Pinky  | 5 | Blue |
| Sixth (Imagery only) | 6 | Violet |

The classic somatotopic gradient (thumb lateral, pinky medial) should produce a red-to-blue sweep across the hand knob.

---

## Summary of Outputs

| Folder | Contents | Created by |
|---|---|---|
| `derivatives/Execution/` | Per-subject beta + t-stat maps (fsnative) | `run_main.m` |
| `derivatives/Imagery/` | Per-subject beta + t-stat maps (fsnative) | `run_main.m` |
| `derivatives/Execution_fsavg/` | Per-subject resampled maps (fsaverage) | `run_grouplevel.m` Step 1 |
| `derivatives/Imagery_fsavg/` | Per-subject resampled maps (fsaverage) | `run_grouplevel.m` Step 1 |
| `derivatives/group/` | Group-averaged betas, t-stats, continuous fingermap | `run_grouplevel.m` Steps 2–5 |
| `derivatives/group_WTA/` | Winner-takes-all fingermap | `run_grouplevel_WTA.m` |

---

## Visualisation Code Snippets

Run these in MATLAB. Change `task`, `ses`, and `hemi` to inspect any combination.

### Part 2 — Continuous Weighted Average Map

```matlab
bidsDir = '/Users/hha243/Library/CloudStorage/Box-Box/sixthfinger-test';
fsHome  = '/Applications/freesurfer/8.1.0';

task = 'Execution';   % or 'Imagery'
ses  = 'ses-01';      % or 'ses-02', 'ses-03'
hemi = 'lh';          % or 'rh'

% threshold: 1 to 5 for Execution, 1 to 6 for Imagery
thresh_max = 5;       % change to 6 for Imagery

setenv('FREESURFER_HOME', fsHome);
setenv('SUBJECTS_DIR', fullfile(bidsDir, 'derivatives', 'freesurfer'));

surf    = fullfile(bidsDir, 'derivatives', 'freesurfer', 'fsaverage', 'surf', [hemi '.inflated']);
overlay = fullfile(bidsDir, 'derivatives', 'group', task, ses, [hemi '.fingermap.mgz']);
fv      = fullfile(fsHome, 'bin', 'freeview');

cmd = sprintf('%s -f %s:overlay=%s:overlay_color=colorwheel,inverse:overlay_threshold=1,%d &', ...
    fv, surf, overlay, thresh_max);
system(cmd);
```

### Part 3 — Winner-Takes-All Map

```matlab
bidsDir = '/Users/hha243/Library/CloudStorage/Box-Box/sixthfinger-test';
fsHome  = '/Applications/freesurfer/8.1.0';

task = 'Execution';   % or 'Imagery'
ses  = 'ses-01';      % or 'ses-02', 'ses-03'
hemi = 'lh';          % or 'rh'

thresh_max = 5;       % change to 6 for Imagery

setenv('FREESURFER_HOME', fsHome);
setenv('SUBJECTS_DIR', fullfile(bidsDir, 'derivatives', 'freesurfer'));

surf    = fullfile(bidsDir, 'derivatives', 'freesurfer', 'fsaverage', 'surf', [hemi '.inflated']);
overlay = fullfile(bidsDir, 'derivatives', 'group_WTA', task, ses, [hemi '.fingermap.mgz']);
fv      = fullfile(fsHome, 'bin', 'freeview');

cmd = sprintf('%s -f %s:overlay=%s:overlay_color=colorwheel,inverse:overlay_threshold=1,%d &', ...
    fv, surf, overlay, thresh_max);
system(cmd);
```

### Viewing Both Side by Side

```matlab
bidsDir = '/Users/hha243/Library/CloudStorage/Box-Box/sixthfinger-test';
fsHome  = '/Applications/freesurfer/8.1.0';

task = 'Execution';
ses  = 'ses-01';
hemi = 'lh';

setenv('FREESURFER_HOME', fsHome);
setenv('SUBJECTS_DIR', fullfile(bidsDir, 'derivatives', 'freesurfer'));

surf       = fullfile(bidsDir, 'derivatives', 'freesurfer', 'fsaverage', 'surf', [hemi '.inflated']);
overlay_wa = fullfile(bidsDir, 'derivatives', 'group',     task, ses, [hemi '.fingermap.mgz']);
overlay_wt = fullfile(bidsDir, 'derivatives', 'group_WTA', task, ses, [hemi '.fingermap.mgz']);
fv         = fullfile(fsHome, 'bin', 'freeview');

% Opens one FreeView window with both overlays loaded — toggle between them
% using the overlay panel on the left
cmd = sprintf(['%s -f %s' ...
    ':overlay=%s:overlay_color=colorwheel,inverse:overlay_threshold=1,5:overlay_name=WeightedAvg' ...
    ':overlay=%s:overlay_color=colorwheel,inverse:overlay_threshold=1,5:overlay_name=WTA &'], ...
    fv, surf, overlay_wa, overlay_wt);
system(cmd);
```

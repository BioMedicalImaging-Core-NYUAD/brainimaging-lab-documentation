# RSA Pipeline Report
**Project:** Sixth Finger | **Last updated:** 2026-05-03

---

## Overview

The RSA (Representational Similarity Analysis) pipeline characterises how the brain represents individual finger movements in primary motor (M1) and somatosensory (S1) cortex. It proceeds in four major stages:

1. **First-level GLM** — estimate per-finger BOLD response at every vertex within an anatomical ROI, for every run of every session of every subject.
2. **ROI Definition via F-contrast + Winner-Takes-All** — identify which vertices are functionally responsive to fingers and assign each to its preferred finger. Two ROI variants are saved per subject: ses-01 only and all-sessions pooled.
3. **Crossnobis RDM computation** — compute a representational dissimilarity matrix (RDM) per subject/session/task using crossvalidated Mahalanobis distance within a chosen functional or anatomical ROI.
4. **Visualization** — group MDS plots, per-subject MDS plots for outlier inspection, and RDM heatmaps.

---

## Stage 1 — First-Level GLM

### 1.1 Design Matrix Construction — `load_dsm_rsa.m`

**What it does:**
Builds the GLM design matrix for each run, including HRF-convolved finger regressors, their temporal derivatives, and nuisance regressors.

**Inputs:**

| Variable | Description |
|---|---|
| `dataLog` | Table: subject, session, task, run |
| `dmBaseDir` | Path to behavioural design matrix directory |
| `dmNum` | Subject-specific design matrix number |
| `bidsDir` | Project root directory |

**Processing:**
- Reads raw onset timing files (`.csv`) for each run
- Convolves each finger condition with the SPM canonical HRF (TR = 1 s)
- Appends temporal derivatives using forward finite differences — these capture any mismatch between the canonical HRF shape and the actual BOLD response
- Builds nuisance matrix: constant, linear drift, 6 motion parameters, framewise displacement (FD), top 5 aCompCor components, and one-hot scrubbing regressors for any timepoint where FD > 0.5 mm (number of scrubbing columns varies per run)

**Outputs:**

| Variable | Dimensions | Contents |
|---|---|---|
| `dsm` | `{1 × nRuns}` each `[nTRs × 2*nFingers]` | Columns 1:nFingers = HRF-convolved conditions; columns nFingers+1:2*nFingers = temporal derivatives |
| `myNoise` | `{1 × nRuns}` each `[nTRs × nNoise]` | constant, drift, 6 motion, FD, 5 aCompCor, scrubbing one-hots |

**Task sizes:**

| Task | Runs | nFingers | TRs/run |
|---|---|---|---|
| Execution | 3 | 5 (thumb–pinky) | 372 |
| Imagery | 5 | 6 (thumb–sixth) | 300 |

---

### 1.2 GLM Fitting — `get_beta_rsa.m`

**What it does:**
Fits the GLM at every cortical vertex for every run. Returns raw (not contrast-coded) betas, residuals, standard errors, and the components needed for an exact omnibus F-test.

**Inputs:**

| Variable | Dimensions | Contents |
|---|---|---|
| `datafiles` | `{1 × nRuns}` each `[nVerts × nTRs]` | BOLD timeseries in percent signal change |
| `dsm` | `{1 × nRuns}` each `[nTRs × 2*nFingers]` | From `load_dsm_rsa` |
| `myNoise` | `{1 × nRuns}` each `[nTRs × nNoise]` | From `load_dsm_rsa` |

**Processing (per run):**

**Step A — Percent signal change conversion:**
```
Y = ((BOLD / mean(BOLD)) - 1) × 100       [nVerts × nTRs]
```

**Step B — OLS regression (full model):**
```
X        = [dsm | myNoise]                 [nTRs × (2*nFingers + nNoise)]
XtXinv   = inv(X'X)
betas    = (XtXinv * X' * Y')'            [nVerts × nRegressors]
residuals = Y - X * betas'                [nVerts × nTRs]
```
Only the first nFingers columns of betas are kept — these are the canonical HRF finger responses. Temporal derivative and nuisance betas are discarded.

**Step C — Standard errors per condition:**
```
df     = nTRs - rank(X)                    accounts for scrubbing exactly
sigma2 = sum(residuals²) / df             [nVerts × 1]  residual variance per vertex
SE     = sqrt(sigma2 × diag(XtXinv)(1:nFingers)')     [nVerts × nFingers]
```
The diagonal of (X'X)⁻¹ gives the variance inflation per regressor. Multiplying by the residual variance gives the SE for each finger condition independently.

**Step D — Exact omnibus F-test components:**

The F-test asks: *"Do the canonical HRF finger regressors explain significant variance beyond the temporal derivatives and nuisance regressors?"*

To answer this, we solve for beta **twice** — once for each model — then compare how much unexplained variance each leaves behind:

```
Full model:    Y = fingers + derivatives + nuisance + error
Reduced model: Y =           derivatives + nuisance + error
```

**Solve full model → compute RSS_full:**
Fit all regressors (fingers + derivatives + nuisance), compute residuals (Y − Ŷ), then sum their squares over time at each vertex:
```
RSS_full = sum(residuals_full², over time)          [nVerts × 1]
```

**Solve reduced model → compute RSS_reduced:**
Fit only derivatives + nuisance (no finger regressors), compute residuals, sum squares:
```
X_red        = [dsm(:, nFingers+1:end) | myNoise]   derivatives + nuisance only
RSS_reduced  = sum(residuals_reduced², over time)    [nVerts × 1]
```

**Compute SS_model:**
The difference tells you how much variance the finger regressors specifically accounted for — variance the reduced model could not explain but the full model could:
```
SS_model = RSS_reduced - RSS_full                    [nVerts × 1]
```
If fingers explain nothing, both models fit equally badly and SS_model ≈ 0. If fingers capture real signal, RSS_full drops below RSS_reduced and SS_model is large.

The reduced model intentionally retains the temporal derivatives. This is a deliberate design choice: derivatives capture HRF shape variation and will explain some variance at almost every cortical vertex. Including them in the reduced model means the F-test only credits variance that the canonical finger regressors explain *on top of* HRF shape correction — a more conservative and interpretable test than comparing against nuisance alone. Without this fix, ~96% of anatomical ROI vertices survived p < 0.0001 because derivatives alone inflated SS_model at nearly every vertex.

**Outputs:**

| Variable | Dimensions | Contents |
|---|---|---|
| `raw_betas` | `{1 × nRuns}` each `[nVerts × nFingers]` | Raw OLS beta per finger per vertex |
| `residuals` | `{1 × nRuns}` each `[nVerts × nTRs]` | GLM residuals — used in crossnobis precision matrix |
| `SEs` | `{1 × nRuns}` each `[nVerts × nFingers]` | Per-condition standard errors |
| `Finfo.SS_model` | `{1 × nRuns}` each `[nVerts × 1]` | Model sum of squares per run |
| `Finfo.SS_resid` | `{1 × nRuns}` each `[nVerts × 1]` | Residual sum of squares (full model) per run |
| `Finfo.df_num` | scalar | nFingers (numerator df) |
| `Finfo.df_denom` | `[1 × nRuns]` | Exact denominator df per run (nTRs − rank(X)) |

---

### 1.3 Combining Across Runs and Saving — `run_glm_rsa.m`

**What it does:**
Orchestrates the full pipeline across all subjects, sessions, and tasks. Applies the anatomical ROI mask, combines estimates across runs, and saves outputs.

**Anatomical masking:**
Before any data is loaded, a binary mask is built per subject from Glasser 2016 parcellation labels for left hemisphere M1/S1: Areas **4, 3a, 3b, 1, 2**. Only vertices inside this mask (`roi_idx`) are retained — everything else is discarded to save memory.

**Precision-weighted beta combination across runs:**

Runs are combined using inverse-variance (precision) weighting — runs with lower noise contribute more:
```
precision        = 1 / SE²                          per vertex per finger per run
beta_combined    = Σ(precision × beta) / Σ(precision)   [nROI × nFingers]
se_combined      = sqrt(1 / Σ(precision))                [nROI × nFingers]
t_combined       = beta_combined / se_combined            [nROI × nFingers]
```

**F-stat pooling across runs:**

SS components are summed across runs *before* dividing — averaging F-stats directly across runs is statistically incorrect:
```
SS_model_total = Σ_runs SS_model              [nROI × 1]
SS_resid_total = Σ_runs SS_resid              [nROI × 1]
df_num_total   = nFingers × nRuns             scalar
df_denom_total = Σ_runs df_denom             scalar (exact, accounts for scrubbing)

F_combined = (SS_model_total / df_num_total) / (SS_resid_total / df_denom_total)
p_combined = 1 - fcdf(F_combined, df_num_total, df_denom_total)
```

**Expected degrees of freedom:**

| Task | df_num | df_denom (range due to scrubbing) |
|---|---|---|
| Execution (3 runs, 372 TRs/run) | 15 | ~894 – 1038 |
| Imagery (5 runs, 300 TRs/run) | 30 | ~1120 – 1360 |

At these df values, F values to expect per vertex:
- Unresponsive vertex: F ≈ 0–2 (near null)
- Borderline: F ≈ 2–5
- Clearly finger-responsive: F ≈ 5–20
- Strong hand knob response: F ≈ 20–100+

**Files saved per subject / session / task:**

```
derivatives/RSA/<subID>/<ses>/
├── Execution_betas.mat       betas_allruns {1×3} [nROI × 5],  roi_idx
├── Execution_residuals.mat   residuals_allruns {1×3} [nROI × nTRs], roi_idx
├── Execution_SEs.mat         SEs_allruns {1×3} [nROI × 5], roi_idx
├── Execution_combined.mat    beta/se/t_combined [nROI × 5]
│                             F_combined, p_combined [nROI × 1]
│                             SS_model_total, SS_resid_total [nROI × 1]
│                             df_num_total, df_denom_total (scalars), roi_idx
├── Imagery_betas.mat         same structure, {1×5}, [nROI × 6]
├── Imagery_residuals.mat
├── Imagery_SEs.mat
└── Imagery_combined.mat
```

---

## Stage 2 — ROI Definition via F-contrast + Winner-Takes-All

### `define_roi_wta.m`

**What it does:**
Loops over all subjects. For each subject, defines two functional ROI variants by pooling Execution GLM outputs and applying F-threshold + Winner-Takes-All:

- **`Execution_ses01_WTA.mat`** — uses ses-01 data only
- **`Execution_allses_WTA.mat`** — pools all available sessions (subjects with 2 sessions use 2; with 3 sessions use 3)

Both are saved to the same location: `derivatives/RSA/<subID>/ROI/`

**Threshold:** p < 1e-8 (uncorrected)

**Inputs (loaded from `_combined.mat` per session):**

| Variable | Dimensions | Contents |
|---|---|---|
| `SS_model_total` | `[nROI × 1]` | Model SS (pooled across runs within session) |
| `SS_resid_total` | `[nROI × 1]` | Residual SS (pooled across runs within session) |
| `df_num_total` | scalar | Numerator df for this session |
| `df_denom_total` | scalar | Denominator df for this session |
| `beta_combined` | `[nROI × nFingers]` | Precision-weighted betas |
| `se_combined` | `[nROI × nFingers]` | Combined SEs |
| `roi_idx` | `[nROI × 1]` | Vertex indices in the anatomical mask |

**Processing:**

**Step 1 — Pool F across sessions (for allses variant):**
SS components are accumulated across sessions before computing F — same principle as pooling across runs:
```
SS_model_allses = Σ_sessions SS_model_total       [nROI × 1]
SS_resid_allses = Σ_sessions SS_resid_total       [nROI × 1]
df_num_allses   = Σ_sessions df_num_total         scalar
df_denom_allses = Σ_sessions df_denom_total       scalar

F_combined = (SS_model_allses / df_num_allses) / (SS_resid_allses / df_denom_allses)
p_combined = 1 - fcdf(F_combined, df_num_allses, df_denom_allses)
```
For the ses-01 variant, only that session's values are used (no accumulation).

**Step 2 — F-threshold:**
```
active_mask = p_combined < p_thresh            [nROI × 1] logical
```

**Step 3 — Precision-weighted t across sessions (for WTA):**
```
prec             = 1 / se_combined²
beta_combined    = Σ(prec × beta) / Σ(prec)   [nROI × nFingers]
t_combined       = beta_combined / sqrt(1/Σ(prec))
```

**Step 4 — Winner-Takes-All:**
```
[max_t, wta_idx] = max(t_combined, [], 2)      peak finger per vertex

wta_map = 0  (unassigned by default)
wta_map = wta_idx  where: active_mask AND max_t > 0
```
The `max_t > 0` guard excludes vertices where all fingers cause deactivation.

**Step 5 — Project to full surface and save Freeview overlays:**
Results are placed back into full LH surface arrays using `roi_idx` for display in Freeview.

**Outputs (saved to `derivatives/RSA/<subID>/ROI/`):**

```
ROI/
├── Execution_ses01_WTA.mat          wta_map, active_mask, roi_idx, F, p, df
├── Execution_allses_WTA.mat         same, pooled across all sessions
├── lh.Execution_ses01_Fmap.mgh
├── lh.Execution_ses01_neglog10p.mgh
├── lh.Execution_ses01_WTA.mgh
├── lh.Execution_allses_Fmap.mgh
├── lh.Execution_allses_neglog10p.mgh
└── lh.Execution_allses_WTA.mgh
```

**Viewing overlays:** `view_roi_wta.m` — set `subNum` at the top, launches Freeview on `lh.inflated` with F-map, −log₁₀(p), and WTA overlays.

---

## Stage 3 — Crossnobis RDM Computation

### `compute_crossnobis_rdm.m`

**What it does:**
For each subject × session × task, computes a crossvalidated Mahalanobis (crossnobis) RDM within a chosen ROI. The result is a symmetric dissimilarity matrix where each cell (i, j) captures how different the brain's spatial pattern for finger i is from finger j — independent of noise.

**ROI mode (set `roiMode` at top of script):**

| Mode | ROI source | Vertices used | Output tag |
|---|---|---|---|
| 1 | `ROI/Execution_ses01_WTA.mat` | F-threshold + WTA from ses-01 only | `ses01WTA` |
| 2 | `ROI/Execution_allses_WTA.mat` | F-threshold + WTA pooled across all sessions | `allsesWTA` |
| 3 | `ROI/Execution_allses_WTA.mat` (for `roi_idx` only) | All Glasser M1/S1 vertices, no WTA filter | `anatROI` |

The same ROI mask is applied to both Execution and Imagery sessions — the ROI is always derived from Execution, then used consistently for both tasks.

---

### What is an RDM?

An RDM (Representational Dissimilarity Matrix) answers: *"How different is the brain's representation of finger A from finger B?"*

For Execution (5 fingers) the result is a 5×5 matrix. The diagonal is always 0 (a pattern compared to itself). Off-diagonal values are distances — larger values mean more distinct representations.

```
         thumb  index  middle  ring  pinky
thumb  [  0      d      d       d      d  ]
index  [  d      0      d       d      d  ]
middle [  d      d      0       d      d  ]
ring   [  d      d      d       0      d  ]
pinky  [  d      d      d       d      0  ]
```

---

### Why crossnobis (not regular Euclidean distance)?

Two problems arise with simple Euclidean distance between finger patterns:

**Problem 1 — Noise bias:** If you compare finger i and finger j from the *same run*, any noise that happened during that run inflates the distance. You'd be measuring noise as much as signal.

**Solution — Cross-validation (leave-one-run-out):** Compare the pattern for finger i from run r against the pattern for finger j from all *other* runs. Because the two patterns come from independent measurements, noise does not systematically inflate the distance — it averages to ~0. This is the "cross" in crossnobis.

**Problem 2 — Unequal noise across vertices:** Some vertices are noisier than others. Euclidean distance treats all vertices equally, so noisy vertices dominate.

**Solution — Mahalanobis distance:** Normalize by the noise covariance structure estimated from GLM residuals. Noisy vertices are down-weighted; correlations between vertices are accounted for. This is the "nobis" (Mahalanobis) part.

Together: **crossnobis = leave-one-run-out cross-validation + Mahalanobis noise normalization.**

---

### Step-by-step procedure

**Step 1 — Build ROI mask:**
Load the appropriate WTA file per `roiMode`. `roi_mask` is a `[nROI × 1]` logical vector indexing into the rows of `betas_allruns` (which are already restricted to Glasser M1/S1 vertices).

**Step 2 — Run-wise noise normalization (prewhitening):**
For each run separately, the noise covariance is estimated from the GLM residuals and used to prewhiten the betas. Run-wise (rather than overall) normalization is used because noise characteristics can vary across runs due to motion, scanner drift, and physiology.

```
Σ_r  = residuals_r × residuals_r' / (nTRs - 1)    [nROI × nROI]  sample covariance
Σ_r  = Ledoit-Wolf regularisation                  prevents rank deficiency
Σ_r^(-1/2) via eigendecomposition
B_white_r = B_r × Σ_r^(-1/2)                       [nFingers × nROI] prewhitened betas
```

**Why Ledoit-Wolf regularisation?** The number of ROI vertices can approach or exceed the number of TRs per run, making the raw covariance matrix rank-deficient (singular). Ledoit-Wolf analytically shrinks the sample covariance toward a scaled identity matrix — down-weighting noisy off-diagonal covariances while preserving the overall scale. The optimal shrinkage coefficient λ is computed analytically from the data.

**Step 3 — Stack and label betas across runs:**
```
B_all        = [B_white_run1; B_white_run2; ...]   [nRuns×nFingers × nROI]
partition    = [1,1,...,1, 2,2,...,2, ...]          run index per row
conditionVec = [1,2,...,5, 1,2,...,5, ...]          finger index per row
```

**Step 4 — Crossnobis distance via `rsa.distanceLDC`:**
The RSAtoolbox function implements leave-one-run-out crossvalidation internally. For each pair of conditions (i, j) and each fold (left-out run r):

```
distance_r = (beta_i_r - beta_j_r) · Σ^(-1) · (beta_i_notR - beta_j_notR)
```

Distances are averaged across folds. **Values can be negative** — this is expected and correct for an unbiased estimator. A value near 0 means the two finger patterns are indistinguishable from noise; a large positive value means they are reliably distinct.

**Step 5 — Build symmetric RDM matrix:**
```
RDM(i,j) = RDM(j,i) = d_vec(pair_index)    [nFingers × nFingers]
```
Built manually (not via `squareform`) to correctly handle negative crossnobis values.

---

### Inputs

| Variable | Source | Dimensions |
|---|---|---|
| `betas_allruns` | `<task>_betas.mat` | `{1 × nRuns}` each `[nROI × nFingers]` |
| `residuals_allruns` | `<task>_residuals.mat` | `{1 × nRuns}` each `[nROI × nTRs]` |
| `roi_mask` | `ROI/Execution_<roiTag>_WTA.mat` | `[nROI × 1]` logical |

---

### Outputs

One file per subject / session / task, named with the ROI tag:

```
derivatives/RSA/<subID>/<ses>/
├── Execution_RDM_<roiTag>.mat    RDM [5×5], d_vec [1×10], fingerNames, nROI, roi_mask, roiTag
└── Imagery_RDM_<roiTag>.mat      RDM [6×6], d_vec [1×15], fingerNames, nROI, roi_mask, roiTag
```

**Total files (allsesWTA):** 56 RDM files across all subjects/sessions/tasks.

---

## Stage 4 — Visualization

All three plotting scripts share a `roiTag` user setting at the top — set it to match the RDM files you want to visualize (`ses01WTA`, `allsesWTA`, or `anatROI`).

### 4.1 RDM Heatmaps — `plot_rdm.m`

**User settings:** `subNum` (e.g. `'0457'`), `roiTag`

Plots RDMs for one subject across all available sessions and both tasks. Layout: rows = tasks, columns = sessions. Each heatmap uses a shared color scale within each task row so distances are comparable across sessions. Color map: blue–white–red (diverging, zero = white).

---

### 4.2 Group MDS — `plot_mds.m`

**User setting:** `roiTag`

For each session × task panel (up to 6 panels in a 2×3 grid):

1. Shifts each subject's RDM so all off-diagonal values are positive (adds `|min| + ε` if any are negative), then normalizes to mean off-diagonal = 1
2. Classical MDS per subject → 2D finger coordinates (`cmdscale` handles negative eigenvalues; takes first 2 dimensions)
3. **Within-session Procrustes:** aligns all subjects to subject 1 (rotation/reflection only, no scaling)
4. **Cross-session Procrustes:** aligns ses-02 and ses-03 group means to ses-01 group mean, applies the same transform to all individual subjects — removes arbitrary orientation differences across sessions while preserving true geometry changes
5. Plots group mean dots + 1 SEM ellipses per finger

Axes are shared across all panels for direct comparison.

---

### 4.3 Per-Subject MDS — `plot_mds_individual.m`

**User setting:** `roiTag`

Produces one PNG per subject saved to `derivatives/RSA/QC/MDS_individual/`. Layout: rows = tasks, columns = sessions.

- Applies the same negative-value shift and normalization as the group script
- **Cross-session Procrustes** aligns ses-02 and ses-03 to ses-01 within each task, so session-to-session changes in finger geometry are interpretable
- Prints a summary table of 2D variance explained per panel — low values (< 50%) flag poor MDS representations worth inspecting
- Axis range is consistent across all panels for each subject

---

## Key Design Decisions

| Decision | Rationale |
|---|---|
| Raw betas (not contrast-coded) | RSA requires distances between all finger patterns — contrast coding would distort the geometry |
| Temporal derivatives in reduced model | Prevents inflated F-stats; without this, ~96% of anatomical ROI vertices survived p < 0.0001 because derivatives alone captured HRF shape variance at almost every vertex |
| Pool SS before computing F | Statistically correct way to combine F across runs or sessions; averaging F-stats directly is not valid |
| Exact df via rank(X) | Automatically accounts for variable scrubbing regressors per run; no approximation needed |
| Precision-weighted beta combination | Runs/sessions with lower noise contribute more; more efficient than simple averaging |
| WTA requires max_t > 0 | Prevents assigning vertices to fingers they are deactivated by |
| Two WTA ROI variants saved | ses-01 only provides an uncontaminated pre-training ROI; all-sessions pooled maximises statistical power for ROI definition |
| ROI applied to both tasks | ROI defined from Execution and reused for Imagery — ensures consistent vertex set across all comparisons |
| Crossnobis can be negative | Expected for an unbiased estimator; values near 0 mean indistinguishable patterns, not a computation error |
| Run-wise prewhitening | Noise properties vary across runs; run-wise normalization is more accurate than pooling residuals |
| Ledoit-Wolf regularisation | nROI vertices can approach nTRs per run, making raw covariance singular; LW shrinkage ensures invertibility |
| Cross-session Procrustes in MDS | MDS orientation is arbitrary; aligning ses-02/ses-03 to ses-01 makes session-to-session geometry changes interpretable |
| No cross-task Procrustes | Execution (5 fingers) and Imagery (6 fingers) have different dimensionality; forcing a common orientation would impose an assumption about task similarity that is itself a scientific question |

---

## Current Status

All four stages are complete:
- **Stage 1** (`run_glm_rsa.m`) — GLM fit, betas, SEs, residuals, and F-stats saved for all subjects/sessions/tasks
- **Stage 2** (`define_roi_wta.m`) — Both `ses01` and `allses` WTA ROI files saved for all 10 subjects under `derivatives/RSA/<subID>/ROI/`
- **Stage 3** (`compute_crossnobis_rdm.m`) — 56 RDM files saved (allsesWTA); ses01WTA and anatROI variants can be generated by changing `roiMode`
- **Stage 4** — Group MDS, per-subject MDS QC plots, and RDM heatmaps implemented; all scripts accept `roiTag` to select which RDM variant to visualize

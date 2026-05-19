# Sixthfinger Pipeline — Code Walkthrough Report

A reference guide summarizing how each file in the pipeline works, based on our Q&A session.

---

## 1. `run_main.m` — The Batch Manager

**What it does in plain English:**
`run_main.m` is the batch manager for your entire fMRI finger-mapping pipeline. It reads `map.json` (which lists all 10 subjects, their sessions, and design matrix numbers), loops through every subject × session, figures out which design matrix folder to use, and hands off the real work to `process_subject_fingermap()`. If something crashes for one subject, it logs the error and moves on.

**Key steps:**
1. **Clean slate** — `clear all; close all; clc`
2. **Add to path** — FreeSurfer 8.1.0 MATLAB functions + SPM
3. **Read `map.json`** — gets the list of subjects, their dmNum, sessions, and the session→directory mapping (`ses-01` → `fmri_pre_dm`, etc.)
4. **Loop subjects × sessions** — for each combo:
   - Look up which dm folder to use (e.g., `fmri_post_gap_dm` for `ses-03`)
   - Check that the dm folder actually exists (skip if missing)
   - Call `process_subject_fingermap(subID, ses, dmNum, dmBaseDir, bidsDir, codeDir)`
   - Wrap in `try/catch` so one failure doesn't stop the batch

---

## 2. `process_subject_fingermap.m` — Single Subject Pipeline

**What it does in plain English:**
Takes one subject's one session and produces finger activation maps. It loads fMRI data, loads the experimental design, runs a GLM, and saves the resulting beta maps as `.mgz` files.

**Key steps:**
1. **Build `dataLog` table** — 8 rows (5 Imagery + 3 Execution runs), columns: subject, session, task, run
2. **`load_dataLog()`** — loads BOLD surface data for all 8 runs
3. **`load_dsm()`** — loads design matrices + noise regressors for all 8 runs
4. **`get_beta()`** — runs the GLM, returns beta weights per vertex per condition
5. **Find FreeSurfer directory** — locates this subject's surfaces
6. **Get hemisphere split** — uses `read_curv` to know where left ends and right begins
7. **Per task (Imagery / Execution):**
   - Average betas across runs for each finger
   - Split into L/R hemispheres
   - Save as `.mgz` files

**Output files per session:**
- **Imagery**: 12 files (6 fingers × 2 hemispheres) — `lh.thumb.mgz` through `rh.sixth.mgz`
- **Execution**: 10 files (5 fingers × 2 hemispheres) — `lh.thumb.mgz` through `rh.pinky.mgz`

> **Important:** Imagery has **6 conditions** (5 regular fingers + the 6th finger). Execution has only **5**. The code handles this dynamically — `fingerNames_imagery` has 6 entries, `fingerNames_execution` has 5.

### The `dataLog` Table

| Row | subject | session | task | run |
|-----|---------|---------|------|-----|
| 1 | sub-0872 | ses-01 | Imagery | 1 |
| 2 | sub-0872 | ses-01 | Imagery | 2 |
| 3 | sub-0872 | ses-01 | Imagery | 3 |
| 4 | sub-0872 | ses-01 | Imagery | 4 |
| 5 | sub-0872 | ses-01 | Imagery | 5 |
| 6 | sub-0872 | ses-01 | Execution | 1 |
| 7 | sub-0872 | ses-01 | Execution | 2 |
| 8 | sub-0872 | ses-01 | Execution | 3 |

---

## 3. `load_dataLog.m` — Load BOLD Surface Data

**What it does in plain English:**
Takes the 8-row `dataLog` table and loads the actual brain data for each run. For every run, it finds the fMRIPrep `.gii` files, converts them to `.mgh`, reads them into MATLAB, and stacks left + right hemispheres into one matrix.

**Key steps:**
1. Loop over 8 runs
2. For each run, loop over L and R hemispheres
3. Build the BIDS filename, e.g.: `sub-0872_ses-01_task-Imagery_run-01_hemi-L_space-fsnative_bold.func.gii`
4. Convert `.gii` → `.mgh` using FreeSurfer's `mri_convert` (cached — skips if `.mgh` already exists)
5. `MRIread()` the `.mgh` file, `squeeze` the data
6. Concatenate L + R vertically: `datafiles{iRun} = cat(1, leftData, rightData)`

**Output:** `datafiles{1×8}` — each cell is ~300,000 vertices × ~300 timepoints

### File Formats

| Format | What it is | Created by |
|--------|-----------|------------|
| `.gii` (GIFTI) | Surface data (vertices × time), XML-based | fMRIPrep |
| `.mgh` | Same data, FreeSurfer binary format (uncompressed) | Converted from .gii |
| `.mgz` | Same as .mgh but gzip-compressed | FreeSurfer / our output |
| `.nii.gz` (NIfTI) | Volume data (3D grid of voxels) — **not used** in this pipeline | fMRIPrep |

---

## 4. `load_dsm.m` — Load Design Matrices & Noise

**What it does in plain English:**
Loads two kinds of information for each run: "what should the brain be doing" (the design matrix) and "what noise should we remove" (confounds). It reads the design CSV, convolves it with the HRF, and reads fMRIPrep's confounds file.

**Key steps:**
1. **Create HRF** — the hemodynamic response function (brain's blood-flow response shape, peaks at ~5s)
2. **Map run order** — `dmFileNums = [1,3,5,7,8,2,4,6]` maps dataLog rows to dm file numbers (interleaved scan order)
3. **For each run:**
   - Load the design matrix CSV from `dmBaseDir/dmNum/Results/`
   - **Convolve** each finger column with the HRF (smears the sharp 0/1 transitions into the expected slow BOLD response shape)
   - Load confounds `.tsv` from fMRIPrep
   - Extract 9 regressors: 6 motion + global signal + white matter + CSF
   - Add constant (ones) + linear drift (1,2,3,...N) → **11 noise columns total**

### The `dmFileNums` Mapping

| dataLog row | Task | Run | dm file # | Why |
|------------|------|-----|-----------|-----|
| 1 | Imagery | 1 | **1** | Odd = imagery (interleaved scan order) |
| 2 | Imagery | 2 | **3** | |
| 3 | Imagery | 3 | **5** | |
| 4 | Imagery | 4 | **7** | |
| 5 | Imagery | 5 | **8** | |
| 6 | Execution | 1 | **2** | Even = execution |
| 7 | Execution | 2 | **4** | |
| 8 | Execution | 3 | **6** | |

### What Convolution Does

```
Before (raw):     1 1 0 0 0 0 0 0 0 0    (finger active, then rest)
After (convolved): 0.2 0.8 1.0 0.7 0.3 0.1 0 0 0 0   (predicted BOLD response)
```

### The 11 Noise Columns in `myNoise`

| # | Name | What it captures |
|---|------|-----------------| 
| 1 | `const` | Baseline signal level (all 1s) |
| 2 | `ldrift` | Scanner drift over time (1, 2, 3, ... N) |
| 3-8 | `trans_x/y/z`, `rot_x/y/z` | Head motion (translation + rotation) |
| 9 | `global_signal` | Average signal across whole brain |
| 10 | `white_matter` | Signal from white matter (not neural) |
| 11 | `csf` | Signal from cerebrospinal fluid (not neural) |

### The Confounds File (`desc-confounds_timeseries.tsv`)

Generated by fMRIPrep — a huge table (~350 columns × ~300 rows) with one row per timepoint. Contains motion parameters, physiological signals, CompCor components, and more. Our pipeline only uses 9 of these columns.

**Output:**
- `dsm{1×8}` — each cell is ~300 × 5 (Execution) or ~300 × 6 (Imagery)
- `myNoise{1×8}` — each cell is ~300 × 11

---

## 5. `get_beta.m` — GLM Beta Computation

**What it does in plain English:**
For each of the 8 runs, it normalizes the BOLD signal to percent change, combines the design matrix and noise into one model, then solves a least-squares regression to find how strongly each vertex responded to each finger. The result is a beta weight per vertex per finger.

**Key steps (per run):**
1. **Combine X** — `[dsm, myNoise]` side by side → ~300 × 17 (Imagery) or ~300 × 16 (Execution)
2. **Percent signal change** — divide each vertex by its mean over time, subtract 1, multiply by 100
3. **Solve GLM** — `betas = pinv(X) * Y` — one beta per vertex per column of X
4. **Reconstruct** — multiply only the finger columns of X by their betas to get a "clean" predicted signal

### The GLM Equation

At every vertex, the model says:

```
signal ≈ β₁×thumb + β₂×index + β₃×middle + β₄×ring + β₅×pinky + β₆×sixth
        + β₇×const + β₈×drift + β₉×motion_x + ... + β₁₇×csf + error
```

The betas are solved via `pinv(X) * Y` (ordinary least squares).

### Original Signal vs. Reconstructed Signal

| | Original | Reconstructed |
|--|----------|---------------|
| **Contains** | Finger activation + noise + motion + drift + random | **Only** finger activation |
| **Looks like** | Noisy, messy | Clean, smooth |
| **Used for** | Input to GLM | Visualization / quality check |

The **betas** are what we ultimately save — they collapse the time series into a single number per finger per vertex.

### Data Sizes

> [!NOTE]
> The `data` (reconstructed signal) is not used in the final output — only `betas` matter for the saved `.mgz` files.

| Variable | Imagery run | Execution run |
|----------|------------|---------------|
| `X` | 300 × 17 | 300 × 16 |
| `tmp` (% signal change) | 300,000 × 300 | 300,000 × 300 |
| `betas{i}` | 300,000 × 17 | 300,000 × 16 |
| `data{i}` (reconstructed) | 300,000 × 300 | 300,000 × 300 |

---

## 6. Run-Matching Verification

The scans were **interleaved** (MI, ME, MI, ME, MI, ME, MI, MI). Three numbering systems exist:

| dataLog row | BOLD file (BIDS) | dm file # | dm filename | Match? |
|---|---|---|---|---|
| 1 | `task-Imagery_run-01` | 1 | `sixFingers1_MI_101_1_*` | ✅ |
| 2 | `task-Imagery_run-02` | 3 | `sixFingers1_MI_101_3_*` | ✅ |
| 3 | `task-Imagery_run-03` | 5 | `sixFingers1_MI_101_5_*` | ✅ |
| 4 | `task-Imagery_run-04` | 7 | `sixFingers1_MI_101_7_*` | ✅ |
| 5 | `task-Imagery_run-05` | 8 | `sixFingers1_MI_101_8_*` | ✅ |
| 6 | `task-Execution_run-01` | 2 | `sixFingers1_ME_101_2_*` | ✅ |
| 7 | `task-Execution_run-02` | 4 | `sixFingers1_ME_101_4_*` | ✅ |
| 8 | `task-Execution_run-03` | 6 | `sixFingers1_ME_101_6_*` | ✅ |

**Three layers of protection:**
1. `dmFileNums = [1,3,5,7,8,2,4,6]` maps BIDS per-task run numbers to interleaved scan numbers
2. `sesType` (MI/ME) is determined from `dataLog.task`, so the filename prefix always matches the task
3. If any mismatch existed, `dir()` would fail to find the file and the pipeline would crash

---

## Key Concepts

### HRF (Hemodynamic Response Function)
When a finger moves at time *t*, the brain's blood flow response peaks ~5–6 seconds later and takes ~30 seconds to return to baseline. The HRF models this delayed shape.

### GLM (General Linear Model)
The statistical model: Y = Xβ + ε. We solve for β via least squares.

### Convolution
"Smearing" the sharp 0/1 design matrix with the HRF so it predicts the expected slow BOLD signal shape.

### PSC (Percent Signal Change)
Normalizing raw BOLD values so all vertices are on the same scale: `(signal / mean - 1) × 100`.

### Surface vs. Volume
- **Volume**: 3D voxel grid, stored in `.nii.gz` — not used here
- **Surface**: Points on cortical sheet (~150K/hemisphere), stored in `.gii`/`.mgh`/`.mgz` — what we use

### Mass-Univariate
A separate GLM is fit at each vertex independently — not one big model for the whole brain.

---

## Academic Jargon Reference

### Plain English → Academic Term

| What we said | Academic term |
|---|---|
| Brain signal over time | **BOLD time series** |
| Table of when each finger was active | **Stimulus onset function** / **task regressors** |
| Smearing design with HRF | **Convolution with the canonical HRF** |
| The combined X matrix | **Design matrix** |
| Noise columns (motion, drift) | **Nuisance regressors** / **confound regressors** |
| Solving for betas | **Parameter estimation** via **OLS** |
| Beta for one finger at one vertex | **Beta weight** / **parameter estimate** |
| `pinv(X) * Y` | **Moore-Penrose pseudo-inverse** solution |
| Converting to % signal change | **PSC normalization** |
| The whole GLM procedure | **Mass-univariate GLM** |
| Averaging betas across runs | **Fixed-effects averaging** |
| The reconstructed signal | **Fitted response** / **model-predicted time course** |
| Working on brain surface, not voxels | **Surface-based analysis** |
| Each subject's own brain shape | **Native space** / **subject-specific cortical surface** |

### Bonus Terms

| Term | Meaning in our pipeline |
|---|---|
| **First-level analysis** | This whole pipeline (one subject, one session) |
| **Second-level analysis** | Group analysis across subjects (not done here) |
| **Condition** | One finger type — one column of the design matrix |
| **Contrast** | Comparing conditions (e.g., thumb > index) — not done here |
| **Run** | One continuous scanning block (~5 min), 8 per session |
| **Regressor** | Any column in the design matrix |
| **Covariate** | Another word for nuisance regressor |

### Sample Methods Section

> *"BOLD time series were extracted from each vertex on the subject's native cortical surface (fsnative) reconstructed by FreeSurfer. Data were converted to percent signal change. A general linear model (GLM) was fit independently at each surface vertex. The design matrix included task regressors for each finger condition (5 for motor execution; 6 for motor imagery, including the supernumerary sixth finger), convolved with the canonical hemodynamic response function (SPM). Nuisance regressors included six rigid-body motion parameters, global signal, white matter signal, CSF signal, a constant term, and a linear drift regressor. Parameter estimates (beta weights) were obtained via ordinary least squares and averaged across runs within each task."*

---

## Pre-Run Checklist

- [x] FreeSurfer 8.1.0 installed with `MRIread`, `MRIwrite`, `read_curv`, `mri_convert`
- [x] Paths updated to FreeSurfer 8.1.0 in `run_main.m` and `load_dataLog.m`
- [x] dmNum unified to 100-series (300-series renamed)
- [x] `map.json` structured as valid JSON with all 10 subjects
- [x] `process_subject_fingermap.m` accepts all parameters (no hardcoded values)
- [x] 6th finger condition saved for Imagery (6 conditions vs 5 for Execution)
- [x] Run-matching verified: BOLD files correctly paired with design matrix files
- [x] Run `run_main.m` in MATLAB
- [x] Verify output `.mgz` files for a few subjects

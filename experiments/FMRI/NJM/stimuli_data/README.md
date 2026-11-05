# NJM fMRI – stimulus and design data

Everything the NJM fMRI task needs, extracted from the protocol PDF (Frimpong, J. A., *Evaluating Competing Job Offers…*).
Where the protocol names a parameter but gives no value, a **SIMULATED** placeholder is used so the code can be built and tested now.
Every value and its origin (protocol page, resolved conflict, inferred from lab docs, or simulated) is listed in `parameter_sources.csv`.

The implementation plan for turning the lab template into this task is in `../IMPLEMENTATION_PLAN.md`.

## Files

| File | What it is | Status |
|---|---|---|
| `njm_fmri_parameters.json` | Single source of truth (timing, attributes, response mapping, layout, catch/exclusion rules, eye tracking, physio, payout). Read in MATLAB with `jsondecode(fileread(...))`. | mixed – see sources |
| `parameter_sources.csv` | Provenance of each parameter, with protocol page and conflicts noted | – |
| `attributes_levels.csv` | 4 attributes, 13 levels, display text and icon per level | protocol |
| `job_profiles.csv` | Full factorial: 4 origins × 3 salaries × 3 rest-day levels × 3 workloads = 108 profiles | protocol |
| `response_mapping.csv` | Buttons 1–4 → finger, label, choice (A/B), confidence; VPixx colour and keyboard fallback | VPixx colours SIMULATED |
| `design/design_v01..v04.csv` | 4 design versions × 4 runs × 12 trials, with planned onsets for every phase (seconds from first trigger) | SIMULATED |
| `design/design_summary.txt` | Level balance, attribute correlations, D-error, run length and volume count | – |
| `design/design_efficiency.txt` | Phase-regressor collinearity for 3 timing options (see below) | – |
| `faces/` | 24 placeholder silhouettes (6 per origin) + `face_inventory.csv` | PLACEHOLDER |
| `icons/` | 5 placeholder icons (employer, background, salary, rest days, workload), white on transparent | PLACEHOLDER |
| `eyetracking_aoi.csv` | Areas of interest per phase/side/element in degrees of visual angle | SIMULATED layout |
| `physio_trigger_codes.csv` | Event codes for VPixx DOUT / EyeLink messages | SIMULATED |
| `simulated/participants.tsv/.json` | 33 simulated enrolled participants (11 per cohort) with design version | SIMULATED |
| `simulated/sub-9999/ses-01/*_events.tsv` | Example of the BIDS events file the new code should write (one row per phase) | SIMULATED responses |
| `generate_njm_design.py` | Rebuilds everything above from the JSON (seeded; needs numpy, pandas, pillow) | – |

## Design in one paragraph

Each run: 10 s fixation, 12 trials, 12 s fixation = **232 s (3.87 min)**, identical for every run and version, so the scanner can be programmed with a fixed **158 volumes at the placeholder TR of 1.5 s**.
A trial is Phase 1 employer photos + origin (3.0 s) → fixation 1–3 s → Phase 2 full offers (4.0 s) → fixation 1–3 s → Phase 3 decision (up to 3.0 s, 0.2 s highlight on press) → fixation 3–7 s.
Each run has 10 trade-off trials (no option dominates), 1 identical-terms trial (same job terms, different employer origin – Aim 2) and 1 catch trial (same origin, one option better on everything; dominant side 2×A, 2×B).
Employer origins are perfectly balanced (each origin 11× left, 11× right per version); job terms were chosen by a D-efficiency search with level balance and no-dominance constraints.

## Why there is jitter between phases

The protocol (p.5, p.12) promises independent HRF deconvolution of each phase, but the timing table on p.13 has the phases back-to-back.
`design/design_efficiency.txt` shows that with no gap between phases a phase-specific FIR model is **not estimable** (rank 19 of 25), while 1–3 s gaps make it estimable (max VIF 4.4) and still fit the protocol's 14–16 min scanning budget.

## Regenerating

Edit `njm_fmri_parameters.json`, then:

```bash
python3 generate_njm_design.py
```

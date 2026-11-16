# NJM fMRI – stimuli and design

Everything the task reads. Values follow the protocol draft of 11-12-26; where the protocol gives no value a placeholder is used and marked. `parameter_sources.csv` lists every value with its protocol page, whether it changed from the earlier draft, and whether it is a placeholder.

| File | What it is | Made by |
|---|---|---|
| `njm_fmri_parameters.json` | all settings of the task (read by MATLAB at run time) | by hand |
| `parameter_sources.csv` | provenance of each parameter | by hand |
| `design/njm_fmri_trials.csv` | the 48 pairs of offers (40 trade-off, 4 identical-terms, 4 catch) | `generate_njm_design.py` |
| `design/njm_practice_trials.csv` | 6 practice pairs, none of them in the 48 | `generate_njm_design.py` |
| `design/design_summary.txt` | balance of the trial set, run length, volumes | `generate_njm_design.py` |
| `design/design_efficiency.txt` | can the three phases be separated? four timing options compared | `generate_njm_design.py` |
| `attributes_levels.csv`, `job_profiles.csv`, `response_mapping.csv`, `physio_trigger_codes.csv`, `eyetracking_aoi.csv` | lookup tables | `generate_njm_design.py` |
| `faces/` | standardised employer photos + `face_inventory.csv` + `contact_sheet.png` | `prepare_faces.py` |
| `faces_raw/<ORIGIN>/` | the photos as generated, before standardisation | you |
| `icons/` | attribute icons (Noto Emoji, Apache 2.0) | – |
| `_source/` | local working files (face-detector model, source sheets); ignored by git | – |

Per-participant randomisation is **not** in these files; MATLAB does it at run time (see the NJM `README.rst`).

## The trial set

48 trials from 96 different job profiles (88.9 % of the 4 × 3 × 3 × 3 = 108), as the protocol specifies. Each employer origin appears 24 times and each salary, rest-day and workload level 32 times (8 times within each origin). The pairs were chosen by a D-efficiency search (D-error 0.74) under these rules:

- **trade-off** (40): different employer origins; neither offer is at least as good as the other on all three terms;
- **identical terms** (4): same salary, rest days and workload, different employer origins – the direct test of "does origin matter when the terms are identical";
- **catch** (4, one per origin): same origin, best profile (AED 3,200, 1 day, light) against the worst (AED 1,800, 0 days, heavy). These two profiles are better or worse than every other profile, so they cannot be part of a real trade-off trial.

## Timing: why there are gaps between the phases

The protocol's timing table shows Phase 1 → Phase 2 → Phase 3 back to back, while its text and its benchmark table ask for jittered intervals between phases so that the three phases can be deconvolved independently. `design/design_efficiency.txt` shows that with no gap this deconvolution cannot be estimated at all, and that 1–3 s gaps are enough. The default therefore uses every element of the timing table plus 1–3 s gaps. To change it, edit the `timing` block of the JSON and re-run `generate_njm_design.py` (to refresh the reports); the task itself reads the JSON directly.

## Faces

The protocol asks for 50 AI-generated photos of women per employer origin, matched and pre-tested, cropped to the central facial features. **Only the 8 sample images printed in the protocol are in `faces/` so far** (2 per origin, low resolution, not pre-tested, origin labels taken from the layout of the sample sheet). They make the task runnable and testable; they are not the final stimuli.

To put in the real set:

1. Generate the photos with the criteria of the protocol (p.19): frontal, neutral expression, same lighting, background, framing and age range; matched on attractiveness, warmth, trustworthiness and dominance.
2. Save them as `faces_raw/SEA_SA/`, `faces_raw/ARAB/`, `faces_raw/AFRICAN/`, `faces_raw/WESTERN/` (any file names; PNG or JPG; at least ~150 px between the eyes) and delete the `protocol_sample_*` files.
3. Run `python3 prepare_faces.py` (needs `numpy pandas opencv-python`). It finds the eyes, rotates and scales every face to the same eye positions, cuts the oval that shows only eyes, nose and mouth, equalises lightness and contrast, and writes `faces/`, the inventory and a contact sheet to look at.
   - `--behavioral-per-origin 25` reserves photos for the behavioural task so the scanner photos are unseen.
   - `--lum-match within` (default) equalises photos within each origin group and keeps natural skin tone; `--lum-match across` also equalises between groups (equal luminance for pupillometry, but skin tones are visibly changed). The lightness of every face is in the inventory either way.
4. After the rating pre-test (20–30 raters), remove outliers from `faces_raw/`, re-run, and set `pretest_status` in the inventory.

The task needs at least 2 fMRI-set faces per origin and uses however many there are.

## Regenerating

```bash
python3 generate_njm_design.py     # trial set, lookup tables, reports   (numpy, pandas)
python3 prepare_faces.py           # faces/                              (numpy, pandas, opencv-python)
```
Then run `njm_selftest` in MATLAB.

# NJM fMRI – plan for adapting the lab template

**Starting point:** `NJM/` is an exact copy of `experiments/FMRI/template-experiment` (circular path + travelling dot, 10 colour trials of 1 s stimulus → 2 s response → 0.5 s feedback → 0.5 s ITI).
**Target:** the 3-phase paired job-offer task described in the protocol, one `main()` call per run, 4 runs × 12 trials.
**Inputs ready:** everything in `stimuli_data/` (parameters, 4 design versions with planned onsets, placeholder faces/icons, AOIs, trigger codes, example output). Values marked SIMULATED there are placeholders until the PI confirms them (section 5).

Patterns to reuse from newer lab code:
- `experiments/FMRI/qc/fingers-mapping/` – absolute onset scheduling (`present_image_epoch.m`), preloaded textures (`containers.Map`), BIDS-ordered filenames with timestamp (`get_info.m`), events/design-matrix writing (`cleanup_experiment.m`), and the macOS note that timed `Flip` is unreliable with PsychVulkanCore (use `WaitSecs('UntilTime', …)` + bare `Flip`).
- `experiments/EEG-FMRI/finger-tapping/showBlockWindow.m` and `experiments/EEG-FMRI/general/bit_test.m` – `Datapixx('SetDoutValues', code)` event markers.
- `experiments/general/vpixx-utilities/vpixx_responsepixx_demo.m` – DIN logging with hardware timestamps.

---

## 1. Template bugs – fixed 2026-11-05

Fixed in `experiments/FMRI/template-experiment` and copied into `NJM` (code was identical).

| # | Problem | Fix | Files |
|---|---|---|---|
| 1 | VPixx path used a fixed `..` depth that was right in `tests/template-experiment` but broke after the move to `experiments/FMRI/`, so `getButtonColor` was never found and the button box silently fell back to the keyboard. | Search upwards for `experiments/general/vpixx-utilities`; warn if not found. | `main.m` |
| 2 | 0-byte `experiments/general/getButtonColor.m` could shadow the real function. | Deleted (tracked in git). | – |
| 3 | `KbQueueCheck` called twice per frame in the response loop, so keyboard responses were lost. The button-box error path also printed a warning every frame. | One `KbQueueCheck` per frame; a button-box failure switches to keyboard once (`pa.buttonBoxFailed`). | `s3_response.m` |
| 4 | Each phase timed itself from its own `GetSecs`, so timing drifted and logged onsets weren't the real ones. | New `start_phase.m`: every phase starts at trigger + `pa.scheduleTime` (`WaitSecs('UntilTime')` + plain `Flip`, as in qc/fingers-mapping) and is logged in `pa.phaseLog` (planned, actual, delay). Trial onsets come from the actual stimulus frame. Cleanup prints mean/max onset delay. | `start_phase.m` (new), `s1`–`s6`, `setup_param.m`, `main.m`, `cleanup_experiment.m` |
| 5 | Time zero was taken *after* EyeLink start-recording, not at the trigger, so onsets were shifted when eye tracking was on. | `wait_trigger` returns the trigger time; it is now `experimentStartTime`. | `wait_trigger.m`, `main.m` |
| 6 | Filenames were `sub_ses_run_task`. | BIDS order `sub_ses_task_run` (no timestamp, to stay BIDS-valid; the overwrite prompt still protects existing files). | `get_info.m`, `create_bids_eyetrack.m` |
| 7 | ESC during the start period did `return` inside `try`, skipping cleanup (window left open, no data saved). | Skip the trials and continue to cleanup; end screen skipped after ESC. | `main.m` |
| 8 | RT measured from a `GetSecs` before the first frame. | RT measured from the response-screen onset. | `s3_response.m` |
| 9 | `main.asv` autosaves committed. | `*.asv` added to `.gitignore`. The existing `.asv` files are still there; delete them if you don't need them. | `.gitignore` |

Still open:
- **DIN log for button presses.** The box is still polled once per frame, which is about 16 ms resolution. Switching to hardware-timestamped presses (`vpixx_responsepixx_demo.m`) needs testing on the VPixx hardware.
- **Full-rate gaze.** Not a bug after all: the EDF already records at the tracker rate. The 0.5 s samples are only for the live plot. NJM still needs the phase messages and AOIs (section 2.6).

---

## 2. File-by-file changes

### 2.1 `main.m`
- Rewrite the header for NJM; keep `debugConfig` as is.
- `bidsInfo = get_info(experimentDir, 'njm')` (now also returns `designVersion`).
- After `setup_param`, the loop is driven by the design table, not by colours:

```matlab
wait_trigger(...)                          % returns trigger time -> pa.triggerTime, sends RUN_START
s1_leadIn(...)                             % fixation until first onset_phase1
for t = 1:height(pa.design)
    row = pa.design(t,:);
    s2_phase1_employer(..., row)           % photos + origin, 3.0 s
    s5_fixation(..., row.onset_phase2)     % ISI1 1-3 s
    s3_phase2_offer(..., row)              % photos + origin + salary/rest/workload, 4.0 s
    s5_fixation(..., row.onset_phase3)     % ISI2 1-3 s
    s4_phase3_decision(..., row)           % options, ends on press, 0.2 s highlight
    s5_fixation(..., nextOnset)            % rest of the 3 s window + ITI 3-7 s
end
s5_fixation(... lead-out 12 s ...), s6_endScreen(...)
```
- Remove `currentFixationAngle` and everything about the travelling dot.

### 2.2 `utils/setup/`

| File | Change |
|---|---|
| `get_info.m` | BIDS order + timestamp (bug 5). Add a `Design version` field, defaulting to `mod(subjectNumber-1,4)+1`, editable. Validate run ∈ 1–4. Default task `njm`. |
| `setup_param.m` | Rewrite. Read `stimuli_data/njm_fmri_parameters.json`; read `design/design_vXX.csv` and keep the rows for this run. Preload face textures for this run + the 5 icons into a `containers.Map`. Convert `display.layout_deg` to pixel rects with `VP.pixelsPerDegree` (+y is down). Build the display strings from `attributes.*.display`. Pre-allocate `pa.data` per trial: planned and actual onset of each phase, `onsetDelay`, button, label, choice, confidence, RT, timeout, catch pass. Store `pa.dout` codes from `physio_trigger_codes.csv`. Remove colours, dot cache and circle parameters. |
| `setup_keyboard.m` | Keys `1`–`4` → buttons 1–4, plus ESC, `t`/`5`. Drop colour names. |
| `check_response.m` | Return button number 1–4 (not a colour). |
| **new** `get_button_response.m` | Wrap `getButtonColor(struct('right_box',{{'red','yellow','green','blue'}}), false)` and map colour → button via `response_mapping.csv`. Only the right box: the left hand holds the squeeze ball. Better: read the DIN log for hardware-timestamped presses. **The finger→colour mapping is a placeholder** – verify with `experiments/general/test-vpixx-utilities/test_getButtonColor.m`. |
| **new** `send_event.m` | One call per event: `Datapixx('SetDoutValues', code)` (ideally latched to the next flip with `RegWrVideoSync`), reset to 0 after ~10 ms, `Eyelink('Message', name)`, append to `pa.events`. Verify bit mapping with `bit_test.m` – in the lab's EEG-fMRI setup value 4 lights bit 0. |
| `wait_trigger.m` | Keep the DIN bit-14 logic. Return the trigger timestamp and send `RUN_START`. |
| `create_bids_events.m` | Rewrite: one row per phase plus a `response` row, with all attribute columns. Target format = `stimuli_data/simulated/sub-9999/ses-01/*_events.tsv` and its JSON sidecar. Write actual (flip) onsets; keep planned onsets in the `.mat`. |
| `cleanup_experiment.m` | Replace the colour accuracy summary with: responses, timeouts (%), catch result, median RT, and a warning when an exclusion rule is hit (timeouts > 15 %, failed catch). Close textures before saving `pa`. Write events TSV/JSON. |
| `setup_display.m` | Keep. Remove the unused `PsychPortAudio('Open')`. Check readable text size on the in-bore screen. |

### 2.3 `utils/stimuli/` (replace the circle/dot files)

| File | Purpose |
|---|---|
| `present_epoch.m` | Generic: draw → wait until target onset → flip → log actual onset and delay → `send_event` → keep redrawing until the planned end, with ESC check. Adapted from `qc/fingers-mapping/utils/stimuli/present_image_epoch.m`. |
| `draw_fixation.m` | Central cross (`fixation_half_size_deg`). |
| `draw_offer_screen.m` | One drawing function for all 3 phases: for each side, photo (`DrawTexture`), icon + text rows (origin; in Phase 2 also salary, rest days, workload); in Phase 3 the prompt and the 4 option boxes, plus the highlight border around the selected option. Optional "Trial n / 48" header. |
| `s1_leadIn.m`, `s5_fixation.m` | Fixation until a given absolute time. |
| `s2_phase1_employer.m`, `s3_phase2_offer.m` | Fixed-duration screens via `present_epoch`. |
| `s4_phase3_decision.m` | Show options from `onset_phase3`; poll responses (keyboard or `get_button_response`) for up to 3.0 s; on a press send `RESPONSE_Bn`, record RT from the flip timestamp, show the highlight for 0.2 s, then hand over to fixation. **The schedule does not shift**: the next trial still starts at its planned onset, so every run is exactly 232 s. No press → `RESPONSE_TIMEOUT`. |
| `s6_endScreen.m` | "Rest – next run soon" text (instead of the moving dot). |
| delete | `drawCircleWithDot.m`, `utils/cache/get_dot_cache.m` and cached `.mat` files. |

### 2.4 New top-level scripts
- `compute_payout.m` – run after run 4: load the 4 run `.mat` files, pick one random trial, apply the rule (only Definitely A/B → market lottery → salary / 64), print and save the result with the completion fee. Kept outside `main` because each run is a separate `main()` call.
- Practice mode – the protocol has a mock-scanner practice (p.7). Add `debugConfig.practice = 1` and a short `design/practice.csv` (to be added to the generator: ~4 trials, not used in the real design).
- Instruction screens – before run 1 (full instructions with the icons) and before each run (button reminder). Language per cohort is an open decision; non-Latin scripts must be tested with Psychtoolbox's text renderer on the stimulus Mac.

### 2.5 Physio
- If physiology is recorded by the **scanner's own pulse/respiration (PMU)**, it is already in scanner time: RETROICOR and event-locked HR can be aligned through the trigger time and `events.tsv`, and DOUT markers are optional.
- If it is recorded on a **separate amplifier (e.g. BrainAmp ExG MR)**, send the DOUT codes in `physio_trigger_codes.csv` at every phase onset (as the protocol asks, p.8) and log the scanner triggers on the same device.

### 2.6 Eye tracking (`utils/eyetracking/`)
- `initEyelinkStates('eyestart')` already sets HV5 calibration and writes pupil `AREA` to the EDF; add an explicit sampling rate (`sample_rate = 1000`, placeholder until the tracker setup is confirmed). EDF name ≤ 8 characters, e.g. `N9999R1` (the template currently uses the date `mmddHHMM`).
- Messages: `TRIALID n` at Phase 1, then `PHASE1_ONSET`, `PHASE2_ONSET`, `PHASE3_ONSET`, `RESPONSE_Bn`/`RESPONSE_TIMEOUT`, `ITI_ONSET`; `!V TRIAL_VAR` for every attribute; `!V IAREA RECTANGLE` per AOI from `eyetracking_aoi.csv` so Data Viewer has AOIs per phase.
- Drop `record_continuous_gaze.m` from the trial loop (keep it only as an optional live check); replace `create_bids_eyetrack.m`/`plot_continuous_gaze.m` with offline EDF conversion.
- The protocol uses pupil dilation as a friction index, so the face photos must be luminance-matched and screens should have similar overall luminance across phases.

---

## 3. Order of work

1. ~~Template bug fixes~~ – done (section 1).
2. JSON + design loading and the absolute schedule with fixation-only screens. Check on the stimulus Mac: run length 232 s, `onsetDelay` < 1 frame.
3. Drawing for the 3 phases with the placeholder faces/icons; check layout on the projector (`displayMode = 1`).
4. Responses: keyboard, then the right VPixx box; verify finger→colour mapping and DIN-log RTs.
5. Outputs: `.mat` + per-phase `events.tsv`, compared with the simulated example.
6. DOUT markers (if needed) and physio alignment test.
7. Eye tracking: EDF, messages, AOIs, in-bore calibration.
8. Payout script, practice mode, instruction screens.
9. Full pilot with `sub-9999` at the scanner: 4 runs, 158 volumes each (at TR 1.5 s), trigger and timing logs.

---

## 4. Timing defaults used in `stimuli_data/` and why

| Element | Default | Protocol says |
|---|---|---|
| Phase 1 | 3.0 s | 2.5–3.0 s (p.5, p.13) vs 4.0 s (p.12) |
| ISI 1 and ISI 2 | 1, 2, 3 s (6/4/2 per run) | p.12 text: phases jittered; p.13 table: no gap |
| Phase 2 | 4.0 s | 4.0 s (p.5, p.13) vs 5.0 s (p.12) |
| Phase 3 | ≤ 3.0 s, 0.2 s highlight | same |
| ITI | 3–7 s, counts 5/3/2/1/1 (p.12 probabilities) | p.12: 3–7 s, mean "5 s" (the probabilities give 4.2 s); p.13: 2–6 s plus 1–2.5 s fixation |
| Run | 10 s + 12 trials + 12 s = 232 s | 3.5–4 min per run, 14–16 min total |

From `stimuli_data/design/design_efficiency.txt` (TR 1.5 s):

| Option | Task scanning (4 runs) | Phase-specific FIR model |
|---|---|---|
| Default (gaps 1–3 s) | 15.5 min | estimable, max VIF 4.4 |
| p.13 table (no gaps) | 12.0 min | **not estimable** (rank 19 of 25) |
| p.12 text (gaps 3–7 s, 4/5/3 s phases) | 21.1 min | estimable, max VIF 1.8 |

With the canonical HRF alone all three options are fine (VIF ≤ 2), so the gaps matter specifically because the protocol promises independent deconvolution of each phase.

---

## 5. Decisions needed from the PI

Conflicts or gaps in the protocol; the current default is in brackets.

1. **Phase durations** – 3.0/4.0/3.0 s or 4.0/5.0/3.0 s? [3.0/4.0/3.0]
2. **Gaps between phases** – needed for the deconvolution the protocol promises (section 4). [1–3 s]
3. **ITI** – 3–7 s with the p.12 probabilities (mean 4.2 s, not 5.0 s) or 2–6 s? [3–7 s]
4. **TR and sequence** – not in the protocol. [placeholder TR 1.5 s → 158 volumes]. vmPFC/OFC and amygdala are core ROIs, so the sequence should be checked for susceptibility dropout there.
5. **Trials and runs** – 48 in 4 runs, or up to 60 in 5 (p.6)? [48 / 4]
6. **Catch trials** – 4 or 4–6? The ">1 failed (33 %)" rule was written for 3 behavioural catches; with 4 fMRI catches it means 50 %. Does "Probably" on the dominant side count as a pass? Should the dominant option be counterbalanced A/B? [4; pass at either confidence; 2 A / 2 B]
7. **Origin levels** – "Southeast / South Asian" is one employer level while workers form separate Southeast Asian and South Asian cohorts, so "culturally aligned" employers (H1) can't be defined for those cohorts separately. Split into 5 levels? (Larger design.) What exact on-screen text for this level (p.11 example says "South Asian Family")?
8. **Phase 3 screen** – terms hidden (p.13: photo + origin + options) or still visible? [hidden]
9. **Payout** – "Probably" responses can never pay, which gives an incentive to press "Definitely" and may bias the confidence measure that H3 relies on. Also: "rounded down" vs 28.13/39.06; market lottery probability; completion fee and travel amounts; is the paid trial drawn from fMRI, behavioural, or both tasks? [p = 0.5; fee/travel are placeholders only]
10. **Faces** – source, identities per origin, matching (age, expression, luminance). [6 per origin, placeholders]
11. **Identical-terms trials** – one per run as a clean probe for Aim 2? [yes]
12. **Language** of instructions and on-screen text per cohort.
13. **Physio hardware** – scanner PMU or separate amplifier; is skin conductance (p.10) actually recorded?
14. **Eye tracker** – model, sampling rate, calibration type. [1000 Hz, HV5]
15. **Sample size** – 25–30 usable vs 30–35 (abstract); 10–12 per cohort gives 30–36.
16. **Head-motion exclusion** – no threshold given. [FD > 0.5 mm in > 20 % of volumes, or > 3 mm translation]
17. **Trial counter** – is "Trial n / 48" shown to participants? [yes, as in the p.11 mock-up]

---

## 6. Test checklist before the first participant

- [ ] Each run lasts 232 s (± 1 frame) from trigger; all `onsetDelay` < 1 frame; no missed flips.
- [ ] Logged planned onsets equal `design_vXX.csv`; actual onsets within 1 frame.
- [ ] Keyboard and right-box responses both recorded; finger→button mapping verified on the hardware.
- [ ] Timeout path, early-press path and catch trials behave as specified.
- [ ] `events.tsv` matches the simulated example's columns; `.mat` saves even after ESC or an error.
- [ ] DOUT codes arrive on the physio recorder (if used) with the right values.
- [ ] EDF contains phase messages and AOIs; calibration works in the bore.
- [ ] Scanner programmed with the right number of volumes for the final TR.

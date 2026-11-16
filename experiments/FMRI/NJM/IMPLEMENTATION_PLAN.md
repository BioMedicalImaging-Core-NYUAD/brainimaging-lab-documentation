# NJM fMRI – status, changes and open decisions

Updated 2026-11-16 for the protocol draft of 11-12-26 (52 pages). How to run the task is in `README.rst` (also the experiment's page on the documentation website); this file records what was changed, what was tested and what is still open.

## 1. Status

| Piece | State |
|---|---|
| Task (3 phases, jittered fixation, 4 runs × 12 trials) | **done**, tested end to end with a simulated participant |
| Per-participant randomisation (runs, order, left/right, faces, jitter) | **done**, checked for 60 simulated participants (`njm_check_design`) |
| Trial set: 48 pairs from 96 distinct profiles | **done** |
| Responses: keyboard 1–4 | **done** (logic tested; not yet tried by a person at the keyboard) |
| Responses: VPixx right box | written, **not tested** – needs the hardware; colour → finger mapping is a placeholder |
| BIDS events (one row per phase + response) and `.mat` | **done** |
| Instructions, practice run | **done**; English wording is a draft to align with the IRB text |
| Payout (scanner lottery + online lottery, drawn once) | **done**; market probability is a placeholder |
| Think-aloud playback | **done** |
| Event markers on VPixx digital output | written, **not tested** – needs the hardware and the choice of bit mapping |
| Eye tracking (EDF with phase messages, trial variables, areas of interest) | written, **not tested** – needs the EyeLink |
| Photos | pipeline **done**; only the 8 sample faces of the protocol are in place (see section 4) |
| Icons | **done** (Noto Emoji, open licence) |
| Scanner trigger | unchanged lab code (VPixx DIN bit 14); to be tried at the scanner |

Tested on a Windows PC with MATLAB R2025b and Psychtoolbox 3.0.22, in a window, at 10× speed: 48 trials, 192 event rows, all screens within one frame of schedule (mean onset error −0.1 ms, max 10 ms; a frame is 16.7 ms), no-response and failed-catch paths included. Not tested: the stimulus Mac, the projector, real key or button presses, the trigger, the eye tracker, the digital output.

## 2. What changed with the 11-12-26 protocol

| Topic | Before | Now |
|---|---|---|
| Phase 1 / Phase 2 | 3.0 s / 4.0 s | **4.0 s / 5.0 s** (bold in the timing table) |
| Fixation before each trial | – | **1.0–4.5 s, mean 3 s** (timing table) |
| ITI | 3–7 s | 3–7 s (the table now agrees with the text) |
| Run length / volumes (TR 1.5 s) | 232 s / 158 | **292 s / 198**; 4 runs = 19.5 min |
| fMRI sample | 25–30 usable | **35 usable, 41 enrolled**, 11–12 per cohort |
| Trials | "48 to 60, 4 to 5 runs" | **48 in 4 runs**, fixed |
| Trial set | free pairing from 27 term combinations | **96 distinct profiles of 108** (88.9 %), all levels equally frequent |
| Trial order | 4 fixed versions | **shuffled per participant** |
| Left/right | fixed per version | **half of the trials swapped per run, per participant** |
| Faces | 6 placeholder silhouettes per origin, fixed | AI-generated photos, central features only; **assignment randomised per participant** |
| Screen | two columns | **two cards with a neutral gap, no "OR"**; feedback frames the chosen option and its card |
| Catch trials | "4 to 6" | **4, one per run**; now best vs worst profile of one origin |
| Language | open | **English** |
| Handedness | – | right-handed (Edinburgh inventory) |
| Payment | fee not stated | **AED 80 + AED 20 travel**; bonus 28 / 39 / 50; **dual lottery** (online + scanner) |
| New procedure | – | **think-aloud playback** of the scanned trials |
| Skin conductance | mentioned once | listed as an outcome measure |
| Analysis | GLM | GLM + **attentional drift-diffusion model** (needs gaze per area of interest → written into the EDF) |

Code that went away: the circle/dot screens of the template (`s1`–`s6`, `drawCircleWithDot`, the dot cache), the 0.5 s gaze sampler and its plot, the four fixed design versions and the Python-simulated example data.

Also fixed in passing: screens were starting exactly one frame late because the redraw loop ran half a frame too long before the next screen was scheduled. Corrected here and in `template-experiment` (the `s1`–`s6` loops, `start_phase.m`).

## 3. Decisions taken by default – confirm or change

Each is a one-line change in `stimuli_data/njm_fmri_parameters.json` unless noted.

1. **Gaps between phases (1–3 s).** Not in the timing table, but without them the three phases cannot be deconvolved separately, which the protocol asks for (`stimuli_data/design/design_efficiency.txt`). With the gaps a run is 4.87 min and the four runs 19.5 min, above the "14 to 16 minutes" in the protocol (that figure predates the longer phases; the table as printed, without gaps, already gives 16.8 min). Alternatives in the report: no pre-trial fixation (17.1 min) or 3–7 s between phases as the text says (21.1 min, best separation).
2. **Decision window always takes 3 s in the schedule.** After the button press the rest of the window is fixation, so every run has the same length and number of volumes.
3. **One identical-terms trial per run** (same terms, different origin).
4. **Catch trial = best vs worst profile** of one origin; passing = choosing the better offer with either "Definitely" or "Probably".
5. **Left/right swap is balanced** (exactly half per run) rather than an independent coin flip per trial.
6. **Face luminance is equalised within each origin group**, not between groups (see the faces section of `stimuli_data/README.md`).
7. **Bonus is rounded down** to 28 / 39 / 50 AED; the protocol also prints 28.13 / 39.06 / 50.00.
8. **Trial counter** ("Trial n / 48") is shown, as in the protocol's mock screen.
9. **The lottery draws from all 48 scanned trials**, catch trials included.

## 4. Still needed from the PI / the lab

1. **The photo set**: 50 per origin, generated and pre-tested (protocol p.19). Only the protocol's 8 sample faces are in place: 2 per origin, low resolution, not pre-tested; which sample belongs to which origin was read off the layout of the sample sheet and should be confirmed. Until then every face repeats 12 times per participant.
2. **TR and sequence** (placeholder 1.5 s). vmPFC/OFC and amygdala are core regions, so check signal dropout there.
3. **Market-lottery probability** (placeholder 0.5) and how the online choices reach the scanner visit (the payout script takes a CSV with `confidence` and `chosen_salary_aed`).
4. **Response box**: which physical button is under which finger (placeholder: red, yellow, green, blue = index … little finger on the right box). Test with `experiments/general/test-vpixx-utilities/test_getButtonColor.m`.
5. **Physiology**: scanner's own pulse/respiration recording or a separate amplifier? Only the second needs `sendMarkers = 1`, and then the bit mapping (`doutMapping`, see `send_event.m`) and the codes in `physio_trigger_codes.csv` must be checked with `experiments/EEG-FMRI/general/bit_test.m`. Is skin conductance really recorded?
6. **Eye tracker** settings (placeholders: 1000 Hz, HV5).
7. **Instruction wording** – the JSON has an English draft; it must match the IRB-approved text.
8. **The behavioural task set**: the protocol wants the scanner trials and photos to be unseen. This repo holds only the fMRI set; compare it with the behavioural set once that exists.
9. **Origin levels**: "Southeast / South Asian" is one employer level while workers are recruited as separate Southeast Asian and South Asian cohorts, so "in-group employer" cannot be told apart for those two cohorts.
10. **Payout and certainty**: "Probably" answers can never pay, which rewards pressing "Definitely" and may bias the certainty measure the analysis relies on.

Inconsistencies left in the protocol text (the code follows the first value): Phase 1 4.0 s vs 2.5–3.0 s (p.31, p.41); ITI 3–7 s vs 2–6 s (p.41); mean ITI "5 s" vs 4.2 s from the stated probabilities; handedness "right and/or left" (p.12) vs right-handed only; behavioural catch trials 2 vs 2–3; scan 1–14 days vs 24 h–7 days after the behavioural session; "more than 1 of 4" catch trials called 33 %; "flat cash" payments (p.14) vs the bonus lottery (p.22).

## 5. Before the first participant

- [ ] `njm_selftest` passes on the stimulus Mac.
- [ ] `njm_preview_screens` on the projector (`displayMode 1`): everything visible through the mirror, text readable.
- [ ] One real-time run with the scanner trigger: 292 s from trigger to end, onset delays under one frame, scanner programmed with the volumes the task prints.
- [ ] Button box: each finger gives the right button number; response times plausible.
- [ ] A press in the last moments of the 3 s window, no press at all, and `ESC` all leave complete output files.
- [ ] Eye tracker: calibration in the bore; EDF contains `PHASE1_ONSET` … messages and the interest areas.
- [ ] Physiology recorder (if separate) receives the event codes.
- [ ] Final photos in place, `prepare_faces.py` re-run, contact sheet checked.
- [ ] Instruction texts replaced by the approved wording.
- [ ] `njm_payout` and `njm_playback` tried on the test participant by the people who will run the session.

# Eye Tracking Test - 30 Second Resting State

This is a minimal 30-second resting state experiment using **VRI's exact code structure** with only eye tracking features.

## Structure

Uses VRI resting state code exactly:
- `main.m` - Main entry point (VRI structure)
- `Config/` - Screen, keyboard, file setup (VRI methods)
- `Eyetracking/` - VRI's exact initEyelinkStates.m
- `runDisplay.m` - Display loop with continuous eye tracking (VRI method)

## How to Run

```matlab
cd /Users/pw1246/Documents/GitHub/brainimaging-lab-documentation/tests/eyetracking-test
main
```

## What it does

1. Asks for 4-digit subject ID (or type TEST for debug mode with no eye tracking)
2. Opens screen using VRI's exact PsychImaging setup
3. Initializes EyeLink with VRI's exact method
4. Runs calibration
5. Waits for T or 5 key press
6. Shows fixation dot for 30 seconds with continuous eye tracking monitoring
7. Saves EDF file to Data/SUBJ/Run#/eyedata/

## Differences from VRI

ONLY changed:
- Duration: 30 seconds instead of 343 seconds
- No instructions text (just waits for T/5)
- Removed vpixx-specific code
- Simplified directory structure

Everything else is **EXACTLY** the same as VRI resting state.

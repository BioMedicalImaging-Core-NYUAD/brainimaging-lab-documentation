--------------------------------
fMRI - Finger-tapping experiment
--------------------------------


The `fingertapping` script implements a simple block‐design fMRI task where participants alternate
between “stop” and “tap” cues.
After clearing the workspace and loading subject parameters, the script initializes
Psychtoolbox (and DataPixx for scanner TTL triggers) and converts visual angles to pixels.
It hides the cursor and suppresses keyboard output before showing a scanner‐sync window
(`showTTLWindow_1/2`). During each of `parameters.numberOfBlocks` trials, it displays either
`blockOneMsg` or `blockTwoMsg` via `showBlockWindow`, captures the block’s start and end times,
and logs the duration. Once all blocks complete, an end‐of‐experiment window appears, timings are
saved to `parameters.datafile`, keyboard output and cursor are restored, and all screen and DataPixx
connections are closed.



:github-file:`experiments/FMRI/finger-tapping`


:github-file:`experiments/EEG-FMRI/finger-tapping/main.m`

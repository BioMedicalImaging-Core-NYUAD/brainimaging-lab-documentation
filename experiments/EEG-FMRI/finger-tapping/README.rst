EEG-fMRI Finger Tapping experiment
==================================


The experiment is intended for the EEG-fMRI system.
The participant is asked to tap one finger at a time: thumb, index, middle, ring, pinkie.
The screen shows the finger to be tapped as a text: "Tap thumb" for 1.2 seconds, followed by "Wait" 0.8 seconds, the same finger
is kept for 18 seconds. A random delay of maximum 2 seconds is added at the beginning of each block, the leftout duration is waited inbetween blocks randomly aswell.
The cycle repeats again with a new finger chosen randomly. At the end of the experiment all finger has been asked to be tapped for an equal number of times.
The fMRI blocks are set to a total of 300 seconds.
TR is set to 1 seconds.

The saved MATLAB file from the experiment contains a column block_type:

- 1 is thumb
- 2 is index
- 3 is middle
- 4 is ring
- 5 is pinkie



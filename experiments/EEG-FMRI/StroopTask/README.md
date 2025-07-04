
## Experiment Description:
This repository contains MATLAB Psychtoolbox code for running the Stroop Color-Word Task (SCWT) with auditory and visual feedback and trial timing control.

- Visual Stimuli: Each trial presents a color word (e.g., "RED", "BLUE") displayed in a specific font color at the top-center of the screen. 
  Below the stimulus, there are 10 on-screen colored response buttons, each labeled with a color name and a corresponding keyboard key (1–0). The button colors do not match their labels to induce cognitive interference.
- Response Method: Participants respond by pressing the keyboard keys 1 to 0, each mapped to one of the 10 colored buttons on the screen.
- Auditory Feedback: After each response, a "Correct" sound or "Incorrect" sound is played, and feedback text is displayed.
- Timer: A countdown timer is shown below the stimulus indicating the remaining time to respond for each trial.

- Block Structure:
   - A block of trials followed by a rest period.
   - Each block contains 40 seconds of trials and is followed by a 20-second rest period.
   - The experiment runs for 10 blocks in total.
   - Duration: The total experiment duration is 10 minutes.

### Files:

- StroopTask.m – main experiment script
- GenerateSCWTTrials.m – a function that generates the Stroop trials
- correct2.mp3 – sound played for correct responses
- wrong2.mp3 – sound played for incorrect responses or timeout

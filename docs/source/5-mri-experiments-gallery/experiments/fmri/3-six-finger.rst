--------------------
fMRI - Six
--------------------

The `six-fingers` experiment uses a block‐design paradigm to probe hand‐movement networks in the
fMRI scanner. After loading subject parameters and initializing Psychtoolbox
(and DataPixx for scanner TTL triggers), the script hides the cursor and suppresses keyboard output.
It then alternates between odd‐numbered blocks displaying a rest prompt (`blockOneMsg`)
and even‐numbered blocks showing a full‐screen clenched‐fist image (`clenched_fist.jpg`)
to cue rhythmic finger tapping. Each block’s onset and offset are recorded via `Screen('Flip')`
and `GetSecs`, and all timing data are saved to `parameters.datafile` at the end of the session.
Finally, an end‐of‐experiment window is shown, the cursor and keyboard are restored, and all screen
and Datapixx connections are closed.



:github-file:`experiments/FMRI/six-fingers`


:github-file:`experiments/FMRI/six-fingers/main_ME.m`


:github-file:`experiments/FMRI/six-fingers/main_MI.m`


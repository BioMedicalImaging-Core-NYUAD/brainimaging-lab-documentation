@echo off
dcm2bids ^
    -c C:\Users\hz3752\PycharmProjects\meg-pipeline\pipeline\eeg_fmri_pipelines\fmri_preprocessing\utilities\config.json ^
    -o C:\Users\hz3752\Desktop\EEG-FMRI\data_finger_tapping\t1\bids_output\ ^
    -d C:\Users\hz3752\Desktop\EEG-FMRI\data_finger_tapping\t1\Subject_0665_ses_01\scans ^
    -p 0665 ^
    --force_dcm2bids
pause
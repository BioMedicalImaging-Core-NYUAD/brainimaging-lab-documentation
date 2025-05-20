#!/bin/bash

set -e  # Exit if error occurs

CONFIG_FILE="/home/hz3752/meg-pipeline/pipeline/eeg_fmri_pipelines/fmri_preprocessing/utilities/config.json"
BIDS_DIR="/home/hz3752/data_eeg_fmri/bids_output"
DICOM_DIR="/home/hz3752/data_eeg_fmri/Subject_0665_ses_01/scans"
SUBJECT_ID="0665"  # Participant ID
FMRIPREP_OUTPUT_DIR="/home/hz3752/data_eeg_fmri/fmriprep_output"     # Output directory for fMRIPrep
WORK_DIR="/home/hz3752/data_eeg_fmri"              # Temporary working directory





dcm2bids -d "$DICOM_DIR" \
          -p "$SUBJECT_ID" \
          -c "$CONFIG_FILE" \
          -o "$BIDS_DIR" \
          --force_dcm2bids



# Post conversion (Copy Sbref for each run)

module load python

python post_conversion_script.py $BIDS_DIR

# Run fMRIPrep

module load fmriprep/24.0.0

fmriprep $BIDS_DIR $FMRIPREP_OUTPUT_DIR participant \
    --participant-label $SUBJECT_ID \
    --work-dir $WORK_DIR \
    --output-spaces MNI152NLin2009cAsym fsaverage \



#!/bin/bash

# Set paths (Modify these to match your Linux/HPC environment)
CONFIG_FILE="/home/hz3752/meg-pipeline/pipeline/eeg_fmri_pipelines/fmri_preprocessing/utilities"
BIDS_DIR="/home/hz3752/data_eeg_fmri/bids_output"
DICOM_DIR="/home/hz3752/data_eeg_fmri/Subject_0665_ses_01/scans"
SUBJECT_ID="0665"  # Participant ID

## Ensure Singularity module is loaded (only needed on HPC)
#module load singularity 2>/dev/null

# Run dcm2bids inside the Singularity container
singularity run --cleanenv \
    -B "$CONFIG_FILE:/config.json" \
    -B "$BIDS_DIR:/bids" \
    -B "$DICOM_DIR:/dicom" \
    /home/hz3752/dcm2bids.sif \
    -c /config.json \
    -o /bids \
    -d /dicom \
    -p "$SUBJECT_ID" \
    --force_dcm2bids

#!/bin/bash
# Requires freesurfer
# Visualise finger-tapping beta overlays on inflated surface
#
# SETUP (WSL + Box Drive workaround)
# ------------------------------------
# Box Drive's virtual filesystem causes I/O errors when accessed via WSL's
# /mnt/c mount. To avoid this, copy the required data to the native WSL
# filesystem before running this script:
#
#   1. Copy FreeSurfer subject data:
#      mkdir -p ~/data/fingertapping/derivatives/freesurfer
#      cp -r /mnt/c/Users/hadiz/Box/EEG-FMRI/Data/fingertapping/derivatives/freesurfer/sub-0665 \
#             ~/data/fingertapping/derivatives/freesurfer/sub-0665
#
#      If the copy fails from WSL, first copy to a non-Box Windows folder
#      using PowerShell, then copy from there into WSL.
#
#   2. Copy beta overlay files:
#      cp -r /mnt/c/Users/hadiz/brainimaging-lab-documentation/pipeline/eeg_fmri_pipelines/fmri_preprocessing/finger-tapping/betas \
#             ~/data/fingertapping/betas
#

BIDS_DIR=$HOME/data/fingertapping/derivatives
BETAS_DIR=$HOME/data/fingertapping/betas

# Choose hemisphere
echo "Select hemisphere:"
echo "  1) Left  (lh)"
echo "  2) Right (rh)"
read -rp "Enter choice [1/2]: " choice

case "$choice" in
  1) HEMI="lh" ;;
  2) HEMI="rh" ;;
  *)
    echo "Invalid choice. Please enter 1 or 2."
    exit 1
    ;;
esac

echo "Loading $HEMI hemisphere..."

# Show surface info
mris_info "$BIDS_DIR/freesurfer/sub-0665/surf/${HEMI}.inflated"

# Build the surface argument with overlays as a single string
# (freeview requires :overlay= options to be colon-concatenated with the surface path)
SURFACE="$BIDS_DIR/freesurfer/sub-0665/surf/${HEMI}.inflated"
SURFACE+=":overlay=$BETAS_DIR/${HEMI}.betas_thumb.mgz"
SURFACE+=":overlay=$BETAS_DIR/${HEMI}.betas_index.mgz"
SURFACE+=":overlay=$BETAS_DIR/${HEMI}.betas_middle.mgz"
SURFACE+=":overlay=$BETAS_DIR/${HEMI}.betas_ring.mgz"
SURFACE+=":overlay=$BETAS_DIR/${HEMI}.betas_pinkie.mgz"

freeview -f "$SURFACE"
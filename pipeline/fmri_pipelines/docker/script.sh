#!/usr/bin/env bash
set -euo pipefail

# Optional: participant label passed as first arg
if [[ $# -ge 1 ]]; then
  P_ARG="--participant-label $1"
else
  P_ARG=""
fi

## ─── CONFIG ────────────────────────────────────────────────────────────────
# Number of CPU threads to use
NTHREADS=18

# fMRIPrep Docker image
IMAGE="nipreps/fmriprep:24.1.1"
PROJECT = finger-tapping

# Paths

# --- in script.sh -------------------------------------------------
BIDS_DIR="/home/hz3752/PycharmProjects/brainimaging-lab-documentation/data-bids/eeg-fmri/$PROJECT/rawdata"
OUTPUT_DIR="/home/hz3752/PycharmProjects/brainimaging-lab-documentation/data-bids/eeg-fmri/$PROJECT/derivatives/fmriprep"
RECONALL_DIR="/home/hz3752/PycharmProjects/brainimaging-lab-documentation/data-bids/eeg-fmri/$PROJECT/derivatives/freesurfer"
WORKDIR="/home/hz3752/PycharmProjects/brainimaging-lab-documentation/data-bids/eeg-fmri/$PROJECT/tmp/fmriprep-work"
# ------------------------------------------------------------------

FS_LICENSE="/home/hz3752/Documents/license.txt"

# TemplateFlow cache (if you use it)
export TEMPLATEFLOW_HOME="${HOME}/.cache/templateflow"

## ─── PREPARE ───────────────────────────────────────────────────────────────
# Pull the image if it’s not already present
if ! docker image inspect "${IMAGE}" >/dev/null 2>&1; then
  echo "Pulling ${IMAGE}..."
  docker pull "${IMAGE}"
fi

# Make sure output dirs exist
mkdir -p "${OUTPUT_DIR}" "${RECONALL_DIR}" "${WORKDIR}"



## ─── RUN fMRIPrep ──────────────────────────────────────────────────────────
docker run --rm \
  -u "$(id -u):$(id -g)" \
  -v "${BIDS_DIR}:/data:ro" \
  -v "${OUTPUT_DIR}:/out" \
  -v "${WORKDIR}:/work" \
  -v "${RECONALL_DIR}:/reconall" \
  -v "${FS_LICENSE}:/opt/freesurfer/license.txt:ro" \
  -v "${TEMPLATEFLOW_HOME}:${TEMPLATEFLOW_HOME}" \
  -e TEMPLATEFLOW_HOME="${TEMPLATEFLOW_HOME}" \
  "${IMAGE}" \
  /data /out participant \
    ${P_ARG} \
    --fs-subjects-dir /reconall \
    --skip-bids-validation \
    --output-spaces \
      T1w:res-native \
      fsnative:den-41k \
      MNI152NLin2009cAsym:res-native \
      fsaverage:den-41k \
      fsaverage \
    --nthreads "${NTHREADS}" \
    --mem_mb 32000 \
    --work-dir /work \
    --no-submm-recon

## ─── CLEANUP ───────────────────────────────────────────────────────────────
echo "Cleaning up temporary workdir..."
rm -rf "${WORKDIR}"

echo "Done!  Results are in ${OUTPUT_DIR}"

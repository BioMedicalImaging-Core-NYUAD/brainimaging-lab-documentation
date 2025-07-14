#!/usr/bin/env bash
set -euo pipefail


BIDS_DIR=~/PycharmProjects/brainimaging-lab-documentation/data-bids/
OUT_DIR=~/~/PycharmProjects/brainimaging-lab-documentation/data-bids/
LICENSE=~/license/license.txt
IMAGE="nipreps/fmriprep:24.1.1"
NTHREADS=32

docker pull ${IMAGE} || true  # skip if already up-to-date

docker run --rm \
  -u $(id -u):$(id -g) \
  -v ${BIDS_DIR}:/data:ro \
  -v ${OUT_DIR}:/out \
  -v ${LICENSE}:/opt/freesurfer/license.txt:ro \
  ${IMAGE} \
  /data /out participant \
    --nthreads ${NTHREADS} \
    --fs-license-file /opt/freesurfer/license.txt

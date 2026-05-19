#!/bin/bash
# Create Glasser2016 atlas labels in native space for sub-0457
# Requires: FreeSurfer 7.4.1

export FREESURFER_HOME=/Applications/freesurfer/7.4.1
source ${FREESURFER_HOME}/SetUpFreeSurfer.sh

export SUBJECTS_DIR=/Users/pw1246/Library/CloudStorage/Box-Box/sixthfinger-test/derivatives/freesurfer
export SUBJID=0457
export ATLAS_DIR=${SUBJECTS_DIR}/fsaverage/atlasmgz

# ---------------------------------------------------------------
# STEP 1: Skipped — fsaverage Glasser2016 labels/annotations already
# copied from /Users/pw1246/Documents/MRI/bigbids/derivatives/freesurfer/fsaverage/label/
# ---------------------------------------------------------------
# STEP 2: Project Glasser2016 annotation into sub-0457 native space
# ---------------------------------------------------------------
for hemi in lh rh; do
    mri_surf2surf \
        --srcsubject fsaverage \
        --trgsubject sub-${SUBJID} \
        --hemi ${hemi} \
        --sval-annot ${SUBJECTS_DIR}/fsaverage/label/${hemi}.Glasser2016 \
        --tval ${SUBJECTS_DIR}/sub-${SUBJID}/label/${hemi}.Glasser2016.annot
done

mkdir -p ${SUBJECTS_DIR}/sub-${SUBJID}/label/Glasser2016

mri_annotation2label \
    --subject sub-${SUBJID} \
    --hemi rh \
    --annotation Glasser2016 \
    --outdir ${SUBJECTS_DIR}/sub-${SUBJID}/label/Glasser2016

mri_annotation2label \
    --subject sub-${SUBJID} \
    --hemi lh \
    --annotation Glasser2016 \
    --outdir ${SUBJECTS_DIR}/sub-${SUBJID}/label/Glasser2016

echo "Done. Labels written to: ${SUBJECTS_DIR}/sub-${SUBJID}/label/Glasser2016"

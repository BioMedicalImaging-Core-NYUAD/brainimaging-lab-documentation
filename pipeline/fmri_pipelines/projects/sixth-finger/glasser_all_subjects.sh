#!/bin/bash
# Project Glasser2016 atlas labels into native space for all subjects.
# Uses mri_surf2surf to register fsaverage annotation to each subject,
# then mri_annotation2label to split into individual .label files.

# --- Dynamic paths ---
CURRENT_USER=$(whoami)
if [ "$CURRENT_USER" = "pw1246" ]; then
    export FREESURFER_HOME=/Applications/freesurfer/7.4.1
    BIDS_DIR=/Users/pw1246/Library/CloudStorage/Box-Box/sixthfinger-test
else
    export FREESURFER_HOME=/Applications/freesurfer/8.1.0
    BIDS_DIR=/Users/hha243/Library/CloudStorage/Box-Box/sixthfinger-test
fi

source ${FREESURFER_HOME}/SetUpFreeSurfer.sh
export SUBJECTS_DIR=${BIDS_DIR}/derivatives/freesurfer

SUBJECTS=(
    sub-0457
    sub-0624
    sub-0688
    sub-0861
    sub-0872
    sub-0879
    sub-0881
    sub-0883
    sub-0884
    sub-0885
)

echo "=== Glasser2016 native-space projection ==="
echo "SUBJECTS_DIR: ${SUBJECTS_DIR}"
echo "FreeSurfer:   ${FREESURFER_HOME}"
echo ""

for SUBJID in "${SUBJECTS[@]}"; do

    echo "--- Processing ${SUBJID} ---"

    SUBJ_DIR=${SUBJECTS_DIR}/${SUBJID}
    LABEL_DIR=${SUBJ_DIR}/label/Glasser2016

    if [ ! -d "${SUBJ_DIR}" ]; then
        echo "  SKIPPING: ${SUBJ_DIR} not found"
        continue
    fi

    # Remove previously copied/incorrect labels
    if [ -d "${LABEL_DIR}" ]; then
        echo "  Removing existing Glasser2016 folder..."
        rm -rf "${LABEL_DIR}"
    fi
    mkdir -p "${LABEL_DIR}"

    # Step 1: Project fsaverage annotation to subject native space
    for hemi in lh rh; do
        echo "  Projecting ${hemi} annotation..."
        mri_surf2surf \
            --srcsubject fsaverage \
            --trgsubject ${SUBJID} \
            --hemi ${hemi} \
            --sval-annot ${SUBJECTS_DIR}/fsaverage/label/${hemi}.Glasser2016 \
            --tval ${SUBJ_DIR}/label/${hemi}.Glasser2016.annot

        if [ $? -ne 0 ]; then
            echo "  ERROR: mri_surf2surf failed for ${SUBJID} ${hemi}"
            continue
        fi
    done

    # Step 2: Split annotation into individual .label files
    for hemi in lh rh; do
        echo "  Splitting ${hemi} annotation into labels..."
        mri_annotation2label \
            --subject ${SUBJID} \
            --hemi ${hemi} \
            --annotation Glasser2016 \
            --outdir ${LABEL_DIR}

        if [ $? -ne 0 ]; then
            echo "  ERROR: mri_annotation2label failed for ${SUBJID} ${hemi}"
            continue
        fi
    done

    N=$(ls ${LABEL_DIR} | wc -l)
    echo "  Done: ${N} label files written to ${LABEL_DIR}"
    echo ""

done

echo "=== All done! ==="

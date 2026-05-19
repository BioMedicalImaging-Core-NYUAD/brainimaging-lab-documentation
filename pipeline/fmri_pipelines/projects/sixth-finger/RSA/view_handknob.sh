#!/bin/bash
# =============================================================================
# view_handknob.sh  —  Open Freeview for hand knob identification (Step 2)
#
# Opens TWO windows:
#   1. T1 axial — find the omega/epsilon hand knob shape, click to get RAS coords
#   2. Inflated surface — fingermap overlay (ses-01 execution) to verify hand area
#
# Usage:
#   ./view_handknob.sh <subID>
#   ./view_handknob.sh sub-0457
#
# What to look for (T1 axial window):
#   - Characteristic omega (Ω) or epsilon (ε) shape on the precentral gyrus
#   - Left hemisphere = right side of screen (radiological convention)
#   - ~35-45 mm lateral of midline, just anterior to the central sulcus
#
# Fingermap window:
#   - Coloured patch = finger representations (thumb→pink through pinky→blue)
#   - Your hand knob coordinate should fall inside this patch
#
# Once confirmed: read RAS from the T1 window status bar → record in handknob_coords.json
# =============================================================================

set -e

if [ -z "$1" ]; then
    echo "Usage: $0 <subID>  (e.g. sub-0457)"
    exit 1
fi

SUB="$1"

BIDS_DIR="/Users/hha243/Library/CloudStorage/Box-Box/sixthfinger-test"
FS_DIR="${BIDS_DIR}/derivatives/freesurfer/${SUB}"
FS_HOME="/Applications/freesurfer/8.1.0"
FREEVIEW="${FS_HOME}/bin/freeview"
FINGERMAP="${BIDS_DIR}/derivatives/Execution_native/${SUB}/ses-01/lh.fingermap_1.mgz"

if [ ! -d "${FS_DIR}" ]; then
    echo "ERROR: FreeSurfer directory not found: ${FS_DIR}"
    exit 1
fi

if [ ! -f "${FS_DIR}/mri/orig.mgz" ]; then
    echo "ERROR: T1 not found: ${FS_DIR}/mri/orig.mgz"
    exit 1
fi

# Prefer lh.pial.T1 (FreeSurfer 7+), fall back to lh.pial
if [ -f "${FS_DIR}/surf/lh.pial.T1" ]; then
    PIAL="${FS_DIR}/surf/lh.pial.T1"
elif [ -f "${FS_DIR}/surf/lh.pial" ]; then
    PIAL="${FS_DIR}/surf/lh.pial"
else
    echo "ERROR: LH pial surface not found"
    exit 1
fi

INFLATED="${FS_DIR}/surf/lh.inflated"
if [ ! -f "${INFLATED}" ]; then
    echo "ERROR: LH inflated surface not found: ${INFLATED}"
    exit 1
fi

echo "Opening Freeview for ${SUB}..."
echo ""
echo "  Window 1 (T1 axial): find the omega/epsilon shape, click crown, read RAS coords."
echo "  Window 2 (inflated + fingermap): verify your coordinate falls in the coloured hand patch."
echo ""

# ---- Single window: T1 + pial surface + fingermap overlay (all in RAS space) ----
if [ -f "${FINGERMAP}" ]; then
    "${FREEVIEW}" \
        -v "${FS_DIR}/mri/orig.mgz":colormap=grayscale \
        -f "${PIAL}:overlay=${FINGERMAP}:overlay_threshold=1,5:overlay_color=colorwheel" \
        -viewport axial \
        -ras -40 -20 57 \
        -zoom 2 \
        &
    echo "  Fingermap loaded — coloured edges will appear on the pial surface at the hand area."
else
    echo "  WARNING: Fingermap not found at ${FINGERMAP} — loading T1 only."
    "${FREEVIEW}" \
        -v "${FS_DIR}/mri/orig.mgz":colormap=grayscale \
        -viewport axial \
        -ras -40 -20 57 \
        -zoom 2 \
        &
fi

echo ""
echo "Freeview launched."

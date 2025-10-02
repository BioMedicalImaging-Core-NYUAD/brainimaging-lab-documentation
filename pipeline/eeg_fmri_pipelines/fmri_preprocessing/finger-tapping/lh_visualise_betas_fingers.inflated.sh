PROJECT_DIR=/home/hz3752/PycharmProjects/brainimaging-lab-documentation/pipeline/eeg_fmri_pipelines/fmri_preprocessing/finger-tapping

freeview \
  -f  "${BIDS_DIR}/freesurfer/sub-0665/surf/lh.inflated":\
overlay="${PROJECT_DIR}/lh.betas_thumb.mgz":overlay_threshold=0.1,1:overlay_color=255,0,0:\
overlay="${PROJECT_DIR}/lh.betas_index.mgz":overlay_threshold=0.1,1:overlay_color=0,255,0:\
overlay="${PROJECT_DIR}/lh.betas_middle.mgz":overlay_threshold=0.1,1:overlay_color=0,0,255:\
overlay="${PROJECT_DIR}/lh.betas_ring.mgz":overlay_threshold=0.1,1:overlay_color=255,165,0:\
overlay="${PROJECT_DIR}/lh.betas_pinkie.mgz":overlay_threshold=0.1,1:overlay_color=200,0,200 \
  -viewport 3d
# Requires freesurfer
#Check file info
mris_info $BIDS_DIR/freesurfer/sub-0665/surf/lh.inflated

# Visualise

freeview -f $BIDS_DIR/freesurfer/sub-0665/surf/lh.inflated


#Load all five fingers

freeview -f $BIDS_DIR/freesurfer/sub-0665/surf/lh.inflated




freeview \
  -f $BIDS_DIR/freesurfer/sub-0665/surf/rh.inflated \
     :overlay=/home/hz3752/PycharmProjects/brainimaging-lab-documentation/pipeline/eeg_fmri_pipelines/fmri_preprocessing/finger-tapping/load_data.m/rh.betas_thumb.mgz   :overlay_threshold=0.1,1 :overlay_color=255,0,0 \
     :overlay=/path/to/betas/rh.betas_index.mgz   :overlay_threshold=0.1,1 :overlay_color=0,255,0 \
     :overlay=/path/to/betas/rh.betas_middle.mgz  :overlay_threshold=0.1,1 :overlay_color=0,0,255 \
     :overlay=/path/to/betas/rh.betas_ring.mgz    :overlay_threshold=0.1,1 :overlay_color=255,128,0 \
     :overlay=/path/to/betas/rh.betas_little.mgz  :overlay_threshold=0.1,1 :overlay_color=200,0,200

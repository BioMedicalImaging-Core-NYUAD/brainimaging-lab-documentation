#!/bin/bash
#SBATCH --job-name=fmriprep_job
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=32G
#SBATCH --time=10:00:00  # Adjust the time limit as needed
#SBATCH --output=/scratch/hz3752/MRI/fingertapping/fmriprep_%A_%a.out
#SBATCH --error=/scratch/hz3752/MRI/fingertapping/fmriprep_%A_%a.err
#SBATCH --array=0  # Adjust this to match the number of subjects minus one

# Load Singularity module if necessary
module load singularity

USER=hz3752
PROJECT_NAME=fingertapping
# Define paths
SINGULARITY_IMG=/scratch/$USER/mysif/fmriprep_24.1.1.sif
BIDS_DIR=/scratch/$USER/MRI/$PROJECT_NAME/rawdata
OUTPUT_DIR=/scratch/$USER/MRI/$PROJECT_NAME/derivatives/fmriprep
FS_LICENSE=/home/$USER/license.txt

export TEMPLATEFLOW_HOME='/home/hz3752/.cache/templateflow'

# Get the list of subject IDs
SUBJECT_LIST=($(find ${BIDS_DIR} -maxdepth 1 -type d -name "sub-*" | sort | xargs -n 1 basename | sed 's/sub-//'))

# Get the subject ID for this array task
SUBJECT_ID=${SUBJECT_LIST[$SLURM_ARRAY_TASK_ID]}

# Path to FreeSurfer recon-all output
RECONALL_DIR=/scratch/$USER/MRI/$PROJECT_NAME/derivatives/freesurfer

# *** Set temporary working directory ***
#WORKDIR=/tmpdata/${SLURM_JOB_USER}/${SLURM_JOB_ID}/${SLURM_ARRAY_TASK_ID}
WORKDIR=/scratch/$USER/MRI/$PROJECT_NAME/tmpdata/${SLURM_JOB_USER}/${SLURM_JOB_ID}/${SLURM_ARRAY_TASK_ID}

mkdir -p ${WORKDIR}
mkdir -p ${RECONALL_DIR}
mkdir -p ${OUTPUT_DIR}
# Set environment variable for FreeSurfer license
export SINGULARITYENV_FS_LICENSE=${FS_LICENSE}

# Run fMRIPrep using Singularity
singularity run --cleanenv \
    -B ${BIDS_DIR}:/data:ro \
    -B ${OUTPUT_DIR}:/out \
    -B ${WORKDIR}:/work \
    -B ${RECONALL_DIR}:/reconall \
    ${SINGULARITY_IMG} \
    /data /out participant \
    --participant-label ${SUBJECT_ID} \
    --fs-subjects-dir /reconall \
    --skip_bids_validation \
    --output-spaces T1w:res-native fsnative:den-41k MNI152NLin2009cAsym:res-native fsaverage:den-41k fsaverage \
    --nthreads 32 \
    --mem_mb 32000 \
    --no-submm-recon \
    --work-dir /work



# Flag to change spaces:

# --output-space
# Optionally remove the workdir
rm -rf ${WORKDIR}
    
    

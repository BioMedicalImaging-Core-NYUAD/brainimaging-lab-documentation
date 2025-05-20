#!/bin/bash
#SBATCH --job-name=singularity_build
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=32G
#SBATCH --time=01:00:00
#SBATCH --error=log.err

module load singularity

export SINGULARITY_BUILD_NTHREADS=32
#export SINGULARITY_MKSQUASHFS_PROCS=1
# Debugging: Check if /scratch/h3752/mysif exists
echo "Checking if directory exists..."
ls -ld $SCRATCH/mysif/ || echo "Directory does NOT exist"

# Debugging: Print current working directory
echo "Current working directory: $(pwd)"

# Try to change directory
cd $SCRATCH/mysif/ || { echo "Failed to change directory"; exit 1; }

# If successful, continue
echo "Changed to $SCRATCH/mysif/"
singularity pull --force fmriprep_24.1.1.sif docker://nipreps/fmriprep:24.1.1

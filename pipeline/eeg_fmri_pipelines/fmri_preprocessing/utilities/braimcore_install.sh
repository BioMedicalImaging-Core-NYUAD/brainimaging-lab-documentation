module load NYUAD/4.0

module singularity/3.8.0

module braimcore/3.1

export BRAIMCORE_ENGINE=fmriprep

braimcore fetch_templates


export TEMPLATEFLOW_HOME='/home/hz3752/.cache/templateflow'
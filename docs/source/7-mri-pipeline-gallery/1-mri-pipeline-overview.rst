------------------
Pipelines Overview
------------------




EEG-fMRI pipelines
^^^^^^^^^^^^^^^^^^


Preprocessing your fMRI data
"""""""""""""""""""""""""""""

Your fMRI data will need to be preprocessed for distortion correction and movement correction before being able to do statistics.

There are different routes:

- preprocess on local computer
- preprocess on XNAT
- preprocess on HPC Jubail
- preprocess on MRI/MEG labs workstations


Preprocess on MRI/MEG labs workstations
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Your simultaneous EEG-fMRI data should be in BIDS format on NYU-BOX

- Write a config.json file under pipeline/fmri_pipelines/projects/PROJECT_NAME/config.json
    - an example is provided in pipeline/fmri_pipelines/template
- Submit a Pull Request to this repository with title "[Process] Project_NAME Data ..."
- This will automatically trigger a job to launch preprocessing using fMRIprep by utilising one of the labs workstations to perform the computation
- If sucessful the check will marked as successfull, if not review the log of the action and correct for any misconfiguration
- The procesing results will be uploaded to your project directory on NYU BOX

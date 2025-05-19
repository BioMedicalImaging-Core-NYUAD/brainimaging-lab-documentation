Finger tapping pipeline
=======================

.. contents:: Table of Contents
   :depth: 3
   :local:

Familiarise yourself with the generic pipeline first.

Preprocess EEG Data
-------------------

Setup your workspace
~~~~~~~~~~~~~~~~~~~~

- Create three folders in a directory, name them as follow
    - export: this will contain exported data from analysis pipeline
    - history: this will contain all processing steps
    - raw: put your raw .eeg, .vhdr, .vmrk here

- Open BrainVision Analyzer
- Press New then set the Raw, History and Export to the created folders above
    - your workspace is saved in a .wksp
- You should now see the datasets as folders in your Primary view



EEG data triggers
~~~~~~~~~~~~~~~~~

The EEG data from an EEG/fMRI experiment should have the following trigger signals

- `Sync On` of marker type `Sync Status` is a marker repeated every period of time ensuring that the MRI clock and EEG system are in sync
- `T 1_off` of marker type `Toggle` is a marker

    .. figure:: 0-generic-pipeline-figures/fig1.png
       :align: center
       :alt: Description of the image
       :width: 50%

       One TR (repetition time) corresponds to T 1_off - T 1_on.

- Paradigm-based triggers scripted from your experiment, for the finger-tapping experiment we programmed the `S1` marker to appear



Preprocess fMRI Data
--------------------

The fMRI data from the MRI scanner at NYUAD is in dicom format and will undergo multiple steps below:

- conversion from dicom to BIDS
-


fMRIprep output
~~~~~~~~~~~~~~~

fMRIprep outputs a directory, where the required fMRI data is found under

`/derivatives/fmriprep/sub-xyz/ses-01/func`



The output of fMRIprep pipeline is a `.gii` found in the above directory.



GLM learning from fMRIprep output
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- Learning a General Linear Model assumes that the observed data :math:`Y` can be explained as a linear transformation of :math:`X` and some random noise :math:`\epsilon`
    - this is plausible when the conditions should activate different areas of your brain
    - the GLM is learned per voxel or volume unit of a surface of interest
        - two ways we can think of:
            - learning one GLM for each voxel of the whole brain
            - learning one GLM for each volume unit of the grey matter surface of the brain

    .. math::

       Y = X.\beta + \epsilon

    - where
        - :math:`Y` is a matrix :math:`n\times k`
            - where :math:`n` is the number of TR's :math:`k` is the number of voxels
            - the order of the row values :math:`n` should be chronological
            - Remind that each value of the BOLD signal lasts for a TR time (in ms)
        - :math:`n`,is the length of :math:`Y` corresponds to the number of BOLD signal values obtained during the acquisition
            - if the experiment is 20 blocks, each block of duration 10 seconds then :math:`n = (20 \times 10) / TR`
        - :math:`X` is an :math:`n\times m`, binary matrix where :math:`m` is the number of predictors (conditions + noise reduction regressors)
            - :math:`X` aside from the conditions contains also vectors from the output of fmriprep that contains motion regressor (vector) and a drift cancelling (vector)
            - a cell at row k  :math:`X` has a 0 if the condition offset (means the stimulus is not present during this TR at row k)
            - a cell at row k of :math:`X` has a 1 if the condition onset (means the stimulus is present during this TR at row k)

        - :math:`\beta` is a matrix of size :math:`m\times k`, corresponding to the weights learnt for all voxels
            - for a single voxel, the weights are the same across the different TR's
            - the weights are different for each voxel (we can see this as learning multiple GLM's, one per voxel)
        - :math:`\epsilon` is the part of :math:`Y` that cannot be interpreted as a linear combination of :math:`X`
            - it represents the average noise at each BOLD value acquisition, and is therefore of size :math:`n`
    - assuming that the model would explain well the observed data when this model is a simple linear transformation, we would consequently like to find :math:`\beta` for which :math:`\epsilon` is minimal


- The design matrix :math:`X` of the finger-tapping experiment will have the following columns used as regressors:
    - involves five conditions (thumb, index, middle, ring, pinkie)
    - additional regressors output by fmriprep:
        - drift vector (a sequence of 1, 2, 3,..., n)
        - movement accounting vector (size n)



Source reconstruction at peak fMRI values for each condition
------------------------------------------------------------



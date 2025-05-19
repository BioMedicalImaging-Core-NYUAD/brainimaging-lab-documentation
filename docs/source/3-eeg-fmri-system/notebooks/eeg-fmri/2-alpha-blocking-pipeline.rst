Alpha-blocking pipeline
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

    .. figure:: 2-alpha-blocking-pipeline-figures/img_2.png
       :align: center
       :alt: Description of the image
       :width: 50%

       Importing the two alpha-blocking datasets into BrainVision Analyzer

EEG data triggers and sanity check
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The EEG data from an EEG/fMRI experiment should have the following trigger signals

- `Sync On` of marker type `Sync Status` is a marker repeated every period of time ensuring that the MRI clock and EEG system are in sync
- `T 1_off` of marker type `Toggle` is a marker

    .. figure:: 0-generic-pipeline-figures/fig1.png
       :align: center
       :alt: Description of the image
       :width: 50%

       One TR (repetition time) corresponds to T 1_off - T 1_on.

- Paradigm-based triggers scripted from your experiment, for the alpha-blocking experiment we programmed the `S1` marker to appear
- Perform a sanity check on the number of markers (trigger signals)

    .. figure:: 2-alpha-blocking-pipeline-figures/img.png
       :align: center
       :alt: Description of the image
       :width: 50%

       Right click your Raw data in primary view then `Markers` to do a sanity check on the number of markers.

- We had programmed 25 blocks per experiment starting with eyes open as first block
- A .csv produced from the MATLAB script holds the sequence and time of each block for sanity check

    .. figure:: 2-alpha-blocking-pipeline-figures/img_1.png
       :align: center
       :alt: Description of the image
       :width: 50%

       Under EEG-FMRI\Data\resting-state\sub-0665\matlab


- Once we checked that:
    - the number of triggers of each type is correct
    - the sync on is appearing throughout the acquisition
- we can then procceed with the analysis


Renaming the toggle markers
~~~~~~~~~~~~~~~~~~~~~~~~~~~

The markers for the TR (Repetition Time) in NYUAD's setting will be called T 1_on and T 1_off, we need to rename them all to T1 in order to check for any missed TR markers.

- Under `Transformations` pick `Edit markers`
- Put the following settings

    .. figure:: 2-alpha-blocking-pipeline-figures/img_3.png
       :align: center
       :alt: Description of the image
       :width: 50%

       Edit markers transformations all toggle marker will be called T1.

- Press `Finish`, check that all toggle markers are now called `T1`


Repetition Time (TR) Sanity Check
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- Make sure you have all the BrainProducts Solutions installed (these are separate from the software itself)
- Go to Solutions -> Views -> Marker Timing -> Set parameters as following

    .. figure:: 2-alpha-blocking-pipeline-figures/img_4.png
       :align: center
       :alt: Description of the image
       :width: 50%

       Compute timing between consecutive T1 markers to ensure they correspond to the TR.

    .. figure:: 2-alpha-blocking-pipeline-figures/img_5.png
       :align: center
       :alt: Description of the image
       :width: 50%

       The used TR of 750ms corresponds to the max and min different of successive T1's.

- The result is displayed as an extra step in the processing tree and is correct, the used TR was indeed of 750ms during the whole experiment
    - Sanity check is therefore checked

    .. hint::

        You can reproduce the same analysis steps for another dataset by clicking and dragging the step node in the `history tree` onto the other dataset.
        The history files have an `.ehtp` extension.
        To load the files in click on History Template → Open → select history tree file → drag and drop history tree onto data node of interest.

Gradient artifact correction
~~~~~~~~~~~~~~~~~~~~~~~~~~~~
- After performing sanity checks, the first step is to perform the gradient artifact correction using `MR correction`
- The gradient artifact is periodic and predictable
    - Every period, corresponds to he acquisition of one Bold signal value
    - The idea is to consider the first three volumes and average them together, then substract in the subsequent windows the average (performed for each EEG channel)
    - Artifacts will be seen stronger on the peripheral channels (closer to the MRI magnet) than in the center of the magnet
- Before applying the MR correction, check data for saturation
    - Saturation happens when the allocated analog bandwidth for the signal was not enough to display the signal fully
    - Use the butterfly plot to display the data at two Repetition Times (TR)

    .. figure:: 2-alpha-blocking-pipeline-figures/img_7.png
       :align: center
       :alt: Description of the image
       :width: 50%

       Butterfly plot (this is not the alpha-blocking data) over two TR's, used for saturation sanity check, clipping (e.g.,saturation) is pointed to in red.


    - Right click the data, Switch View -> Butterfly View

    .. figure:: 2-alpha-blocking-pipeline-figures/butterfly_plot.png
       :align: center
       :alt: Description of the image
       :width: 50%

       Butterfly plot for the alpha-blocking data over two TR's, saturation can be seen on the ECG electrode can be seen for this participant.

- Observe that when the gradient coils are activated a noise pattern is induced, it is an artifact that requires removal

    .. figure:: 2-alpha-blocking-pipeline-figures/img_6.png
       :align: center
       :alt: Description of the image
       :width: 50%

       EEG data prior and after gradient coil activation.


- MR correction can now be applied
    - Under Transformations go to `Special Signal Processing` then `MR Correction`
    - Use Markers -> T1
    - Artifact Type is always Continuous (interleaved was an old thing when MRI was collected for a period of time and then EEG for another period of time)
    - Enable Baseline correction for average( Compute baseline over the whole artifact)
    - Use sliding average calculation (to account for changes of gradient artifacts with time )
    - Use a value of 21 (empirical evidence)
    - Do not select Common use of all channels for bad intervals and correlation
    - Then next: select all EEG channels (only time we don’t use al chaness if we are measuring ta specific thing )

    .. figure:: 2-alpha-blocking-pipeline-figures/img_8.png
       :align: center
       :alt: Description of the image
       :width: 50%

       MR correction, selection of EEG channels.

- Then next, deselect downsampling we can do this later
- How to store data, next: Select sotre corrected data in cached file
- The MR correction will now take place and can take some time

    .. figure:: 2-alpha-blocking-pipeline-figures/img_9.png
       :align: center
       :alt: Description of the image
       :width: 50%

       Alpha-blocking data after MR correction.


- It can make sense at this point to compare the frequency content (using FFT) of the data at the static field and the data after MR correction
    - They should have comparable frequency components

50 Hz notch filter
~~~~~~~~~~~~~~~~~~



Cardioballistic artifact correction
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- Once the gradient artifact is cleaned, we can procceed with cleaning the cardioballistic artifact using the ECG signals:
- A sliding average substraction approach is used for the correction (Not ICA),  ICA if there is maybe a residual
- We do not have markers on the peaks, (this is needed for the substraction method)
- We need to add R peaks (peaks on the ECG signals)
- The ECG signal will be used as a template
- After the gradient artifact correction, some high frequency noise stays in the ECG channel during MRI acquisition
    - So we need to apply High Cut off Frequency  Go to transformations then IIR filter then disable the Low cutoff and High cutoff of all channels then select only the ECG channel and apply a high cut off 15 Hz filter, then apply filter
    - Then transformations, special signal processing then cb correction
    - Choose the ECG channel (when it is clear heartbeat if not use another EEG channel that can show a clearer one than ECG)
    - Go through the manual check if the automatic analyser skipped some R peaks
    - After selecting all the R peaks which should be marked in Green, then click Finish
    - Then the R peaks should appear on the peaks as R
    - Then go to special signal processing and select CB, and then select use markers then select R markers
    - Then go next and then use whole data to compute the time delay, again the total number of pulse is the sliding signal window also empirically we use the 21 as parameters
    - Select all EEG channels except for CWL and ECG channel


In the currently acquired dataset, the ECG electrode has not been glued properly therefore we cannot perform the ECG correction.

Defining trial segments Eyes Open/Eyes closed
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Remind that each experiment has 25 blocks in alternating sequence starting with eyes open and then eyes closed.

- We need to use the Segmentation Wizard to define our trial segments
- However we have only one marker S1 for both types
    - Go to Transformations, Edit Markers, Table
    - Rename the Eyes Closed Block to S2 (this is done manually for now, we are checking how to automate this)
    - Press Finish
    - Verify that the markers are now correctly renamed
- We can now define our segments
    - Go to Transformations then Segment Analysis and Functions then Segmentation
    - Create New segment based on marker position
    - Press Next, Select S 1, then Next, define the trial duration as 12 seconds (since the participant was asked to keep eyes closed or open for 12 seconds)
    - The segments are defined per channel for Eyes Open
    - Repeat the same steps for Eyes Closed, rename the segments in the history tree accordingly


Spectral analysis using FFT and contrasting conditions
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- For each type of trials, compute the FFT
    - Go to Transformations, Frequency and Component Analysis then FFT

    .. figure:: 2-alpha-blocking-pipeline-figures/alpha_peak_comparison.png
        :align: center
        :alt: Description of the image
        :width: 50%

        Alpha-peak comparison on Pz electrode (Left side: eyes closed, Right side: eyes open).




Preprocess fMRI data
--------------------

Accessing data on XNAT and running fMRIprep pipeline on Jubail
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- Login to `XNAT <https://xnat.abudhabi.nyu.edu/>`_.
- Make sure you have access to XNAT from your `@nyu` gmail account
- Make sure you have permission to access the project under which your fMRI data has been acquired
    - if you cannot see the project, request access from the XNAT administrators
- On XNAT you will need
    - fmap AP / PA (anterior posterior, posterior anterior) it is the direction of data acquisition (reverse phase encoding)
        - acquired when participant is in the scanner
        - they are used for distortion correction (topup algorithm for example by fsl)
        - usually we have two files per session of fMRI
        - these are input for the fMRI prep (and any fMRI processing pipeline)

- the input for fMRIprep pipeline is
    - the anatomical T1 of the participant (used for coregistering the fMRI with the anatomy of the person from T1) (1 item)
    - the two fmap AP/PA (called field maps) (two items)
        - fmap_acq-se_run-01_dir-AP_topup
        - fmap_acq-se_run-02_dir-PA_topup
    - the single band ref in PA and AP (two items) named
        - func-bold_task-SBref_run-02_dir-PA
        - func-bold_task-SBref_run-01_dir-AP
    - the bold runs named (two items because we done two sessions of resting state for this participant)
        - func-bold_task-restingstate_eeg_run-03
        - func-bold_task-restingstate_eeg_run-04
- Sanity checks:
    - check the size of the files (bold files should be around 600 mb+ for example)
    - check the number of the files (it is 402 for the bold resting state that we acquired)

- to run fMRI prep we need to
    - dicom2bids first
        - Run preprocessing pipeline, choose dicom2bids session
        - Pydeface (remove the face of the person)
        - run the pipeline
        - check the status scroll bottom down reload the history and see the status of the job (click the eye icon)
        - Once the job is complete go to Manage Files and view the new BIDS structure
    - we can now press fmriprep
        - fmriprep flag (to customise the pipeline)
        - we need a T1 to run the pipeline however it is not in the session so we need to pull it from another session
        - we ran fmriprep without the T1, just to see (usualy there is a global project called `anat` that holds all the anatomicals of the subjects)
        - update: T1 was not present when we executed fmriprep so we need to rerun it after adding the T1




GLM learning from fMRIprep output
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

- the design matrix of the alpha-blocking experiment involves

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





Ways to improve the pipeline
============================

- Define a specific type of marker for each condition instead of one marker type for all conditions (even if we know the sequence from the design matrix, but this will make the pre-processing in analyzer faster)
- Ensure that the ECG electrode is well gelled, and picking high R peaks when outside the MRI scanner room

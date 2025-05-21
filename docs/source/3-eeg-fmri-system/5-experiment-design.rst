.. _eeg-fmri-experiment:


-----------------
Experiment design
-----------------

Designing your EEG-fMRI experiment
==================================

Multiple things have to be taken into account while designing your EEG-fMRI experiment.

Before that, identify your research question and why it is relevant to use EEG-fMRI
for the research question.


Ensure that:


- You will be using the MRI sequences specific for the EEG-fMRI
    - the radiographer responsible with the data acquisition will help explain what is the best protocol used for EEG-fMRI and provide you with the details
    - you will have to determine the duration of each fMRI acquisition block (typically 10-20 seconds), each block determines one same condition from your paradigm
- You know your TR (Repetition Time) (in ms) time as you will need this value in the analysis pipeline, the shortest TR possible is 750ms
- When designing an EEG-fMRI experiment
    - ensure that you have a jitter (random time) before showing stimulus at the beginning of every TR, if this is not the case, one of the gradient artifact filters might delete important ERP's from your EEG data
    - analyse the trade-off between a high spatial resolution and less number of trials (EEG/fMRI experiment) with a high number of trials (pure EEG experiment)
        - as a matter of fact, the length of an experiment using EEG-fMRI will have less trials than using EEG alone
        - therefore, frequency analysis of the EEG data in an EEG-fMRI experiment is more useful than time-lock analysis
- You know the total duration of your experiment
    - The maximum duration for your experiment should not exceed X value

.. important::

   Always add a random duration of time before showing stimulus at the beginning of each TR


Example Experiments EEG-FMRI
----------------------------


.. nbgallery::
    :name: rst-gallery
    :glob:

    ../5-mri-experiments-gallery/experiments/eeg-fmri/*



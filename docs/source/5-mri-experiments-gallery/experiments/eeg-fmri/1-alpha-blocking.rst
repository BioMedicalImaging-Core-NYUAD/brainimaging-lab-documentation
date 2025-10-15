Alpha blocking experiment
=========================

Author: Hadi Zaatiti <hadi.zaatiti@nyu.edu>

Description
^^^^^^^^^^^

In this experiment, the participant will close their eye 12 seconds and then open for 12 seconds.
This is repeated as blocks for 25 times.

- each experiment is 25 blocks
- each block is 12 seconds duration
    - Block of type 0 is: eyes closed
    - Block of type 1 is: eyes open
    - the first block is eyes open and then followed by eyes closed and alternating
- the same marker `S1` is sent at the beginning of each block
- data has been acquired one same subject for two experiments i.e., 50 blocks in total


Code access
^^^^^^^^^^^

Full directory
""""""""""""""

:github-file:`experiments/EEG-FMRI/resting-eye-closed-eye-open`


Snapshot of main file to run
""""""""""""""""""""""""""""

.. dropdown:: Alpha blocking task code

    .. literalinclude:: ../../../../../experiments/EEG-FMRI/resting-eye-closed-eye-open/main.m
      :language: matlab


Data access
^^^^^^^^^^^

EEG
"""

Acquired datasets are stored safely on NYU Box under `resting-state`.

`MEG Data Directory <https://nyu.box.com/v/eeg-fmri-data>`_


fMRI data
"""""""""

fMRI data is hosted on XNAT

.. admonition:: Link to MRI data (Access given after requesting and upon eligibility)

    `https://xnat.abudhabi.nyu.edu/#/login <https://xnat.abudhabi.nyu.edu/#/login>`_
    Contact the xnat administrator `admin.nyuad.xnat@nyu.edu`


Analysis results
^^^^^^^^^^^^^^^^

A generic pipeline is being built and documented here:

:ref:`generic_pipeline`



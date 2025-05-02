LCModel Control File and Running LCModel
=====================================

Control File Overview
-------------------

The LCModel control file is a plain-text file that contains parameters controlling the LCModel analysis. Running LCModel without its GUI (i.e., from the terminal) is recommended for speed and efficiency. This approach also encourages learning the nuances of the control file parameters (see LCModel manual Section 5.3).

Example Control File
------------------

.. code-block:: text

   $LCMODL
     key=210387309
     nunfil=1024
     title='NYUAD Siemens 3T Phantom (PRESS, TE=30ms)'
     filbas='/Users/SH7437/Desktop/LC/phantom.BASIS'
     filraw='/Users/SH7437/Desktop/LC/suppressed.RAW'
     filps='/Users/SH7437/Desktop/LC/phantom_results.ps'
     filh2o='/Users/SH7437/Desktop/LC/unsuppressed.RAW'
     doecc = T
     nsimul = 0
     hzpppm = 123.238898
     deltat = 0.0008334
   $END

Explanation of Key Parameters
--------------------------

* **key:** Unique identifier for the run
* **nunfil:** Number of unfilled points
* **title:** Descriptive title of the study
* **filbas:** Full path to the basis file
* **filraw:** Full path to the suppressed raw data file
* **filps:** Full path for the output PostScript results file
* **filh2o:** Full path to the unsuppressed water data file
* **doecc:** Boolean flag for eddy current correction
* **hzpppm:** Frequency in parts per million
* **deltat:** Time between data points

Running LCModel from the Terminal
------------------------------

Compile and run LCModel from the terminal (without the GUI) using the compiled binary. This method significantly speeds up processing and allows for easier batch processing. To recompile from source, refer to the LCModel manual and available online instructions. The recommended practice is to write valid control files and run LCModel in terminal mode. 
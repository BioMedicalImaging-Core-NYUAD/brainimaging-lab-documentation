------------
Contributing
------------

After building an initial draft of your experiment code and you wish to start testing it, collect all the files relative to your experiment into one directory, name your directory as the name of your experiment.
The contribution will be submitted for review through github. If you already have a github account sign in to it, if not create a github account.

- Fork the current repository to your account
- On the created fork, create a new branch named with the feature you are developping or change you are making
- Add the directory containing the files of your experiment under the `experiments`.
- Create a pull request from your branch from your forked repository into the main branch of the source repository (origin)
- Add any comments you want the reviewer to know of
- A reviewer will review your code and either approve or ask for changes
- If changes are needed, make the changes and push your new code to the same branch, your PR (Pull Request) will then get automatically updated
- Consider adding a page describing your experiment to the `docs\source\5-mri-experiments-galleryh\experiments`
- Once your branch is merged to the main branch (meaning your experiment is approved), your code will be available in the MEG lab Stimulus computer

Building your processing pipeline
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Do the same steps as before to fork the repository and create a new branch named as `experiment_name-analysis`
Submit an initial notebook under `docs/source/7-mri-pipeline-gallery/notebooks` or simply code file for your pipeline under `pipeline\experiment_name`



Contributing to the documentation
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Your contribution, mistake correction, code contributions are very welcome.
Contributions are made through pull reqests, please do the following steps:

- Fork the current repository to your account
- Create a new branch named with the feature you are developping or change you are making
- Make the change on that branch
- Create a pull request from this branch  to the main brach
- Wait until your pull request is approved, or commented on
- Address all comments until the PR is approved
- Once the PR is merged to the main branch, delete your branch


Sphinx header templates
^^^^^^^^^^^^^^^^^^^^^^^


If you'd like to contribute to this documentation, please follow the heading-adornment conventions below:

+---------------------+------------------------+----------------+------------+
| Level               | Overline & Underline   | Underline only | Character  |
+=====================+========================+================+============+
| Document title      | ``=============``      | N/A            | ``=``      |
+---------------------+------------------------+----------------+------------+
| Top-level section   | ``-------------``      | ``-----------``| ``-``      |
+---------------------+------------------------+----------------+------------+
| Sub-section         | N/A                    | ``^^^^^^^^``   | ``^``      |
+---------------------+------------------------+----------------+------------+
| Sub-sub-section     | N/A                    | ``""""""""``   | ``"``      |
+---------------------+------------------------+----------------+------------+
| Fourth-level        | N/A                    | ``~~~~~~~~``   | ``~``      |
+---------------------+------------------------+----------------+------------+
| Fifth-level         | N/A                    | ``++++++++``   | ``+``      |
+---------------------+------------------------+----------------+------------+

Thank you for your contribution!


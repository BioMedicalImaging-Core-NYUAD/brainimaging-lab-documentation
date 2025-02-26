MRI Data Acquisition Workflow
=============================

Below is a flowchart describing a typical MRI data acquisition process:

.. mermaid::

    graph TD;
    A[🎓 <b>User arrives at MRI lab</b>] -->|Start| B[🧪 <b>Complete Experiment Request Form</b>];
    B --> C[<b>Prepare code (Psychtoolbox)</b>];
    C --> D[<b>Test Code on Stimulus computer in MRI lab</b>];
    D --> E[<b>Test Experiment timing with MRI scanner</b>];

    %% Clickable Node for Google Drive file
    click B "https://drive.google.com/file/d/10Py1KSAsktpCjU6c3lLuWLqVL2a5ofee/view?usp=drive_link"

    %% Style Definitions

    classDef process fill:#2196F3,stroke:#1976D2,color:#fff;

    class A,B,C,D,E process;





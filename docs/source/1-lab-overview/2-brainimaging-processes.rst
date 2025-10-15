---------
Processes
---------



Process for new MRI user
^^^^^^^^^^^^^^^^^^^^^^^^

.. mermaid::

  graph TD;
    B[🧪 <b>Complete New MRI Project Request</b>];
    B --> C[<b>User designs experimental code</b>];
    B --> D[<b>Complete MRI Safety Training Level 2</b>];
    C --> E[<b>Request access from <a href="mailto:haidee.paterson@nyu.edu">haidee.paterson@nyu.edu</a></b>];
    D --> E;
    E --> F[<b>Access 1 - CTPSS calendar</b>];
    E --> G[<b>Access 2 - NYUAD Prisma MRI Schedule</b>];
    E --> H[<b>Access 3 - Card Access to Appropriate MRI Zones</b>];
    F --> I[⏱️ <b>Time to test your code in the MRI lab</b>];
    G --> I;
    H --> I;
    I --> J[<b>Schedule testing time on both CTPSS calendar and NYUAD Prisma MRI Schedule</b>];
    J --> K{🧲️ <b>Does Code Work?</b>};
    K --✅ Yes --> L[<b>Finalize experimental design and participant booking with radiographers</b>];
    L --> M[🏆 <b>Ready to begin recruiting</b>];


    %% Clickable Nodes
    click B "https://drive.google.com/file/d/10Py1KSAsktpCjU6c3lLuWLqVL2a5ofee/view?usp=drive_link"
    click D "https://app.imagingu.com/courses/personnel-group-ii-yearly"
    click E "mailto:haidee.paterson@nyu.edu" "Email haidee.paterson@nyu.edu"
    click F "https://corelabs.abudhabi.nyu.edu/"

    %% Style Definitions
    classDef success fill:#4CAF50,stroke:#2E7D32,color:#fff;
    classDef decision fill:#FFEB3B,stroke:#FBC02D,color:#000;
    classDef process fill:#2196F3,stroke:#1976D2,color:#fff;
    classDef warning fill:#FF5722,stroke:#E64A19,color:#fff;

    class B,C,D,F,G,H,J,L,M process;
    class I warning;
    class K decision;


MRI lab flowchart
^^^^^^^^^^^^^^^^^


.. mermaid::
   :align: center
   :caption: "MRI Lab Flowchart"

   flowchart TB
       A("User arrives at MRI lab") --> B("Start")
       B --> C("Design Experiment")
       C --> D("Present")
       D --> E("Present Research")
       E --> F("Submit")
       F --> G("Submit Draft Code via Pull Request")
       G --> H("Review")
       H --> I("Code Reviewed")
       I --> J{"Does Code Work?"}

       J -- No --> K("Iterate & Revise Code")
       J -- Yes --> L("Keep Testing Code")

       %% Show the 'Resubmit' loop from Review to Submit
       H -- Resubmit --> F

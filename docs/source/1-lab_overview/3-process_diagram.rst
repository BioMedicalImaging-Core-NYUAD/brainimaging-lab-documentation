MRI Data Acquisition Workflow
=============================

Below is a flowchart describing a typical MRI data acquisition process:

Process for new MRI user
========================

.. mermaid::

    graph TD;
        A[🎓 <b>User arrives at MRI lab</b>] -->|🚀 Start| B[🧪 <b>Complete New MRI Project Request</b>];
        B --> C[<b>User designs experimental code</b>];
        C --> D[<b>Complete MRI Safety Training Level 2</b>];
        D --> E[<b>Submit Draft Code via Pull Request</b>];
        E --> F[✅ <b>Code Reviewed</b>];
        F --> G{🧲️ <b>Does Code Work?</b>};
        G --✅ Yes --> H[🔬 <b>Keep Testing Code</b>];
        H -->|🏆 Success| I[🎉 <b>Experiment Finalized</b>];

        %% Clickable Node for GitHub PR
        click B "https://drive.google.com/file/d/10Py1KSAsktpCjU6c3lLuWLqVL2a5ofee/view?usp=drive_link"
        click D "https://app.imagingu.com/courses/personnel-group-ii-yearly"

        %% Style Definitions
        classDef success fill:#4CAF50,stroke:#2E7D32,color:#fff;
        classDef decision fill:#FFEB3B,stroke:#FBC02D,color:#000;
        classDef process fill:#2196F3,stroke:#1976D2,color:#fff;
        classDef warning fill:#FF5722,stroke:#E64A19,color:#fff;

        class A,B,C,D,E,H process;
        class F decision;
        class G warning;
        class I success;





MRI Data Acquisition Workflow
=============================

Below is a flowchart describing a typical MRI data acquisition process:

.. mermaid::

.. mermaid::

    graph TD;
        A[🎓 <b>User arrives at MRI lab</b>] -->| Start| B[🧪 <b>Complete Experiment Request Form</b>];
        B --> C[<b>Present Research</b>];
        C -->|📂 Submit| D[💻 <b>Submit Draft Code via Pull Request</b>];
        D -->|🔍 Review| E[✅ <b>Code Reviewed</b>];
        E -->|🤔 Decision| F{⚖️ <b>Does Code Work?</b>};

        F --❌ No --> G[🔄 <b>Iterate & Revise Code</b>];
        G -->|📂 Resubmit| D;

        F --✅ Yes --> H[🔬 <b>Keep Testing Code</b>];
        H -->|🏆 Success| I[🎉 <b>Experiment Finalized</b>];

        %% Clickable Node for GitHub PR
        click B "https://drive.google.com/file/d/10Py1KSAsktpCjU6c3lLuWLqVL2a5ofee/view?usp=drive_link"
        %% Style Definitions
        classDef success fill:#4CAF50,stroke:#2E7D32,color:#fff;
        classDef decision fill:#FFEB3B,stroke:#FBC02D,color:#000;
        classDef process fill:#2196F3,stroke:#1976D2,color:#fff;
        classDef warning fill:#FF5722,stroke:#E64A19,color:#fff;

        class A,B,C,D,E,H process;
        class F decision;
        class G warning;
        class I success;





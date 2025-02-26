MRI Data Acquisition Workflow
=============================

Below is a flowchart describing a typical MRI data acquisition process:

Process for new MEG user
========================

.. mermaid::

    graph TD;
        A[🎓 <b>User arrives at MEG lab</b>] -->|🚀 Start| B[🧪 <b>Design Experiment</b>];
        B --> C[📝 <b>Present Research</b>];
        C --> D[💻 <b>Submit Draft Code via Pull Request</b>];
        D --> E[✅ <b>Code Reviewed</b>];
        E --> F{⚖️ <b>Does Code Work?</b>};
        F --✅ Yes --> H[🔬 <b>Keep Testing Code</b>];
        H -->|🏆 Success| I[🎉 <b>Experiment Finalized</b>];

        %% Clickable Node for GitHub PR
        click D "https://github.com/Hzaatiti/meg-pipeline/pulls" "Visit GitHub Repository"

        %% Style Definitions
        classDef success fill:#4CAF50,stroke:#2E7D32,color:#fff;
        classDef decision fill:#FFEB3B,stroke:#FBC02D,color:#000;
        classDef process fill:#2196F3,stroke:#1976D2,color:#fff;
        classDef warning fill:#FF5722,stroke:#E64A19,color:#fff;

        class A,B,C,D,E,H process;
        class F decision;
        class G warning;
        class I success;





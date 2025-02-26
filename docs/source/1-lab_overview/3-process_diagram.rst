
Process for new MRI user
========================

.. mermaid::

  graph TD;
    A[🎓 <b>User arrives at MRI lab</b>] --> B[🧪 <b>Complete New MRI Project Request</b>];
    B --> C[<b>User designs experimental code</b>];
    B --> D[<b>Complete MRI Safety Training Level 2</b>];
    C --> E[<b>Request access from <a href="mailto:haidee.paterson@nyu.edu">haidee.paterson@nyu.edu</a></b>];
    D --> E;
    E --> F[✅ <b>Code Reviewed</b>];
    F --> G{🧲️ <b>Does Code Work?</b>};
    G --✅ Yes --> H[🔬 <b>Keep Testing Code</b>];
    H -->|🏆 Success| I[🎉 <b>Experiment Finalized</b>];

    %% Clickable Nodes
    click B "https://drive.google.com/file/d/10Py1KSAsktpCjU6c3lLuWLqVL2a5ofee/view?usp=drive_link"
    click D "https://app.imagingu.com/courses/personnel-group-ii-yearly"
    click E "mailto:haidee.paterson@nyu.edu" "Email haidee.paterson@nyu.edu"

    %% Style Definitions
    classDef success fill:#4CAF50,stroke:#2E7D32,color:#fff;
    classDef decision fill:#FFEB3B,stroke:#FBC02D,color:#000;
    classDef process fill:#2196F3,stroke:#1976D2,color:#fff;
    classDef warning fill:#FF5722,stroke:#E64A19,color:#fff;

    class A,C,D,F,G,H,I process;





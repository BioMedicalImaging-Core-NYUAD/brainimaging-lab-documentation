MRI Data Acquisition Workflow
=============================

Below is a flowchart describing a typical MRI data acquisition process:

.. mermaid::

flowchart TD
    A[Patient Registration & Scheduling]
    B((Screening for Contraindications))
    C{Patient Preparation & Consent}
    D(Patient Positioning)
    E[[Localizer/Scout Scans]]
    F[Pulse Sequence Selection]
    G((MRI Data Acquisition))
    H{Image Reconstruction}
    I(Quality Control & Post-Processing)
    J[[Diagnostic Interpretation]]
    K[Reporting & Archiving]

    A --> B
    B --> C
    C --> D
    D --> E
    E --> F
    F --> G
    G --> H
    H --> I
    I --> J
    J --> K

    %% Class Definitions for styling
    classDef rect fill:#f9f,stroke:#333,stroke-width:2px;
    classDef circle fill:#ccf,stroke:#f66,stroke-width:2px;
    classDef diamond fill:#cfc,stroke:#393,stroke-width:2px;
    classDef round fill:#ffc,stroke:#993,stroke-width:2px;
    classDef subroutine fill:#cce,stroke:#633,stroke-width:2px;

    %% Assign classes to nodes based on their shape
    class A,F,K rect;
    class B,G circle;
    class C,H diamond;
    class D,I round;
    class E,J subroutine;



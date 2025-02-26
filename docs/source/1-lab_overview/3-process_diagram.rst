MRI Data Acquisition Workflow
=============================

Below is a flowchart describing a typical MRI data acquisition process:

.. mermaid::

graph TD
    A[Patient Registration & Scheduling] --> B[Screening for Contraindications]
    B --> C[Patient Preparation & Consent]
    C --> D[Patient Positioning]
    D --> E[Localizer/Scout Scans]
    E --> F[Pulse Sequence Selection]
    F --> G[MRI Data Acquisition]
    G --> H[Quality Control & Post-Processing]
    H --> I[Diagnostic Interpretation]
    I --> J[Archiving]
    J --> K[Send images for reporting]

classDef rectangle fill:#FFB6C1,stroke:#000,stroke-width:1px;
classDef triangle fill:#B0E0E6,stroke:#000,stroke-width:1px;

class A,C,E,G,I,K rectangle;
class B,D,F,H,J triangle;



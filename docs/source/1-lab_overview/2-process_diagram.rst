MRI Data Acquisition Workflow
=============================

Below is a flowchart describing a typical MRI data acquisition process:

.. mermaid::

    graph TD
        A((Patient Registration & Scheduling)) --> B[/Screening for Contraindications/]
        B --> C[[Patient Preparation & Consent]]
        C --> D{Patient Positioning}
        D --> E((Localizer/Scout Scans))
        E --> F[/Pulse Sequence Selection/]
        F --> G[[MRI Data Acquisition]]
        G --> H{Quality Control & Post-Processing}
        H --> I((Diagnostic Interpretation))
        I --> J[/Archiving/]
        J --> K[[Send images for reporting]]

        style A fill:#FFDAB9,stroke:#000,stroke-width:1px
        style B fill:#98FB98,stroke:#000,stroke-width:1px
        style C fill:#ADD8E6,stroke:#000,stroke-width:1px
        style D fill:#FFC0CB,stroke:#000,stroke-width:1px
        style E fill:#FFFFE0,stroke:#000,stroke-width:1px
        style F fill:#E6E6FA,stroke:#000,stroke-width:1px
        style G fill:#87CEFA,stroke:#000,stroke-width:1px
        style H fill:#F0E68C,stroke:#000,stroke-width:1px
        style I fill:#FFA07A,stroke:#000,stroke-width:1px
        style J fill:#90EE90,stroke:#000,stroke-width:1px
        style K fill:#D8BFD8,stroke:#000,stroke-width:1px




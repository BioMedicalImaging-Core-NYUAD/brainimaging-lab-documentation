.. mermaid::
   :align: center
   :caption: "MEG Lab Flowchart"

   flowchart TB
       A("User arrives at MEG lab") --> B("Start")
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

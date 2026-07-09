--------------------
System specification
--------------------


3T Siemens Prisma MRI Scanner
*****************************

.. figure:: ../_static/mri_scanner_inside.png
   :alt: mri scanner inside image
   :width: 800px
   :align: center

   Figure 1. MRI scanner at NYU Abu Dhabi

NYU Abu Dhabi’s MRI lab features a 3T Siemens Prisma system.

Specifications
^^^^^^^^^^^^^^

    - **Field strength**: 3 Tesla
    - **Bore size**: 60 cm
    - **System length**: 213 cm
    - **System weight (in operation)**: 13 tons
    - **Gradient strength**: XR Gradients (139 mT/m8 @ 346 T/m/s8)
    - **Max. amplitude**: 139 mT/m8
    - **Max. slew rate**: 346 T/m/s8



Available coils
^^^^^^^^^^^^^^^

    - **Head/Neck 64**
      Ultra-fast, high SNR, head and neck imaging.

    - **32-Channel Head Coil**
      iPAT-compatible coil for fast high-resolution and advanced neuro imaging.

    - **Tx/Rx CP Head Coil**
      CP Send/Receive head coil with integrated preamplifier.

    - **Head/Neck 20**
      For examination of head and neck (brain, neck blood vessels, and C-spine).

    - **Body 18**
      Light-weight coil with SlideConnect® technology for easy coil set up and
      excellent patient comfort. Typically used with the Spine 32 for thorax,
      abdomen, pelvis, or hip exams. Also well suited for cardiac or vascular applications.

    - **Body 30**
      Flexible and comfortable coil for full Field of View coverage and patient comfort.
      Typically used for pelvis (particularly prostate), hip, abdomen, or thorax exams.
      Often combined with the Spine coil or other coils for cardiac/vascular applications.

    - **Tx/Rx Knee 15 Flare Coil**
      15-channel transmit/receive coil for high-resolution knee imaging, featuring
      a flared opening for better patient fit.

    - **4-Channel Flex Coils**
      Multipurpose coils for orthopedic imaging and other specialized applications.

    - **4-Channel Special-Purpose Coil**
      A no-tune receiver coil designed for small Field-of-View exams.

    - **Spine Matrix Coil**
      24-element design with 24 integrated preamplifiers, 8 clusters of 3 elements each.
      Integrated into the patient table, works with Head and Neck Matrix coils.



Stimulus Computer
*****************

Psychtoolbox
^^^^^^^^^^^^

Psychtoolbox is installed under:
- Version: 3.0.22 `Documents/Psychtoolbox_versions/Psychtoolbox-3.0.22.1`

Other versions exist as well.





Vpixx System
************

VPixx systems provide MRI researchers with tools that deliver precise, reliable, and highly synchronized visual and often auditory stimuli inside the scanning environment. In particular, the PROPixx projector’s long-throw lens options and robust design allow the device to be placed safely outside the MRI room while projecting clear, stable images into the bore. These systems also integrate trigger inputs/outputs and analog I/O so that the presentation of stimuli can be tightly coordinated with scanner pulses, ensuring that changes in brain activity, captured by MRI, line up exactly with the onset of visual or auditory events.

The system includes:

    - a PROPixx projector
    - an in-bore screen
    - left and right-hand response boxes
    - soundpixx

.. figure:: ../_static/vpixx.png
   :alt: vpixx
   :width: 800px
   :align: center

   Figure 3. VPixx System


Eyelink Eyetracker system
*************************

We have an SR Research Eyetracker system.


Network settings for Eyetracker system
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

+---------------------+-------------------+
| **Eyelink**         | **Connected**     |
+---------------------+-------------------+
| **IPv4 Configured** | Manually          |
+---------------------+-------------------+
| **IP address**      | 100.1.1.2         |
+---------------------+-------------------+
| **Subnet mask**     | 255.255.255.0     |
+---------------------+-------------------+
| **Router**          | Router            |
+---------------------+-------------------+
| **DNS Servers**     | DNS Servers       |
+---------------------+-------------------+
| **Search Domains**  | Search Domains    |
+---------------------+-------------------+


The Eyetracker is connected to the Stimulus computer on the bottom-most ethernet card in the Stimulus computer.


Installing the Eyetracker software and API
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

By default, the eyetracker .mex file within Psychtoolbox wouldn't work on the stimulus computer architecture.

- Download the Eyetracker API developper kit from the SR Research website after creating an account there
- Open MATLAB and attempt `EyelinkInit` command, the eyetracker should be working

Installation path on Stimulus computer
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

- The Eyelink Development kit is installed on the stimulus computer in the following path:
    - `Macintosh HD -> Eyelink`
    - `Macintosh HD -> Library -> Frameworks -> eyelink*`

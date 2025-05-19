Trigger Test Script for EEG-FMRI BrainProducts System
=====================================================

This MATLAB script is designed for **trigger testing** with the EEG-FMRI system from
BrainProducts. The script is useful for debugging,
validating marker signals, and troubleshooting signal pathways.

Sending a trigger signal involves the following steps:

- A trigger signal is sent from the `Stimulus computer` to the Vpixx hardware
- the Vpixx hardware sends the signal to the EEG-FMRI trigger box (BrainProducts)
- the trigger box sends the signal to the SyncBox (allowing to synchronise the trigger signal with the EEG data)

Purpose of script
-----------------

1. **Trigger Signal Testing**:
   - Generates and tests digital output signals from the VPixx system to the EEG-FMRI BrainProducts trigger box.
   - Validates that digital lines correctly activate corresponding pins on the EEG-FMRI system.

2. **Marker Validation**:
   - Tests if various markers (e.g., `S1`, `S2`, `S4`) are correctly received and displayed in the BrainProducts recording software.

3. **Debugging Tool**:
   - Useful for troubleshooting trigger signal pathways between the VPixx and BrainProducts systems.

.. dropdown:: Trigger test

    .. literalinclude:: ../../../../experiments/EEG-FMRI/general/trigger_test.m
      :language: matlab

You can also :download:`Download the file here <../../../../experiments/EEG-FMRI/general/trigger_test.m>`



Key Features
------------

1. **Initialization**:
   - Initializes the VPixx Datapixx hardware and ensures the Pixel Mode is disabled, (if left enabled the triggers will not work)

2. **Pin and Bit Mapping**:
    - Provides detailed mapping between:
    - VPixx digital outputs.
    - Corresponding pins on the EEG-FMRI trigger box.

3. **Bit-by-Bit Trigger Testing**:
    - Tests each digital output bit (0 to 7) to validate their functionality:
    - Turns each bit "on" to generate a trigger signal.
    - Verifies correct detection of the signal by the BrainProducts system.
    - Turns each bit "off" to confirm proper deactivation.

4. **Marker Testing**:
   - Activates and deactivates specific markers (`S1`, `S2`, `S4`, etc.) in a loop for a set duration to simulate trigger events.

5. **Customizable Timing**:
   - User-defined **total test duration** and **pause duration** between successive triggers.

6. **Detailed Logging**:
    - Real-time feedback in the MATLAB command window to indicate:
    - Active markers.
    - Digital output states (on/off).

7. **Shutdown Procedure**:
    - Ensures a clean shutdown of the VPixx Datapixx hardware:
        - Stops all ongoing schedules.
        - Closes the Datapixx connection.

Use Case
--------

- Designed for researchers and technicians working with EEG-FMRI setups.
- Validates trigger communication between the VPixx system and the BrainProducts trigger box to ensure accurate synchronization of EEG and MRI data.

Workflow to use this script correctly
-------------------------------------

1. **Setup**:
    - Connect the VPixx system to the BrainProducts EEG-FMRI trigger box via the d-sub 25 pin cable.
    - On the BrainProducts Windows computer open the BrainVision recorder app
        - When testing bits 0 to 7, open the Digital Output interface
        - When testing the S2, S4, ... markers, you will need the BrainProducts amplifier connected to the system
        - Once they are connected, record empty-room data (not necessarily saving it)
    - Run the script in MATLAB

2. **Trigger Testing**:
   - Follow on-screen instructions to test individual bits and markers.
   - Observe responses in the BrainProducts software or hardware.

3. **Validation**:
   - Verify appropriate markers (e.g., `S1`, `S2`) are received and displayed.

4. **Debugging**:
   - Use the script's output to identify and troubleshoot signal issues.

Outcome
-------

By running this script, the user ensures:

- Digital output from the VPixx system activates the corresponding pins on the BrainProducts trigger box.
- EEG markers (`S1`, `S2`, etc.) are recorded correctly for synchronizing EEG and MRI data.




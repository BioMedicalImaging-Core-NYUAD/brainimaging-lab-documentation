Organizing the Main Folder
========================

Folder Structure
--------------

Create a main folder (e.g., ``/Users/SH7437/Desktop/LC``) to host all files required by LCModel. This folder should include:

* **Control File:** A text file that instructs LCModel on how to process the data
* **Basis File:** The `.BASIS` file generated from MRSCloud
* **Raw Data Files:**
  * **Suppressed Water Data:** The `.RAW` file generated from the suppressed acquisition
  * **Unsuppressed Water Data:** The `.RAW` file for water reference data

Keeping these files organized in one location simplifies batch processing and minimizes errors during execution.

.. image:: ../_static/main.png
   :alt: LCModel folder structure
   :align: center 
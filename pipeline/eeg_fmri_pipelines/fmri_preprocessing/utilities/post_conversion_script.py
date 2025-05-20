#!/usr/bin/env python3

import os
import re
import glob
import shutil

def replicate_sbref(directory):
    """
    For each BOLD run in 'directory', replicate the existing PA SBRef files
    (both .nii.gz and .json) and rename them to match the run identifier,
    removing the 'dir-PA' indicator from the filename.
    Also, delete any AP direction files.
    """

    # Look for the PA sbref files (assumes exactly one set of PA sbref in the folder)
    pa_nii_list = glob.glob(os.path.join(directory, "*_dir-PA_sbref.nii.gz"))
    pa_json_list = glob.glob(os.path.join(directory, "*_dir-PA_sbref.json"))

    # Basic check for PA files
    if not (pa_nii_list and pa_json_list):
        print("Error: Could not find a matching set of PA sbref files.")
        return

    # For simplicity, take the first match in each list
    pa_nii = pa_nii_list[0]
    pa_json = pa_json_list[0]

    # Regex to identify BOLD run files
    # Example filename: sub-0065_task-fingertapping_run-01_bold.nii.gz
    bold_pattern = re.compile(r"^(sub-\d+)_task-([a-zA-Z0-9]+)_run-(\d+)_bold\.nii\.gz$")

    # Loop through files in the directory and look for BOLD runs
    for fname in os.listdir(directory):
        match = bold_pattern.match(fname)
        if match:
            sub_id = match.group(1)  # e.g., sub-0065
            task = match.group(2)    # e.g., fingertapping or restingstate
            run = match.group(3)     # e.g., 01, 02, 03

            # Construct the new SBRef filenames without the direction indicator
            new_sbref_nii = f"{sub_id}_task-{task}_run-{run}_sbref.nii.gz"
            new_sbref_json = f"{sub_id}_task-{task}_run-{run}_sbref.json"

            # Copy/replicate the original PA sbref files to new filenames
            shutil.copyfile(pa_nii, os.path.join(directory, new_sbref_nii))
            shutil.copyfile(pa_json, os.path.join(directory, new_sbref_json))
            print(f"Created SBRef for: {sub_id}, task={task}, run={run}")

    # Delete the original PA sbref files
    for pa_file in glob.glob(os.path.join(directory, "*_dir-PA_sbref.nii.gz")):
        os.remove(pa_file)
        print(f"Deleted original PA SBRef file: {pa_file}")
    for pa_file in glob.glob(os.path.join(directory, "*_dir-PA_sbref.json")):
        os.remove(pa_file)
        print(f"Deleted original PA SBRef file: {pa_file}")

    # Delete any AP direction files if they exist
    for ap_file in glob.glob(os.path.join(directory, "*_dir-AP_sbref.nii.gz")):
        os.remove(ap_file)
        print(f"Deleted original AP SBRef file: {ap_file}")
    for ap_file in glob.glob(os.path.join(directory, "*_dir-AP_sbref.json")):
        os.remove(ap_file)
        print(f"Deleted original AP SBRef file: {ap_file}")

if __name__ == "__main__":
    # Example usage: python replicate_sbref.py /path/to/data
    import sys
    if len(sys.argv) < 2:
        print("Usage: python replicate_sbref.py <directory>")
        sys.exit(1)

    data_dir = sys.argv[1]
    replicate_sbref(data_dir)

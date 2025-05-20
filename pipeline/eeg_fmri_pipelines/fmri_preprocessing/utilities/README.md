# config.json README

- add the ses prefix

Each bold run must have the sbref either PA or AP depending on the PhaseEncodingDirection
-    "PhaseEncodingDirection": "j", = PA (To verify)
- after local dicom2bids, remove the bids:: from the fmap .json file

## Local dicom2bids


Install pip pydeface
I would suggest the following —

1. **Identifying a location** (that Matlab and we all have access to) and create the project folder, delete unwanted scans (such as the duplicating incorrect runs, for example, the first fmap and sbref runs for this pilot data).

2. **Install `dcm2bids`** to do the manual conversion. You may use the same configure file.

3. **Post conversion manual correction**:
   - Copying `sbref` (needs to be as many runs as the functional `bold` runs) for each functional run.
   - Checking and fixing the `IntendedFor` field (in the JSON files that are in the `fmap` files).  
   - Can be done in Python or Matlab.

4. **Run BIDS Validator** (browser version).

5. **Copy BIDS data to Jubail**, don’t forget to also find and copy over the anatomicals, i.e., `T1w`.

6. **Set up and run fMRIPrep** on Jubail.

7. **Retrieve data from Jubail**.



## Configure your own `config.json`


criteria is how to filter the dicoms, by matching the sidecars
side_car changes means we are adding new information after dicom2bids


Use the provided template in this folder to define the key-value pairs.

- **Keep the `extractors` and `descriptions` as they are.**
- **Define your `func` datatype** using the structure below:

```json
{
  "id": "finger_tapping_run-02",
  "datatype": "func",
  "suffix": "bold",
  "custom_entities": "task-fingertapping_run-02",
  "criteria": {
    "ProtocolName": "*bold_task-fingertapping_run-02",
    "ImageType": ["ORIGINAL", "PRIMARY", "FMRI", "NONE"]
  },
  "sidecar_changes": {
    "TaskName": "fingertapping",
    "RepetitionTime": 1.0
  }
}
```

## Top-Level Keys

### `dcm2niixOptions`

A string that contains arguments passed to `dcm2niix` (the tool used under the hood by HeuDiConv to convert DICOM to NIfTI).

Common parameters:

- `-d 9`: Search subdirectories up to 9 levels deep for DICOM files.
- `-b y`: Generate a BIDS-compatible sidecar JSON (`.json`) file alongside the NIfTI.
- `-ba y`: Anonymize the BIDS sidecar JSON.
- `-z y`: Compress the NIfTI output into `.nii.gz` instead of an uncompressed `.nii`.
- `-f '%3s_%f_%p_%t'`: Specifies how the output files will be named based on DICOM fields.
  - The placeholders (`%3s`, `%f`, `%p`, `%t`) correspond to DICOM metadata (series number, filename, protocol, time, etc.).

### `case_sensitive`

- A Boolean (`true`/`false`) that specifies whether matching criteria (especially `SeriesDescription`, `ProtocolName`, etc.) should be treated with case sensitivity.
- If `true`, `SeriesDescription` must match exactly (e.g., `anat-T1w` is different from `ANAT-T1W`).

### `search_method`

- Defines how filenames or folder names are matched.
- Often set to `"fnmatch"`, which uses UNIX-style wildcard patterns (like `*`, `?`) to match strings.

### `dup_method`

Defines how to handle what the tool considers “duplicate” series. Possible values:

- `"skip"`: Skip duplicates entirely.
- `"run"`: Treat duplicates as different runs.
- `"combine"`: Combine duplicates into a single run.

### `compKeys`

- An array of DICOM or sidecar JSON fields that help the software decide if two scans are “duplicates.”
- Example:

```json
["SeriesNumber", "AcquisitionTime", "SidecarFilename"]
```

- If these three fields match between two DICOM series, they are considered duplicates.

### `post_op`

A list of instructions (commands) to run after the main conversion step.

Each item in the list includes:

- `"cmd"`: The actual shell command or script to run (e.g., `pydeface` to de-identify faces).
- `"datatype"` and `"suffix"`: Filter so that only specific BIDS types or suffixes are processed (e.g., deface only `anat` type with `T1w` or `FLAIR` suffix).

## `extractors` Section

- Defines regex (regular expression) patterns used to parse out additional BIDS entities from the DICOM metadata fields (`SeriesDescription`, `PhaseEncodedDirection`, etc.).
- Example: If your `SeriesDescription` is `task-fingertapping_run-01`, the extractor can pick out `task = fingertapping` and `run = 01`.

## `descriptions`: The Core Mapping Rules

The `"descriptions"` key is an array of rules that tell the conversion tool:

1. **Which scans to look for** (`criteria`)
2. **How to name them in BIDS** (`datatype`, `suffix`, etc.)
3. **Optional additional changes** (`sidecar_changes`) or **custom naming** (`custom_entities`)

### Common Fields in Each Rule

#### `id`

- An optional human-readable identifier for the rule.
- Useful for differentiating multiple rules for the same datatype.

#### `datatype`

- The top-level BIDS folder name (e.g., `anat`, `func`, `dwi`, `fmap`, `perf`, etc.).

#### `suffix`

- The BIDS suffix for the filename (e.g., `T1w`, `bold`, `dwi`, `asl`, etc.).
- Example output: `sub-001_task-rest_bold.nii.gz`.

#### `criteria`

- Defines the conditions that a DICOM series must meet to match this rule.
- Example:

```json
{
  "ProtocolName": "*bold_task-restingstate_run-01_dir-[aA][pP]",
  "MultibandAccelerationFactor": "[1-9]"
}
```

#### `custom_entities`

- Allows adding extra BIDS key-value pairs beyond the standard.
- Example:

```json
"custom_entities": "dir-AP"
```

- Results in filenames like `sub-001_task-rest_dir-AP_bold.nii.gz`.

#### `sidecar_changes`

- A dictionary of changes or additions to be forced into the BIDS sidecar JSON.
- Example:

```json
{
  "TaskName": "rest",
  "RepetitionTime": 0.7
}
```

- `"IntendedFor"` is commonly used in fieldmap (`fmap`) rules to link the fieldmap to a specific functional or diffusion scan.

## Concrete Examples in the Config

### **Anatomical T1w**

```json
{
  "datatype": "anat",
  "suffix": "T1w",
  "criteria": {
    "SeriesDescription": "anat-T1w"
  }
}
```

### **Diffusion AP**

```json
{
  "id": "dwi_AP",
  "datatype": "dwi",
  "custom_entities": "dir-AP",
  "suffix": "dwi",
  "criteria": {
    "SidecarFilename": "*dwi*",
    "ProtocolName": "dwi_acq-*directions_dir-AP",
    "PhaseEncodingDirection": "j-",
    "ImageType": ["ORIGINAL", "PRIMARY", "DIFFUSION", "NONE"]
  }
}
```

### **Fieldmap for BOLD**

```json
{
  "datatype": "fmap",
  "suffix": "epi",
  "custom_entities": "dir-AP",
  "criteria": {
    "ProtocolName": "*fmap*dir-AP*"
  },
  "sidecar_changes": {
    "IntendedFor": [
      "rest_AP_bold_1",
      "rest_PA_bold_2",
      "rest_AP_bold_3",
      "rest_PA_bold_4"
    ]
  }
}
```

## Summary of Flow

1. HeuDiConv or your chosen tool reads `config.json`.
2. It searches all DICOM series using the rules from `dcm2niixOptions`.
3. Each DICOM series is checked against the `"criteria"` of each `"descriptions"` rule.
4. If a match is found, it is labeled in BIDS format.
5. `"sidecar_changes"` are applied to update metadata.
6. `"post_op"` operations (if defined) are run after conversion.

Everything in this configuration is **modular**. You can **add, remove, or modify rules** as needed based on your DICOM naming conventions.


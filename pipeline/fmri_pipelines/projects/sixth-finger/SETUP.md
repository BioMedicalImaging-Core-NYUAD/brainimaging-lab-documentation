# Sixth-Finger Project — Setup

This project depends on two external MATLAB toolboxes and a couple of large saved workspaces that are intentionally not committed to the repository. After cloning, you need to install the toolboxes locally before running any of the analysis scripts.

The expected on-disk layout once setup is complete:

```
pipeline/fmri_pipelines/projects/sixth-finger/
├── spm/            <-- install here (not in git)
├── RSAtoolbox/     <-- install here (not in git)
├── BA1-4/
├── BA9-46-7-40/
├── RSA/
├── helper/
├── run_main.m
└── ...
```

## External dependencies

### 1. SPM (Statistical Parametric Mapping)

Used for the canonical HRF (`spm_hrf`) and general fMRI utilities. The code adds it to the MATLAB path via `addpath(genpath(fullfile(codeDir, 'spm')))` — so the toolbox must sit at `pipeline/fmri_pipelines/projects/sixth-finger/spm/`.

Download options:

- Official site: https://www.fil.ion.ucl.ac.uk/spm/software/download/
- GitHub mirror: https://github.com/spm/spm

This project was developed against **SPM25** (version 25.01.02). Other recent SPM releases (SPM12 onward) should also work for the functions used here.

Install steps:

```bash
cd pipeline/fmri_pipelines/projects/sixth-finger
git clone https://github.com/spm/spm.git
# or download the zip from the official site and unzip into ./spm
```

### 2. RSAtoolbox (MATLAB)

Used by the RSA pipeline (`RSA/compute_crossnobis_rdm.m` and friends) for representational similarity analysis. Expected at `pipeline/fmri_pipelines/projects/sixth-finger/RSAtoolbox/`.

Download:

- GitHub: https://github.com/rsagroup/rsatoolbox_matlab

Install steps:

```bash
cd pipeline/fmri_pipelines/projects/sixth-finger
git clone https://github.com/rsagroup/rsatoolbox_matlab.git RSAtoolbox
```

### 3. FreeSurfer MATLAB utilities (system-level, not in this folder)

Several scripts also add the FreeSurfer MATLAB folder to the path, e.g. `addpath(genpath(fullfile(fsHome, 'matlab')))`. FreeSurfer is expected to be installed system-wide (the scripts default to `/Applications/freesurfer/8.1.0` on macOS). Install FreeSurfer from https://surfer.nmr.mgh.harvard.edu/fswiki/DownloadAndInstall if you don't already have it.

## Regeneratable data files

`BA1-4/matlab_workspace.mat` and `BA9-46-7-40/matlab_workspace.mat` (~343 MB each) are saved MATLAB workspace dumps from running the GLM scripts. They are not committed; rerun the corresponding `run_glm_*` scripts to regenerate them locally.

## Known hardcoded path to fix

`tmap_code.m` line 1 has a hardcoded absolute path:

```matlab
addpath('/Users/hha243/Desktop/MacBook/NYUPostDoc/MatlabFuncs/spm')
```

Replace it with the relative pattern used elsewhere in the codebase:

```matlab
addpath(genpath(fullfile(codeDir, 'spm')))
```

so the script works for anyone who follows this setup.

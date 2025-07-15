#!/usr/bin/env python3
"""
One-stop launcher for fMRIPrep + TemplateFlow + braimcore.

JSON example (minimal):
{
  "project": "finger-tapping",
  "participants": ["sub-0665", "sub-1020"],   # optional, empty ⇒ ALL
  "threads": 18                               # optional, default 18
}
"""

import json, sys, subprocess, pathlib, os, datetime, shutil, importlib.util

# ─── toggle dry-run (DEBUG) here ────────────────────────────────────────────
DEBUG = True           # True → skip Docker, just create DRYRUN logs
# ---------------------------------------------------------------------------

# ─── paths you rarely change ────────────────────────────────────────────────
HOST_REPO_ROOT = pathlib.Path(
    "/home/hz3752/PycharmProjects/brainimaging-lab-documentation")
DATA_ROOT      = HOST_REPO_ROOT / "data-bids" / "eeg-fmri"
FS_LICENSE     = pathlib.Path("/home/hz3752/Documents/license.txt")
TEMPLATEFLOW_HOME = pathlib.Path.home() / ".cache" / "templateflow"
DOCKER_IMAGE   = "nipreps/fmriprep:24.1.1"
# ---------------------------------------------------------------------------

# ─── load JSON config ───────────────────────────────────────────────────────
cfg_path = pathlib.Path(sys.argv[1]).resolve()
cfg_dir  = cfg_path.parent
cfg      = json.loads(cfg_path.read_text())

project   = cfg["project"]
subjects  = cfg.get("participants", []) or ["ALL"]
threads   = str(cfg.get("threads", 18))




os.environ["TEMPLATEFLOW_HOME"] = str(TEMPLATEFLOW_HOME)
TEMPLATEFLOW_HOME.mkdir(parents=True, exist_ok=True)



# ─── utility: write log into config directory (and print) ───────────────────
def write_log(tag: str, text: str):
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    fname = f"fmriprep_{project}_{tag}_{stamp}{'_DRYRUN' if DEBUG else ''}.log"
    path  = cfg_dir / fname
    path.write_text(text)
    print(f"📝 wrote {path}")
    return path


import templateflow.api as tf

print("📥 Pre-fetching templates …")
for tpl in ("OASIS30ANTs", "MNI152NLin2009cAsym", "fsaverage"):
    tf.get(template=tpl, resolution=1)   # pulls if missing

# ─── DEBUG branch: no Docker, just confirmation logs ────────────────────────
if DEBUG:
    for s in subjects:
        tag = s if s != "ALL" else "all"
        write_log(tag, "Processing done\n")
    sys.exit(0)

# ─── real run: build constant paths for this project ────────────────────────
base   = DATA_ROOT / project
paths  = {
    "BIDS_DIR" : base / "rawdata",
    "OUT_DIR"  : base / "derivatives" / "fmriprep",
    "FS_DIR"   : base / "derivatives" / "freesurfer",
    "WORK_DIR" : base / "tmp" / "fmriprep-work",
}



for p in paths.values():
    p.mkdir(parents=True, exist_ok=True)




# ─── pull Docker image if it isn't on disk ──────────────────────────────────
if subprocess.run(["docker", "image", "inspect", DOCKER_IMAGE],
                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode:
    print(f"📦 Pulling {DOCKER_IMAGE} …")
    subprocess.run(["docker", "pull", DOCKER_IMAGE], check=True)

# ─── helper to run Docker and stream log ────────────────────────────────────
def run_one(participant: str | None):
    tag = participant if participant else "all"
    log  = write_log(tag, "")      # create empty file first
    cmd  = [
        "docker", "run", "--rm",
        "-u", f"{os.getuid()}:{os.getgid()}",
        "-v", f"{paths['BIDS_DIR']}:/data:ro",
        "-v", f"{paths['OUT_DIR']}:/out",
        "-v", f"{paths['WORK_DIR']}:/work",
        "-v", f"{paths['FS_DIR']}:/reconall",
        "-v", f"{FS_LICENSE}:/opt/freesurfer/license.txt:ro",
        "-v", f"{TEMPLATEFLOW_HOME}:{TEMPLATEFLOW_HOME}",
        "-e",  f"TEMPLATEFLOW_HOME={TEMPLATEFLOW_HOME}",
        DOCKER_IMAGE,
        "/data", "/out", "participant",
    ]
    if participant:
        cmd += ["--participant-label", participant]
    cmd += [
        "--fs-subjects-dir", "/reconall",
        "--skip-bids-validation",
        "--output-spaces", "T1w:res-native", "fsnative:den-41k",
                          "MNI152NLin2009cAsym:res-native",
                          "fsaverage:den-41k", "fsaverage",
        "--nthreads", threads,
        "--mem_mb", "32000",
        "--work-dir", "/work",
        "--no-submm-recon",
    ]

    print(f"🚀 Running {tag} …")
    with log.open("ab") as fh:
        proc = subprocess.Popen(cmd,
                                stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT)
        for line in proc.stdout:
            sys.stdout.buffer.write(line)
            fh.write(line)
        proc.wait()
    if proc.returncode:
        raise RuntimeError(f"fMRIPrep for {tag} failed – see {log}")

# ─── launch for each participant ────────────────────────────────────────────
for s in subjects:
    run_one(None if s == "ALL" else s)

print("✅ All requested runs finished successfully")

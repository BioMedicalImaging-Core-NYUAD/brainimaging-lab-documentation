#!/usr/bin/env python3
"""
Launch fMRIPrep from a JSON configuration.

JSON schema (minimal):
{
  "project": "finger-tapping",
  "participants": ["sub-0665", "sub-1020"],   # optional, empty → ALL
  "threads": 18                               # optional, default 18
}

Usage
-----
python3 run_fmriprep_from_config.py /path/to/fmriprep_config.json
"""

import json, sys, subprocess, pathlib, os, datetime

# ─── DEBUG switch ────────────────────────────────────────────────────────────
DEBUG = True          # ← set True for a dry-run that skips Docker
# ---------------------------------------------------------------------------

# ─── Read configuration ─────────────────────────────────────────────────────
cfg_path = pathlib.Path(sys.argv[1]).resolve()
cfg_dir  = cfg_path.parent

cfg       = json.loads(cfg_path.read_text())
project   = cfg["project"]
subjects  = cfg.get("participants", []) or ["ALL"]
threads   = str(cfg.get("threads", 18))

# ─── Static paths (edit if you relocate data) ───────────────────────────────
base   = pathlib.Path(
           "/home/hz3752/PycharmProjects/brainimaging-lab-documentation"
           "/data-bids/eeg-fmri") / project
paths  = {
    "BIDS_DIR"  : base / "rawdata",
    "OUT_DIR"   : base / "derivatives" / "fmriprep",
    "FS_DIR"    : base / "derivatives" / "freesurfer",
    "WORK_DIR"  : base / "tmp"         / "fmriprep-work",
    "FS_LICENSE": "/home/hz3752/Documents/license.txt",
    "IMAGE"     : "nipreps/fmriprep:24.1.1",
}

# ─── Dry-run branch ─────────────────────────────────────────────────────────
if DEBUG:
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    for subj in subjects:
        tag = subj if subj != "ALL" else "all"
        log_path = cfg_dir / f"fmriprep_{project}_{tag}_{stamp}_DRYRUN.log"
        log_path.write_text("Processing done\n")
        print(f"[DEBUG] would process {tag}  →  {log_path.name}")
    sys.exit(0)

# ─── Real run: ensure dirs & permissions ────────────────────────────────────
for key in ("OUT_DIR", "FS_DIR", "WORK_DIR"):
    paths[key].mkdir(parents=True, exist_ok=True)
    if not os.access(paths[key], os.W_OK):
        subprocess.run(["sudo", "chown", "-R",
                        f"{os.getuid()}:{os.getgid()}",
                        paths[key]], check=True)

# pull image if missing
if subprocess.run(["docker", "image", "inspect", paths["IMAGE"]],
                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode:
    print(f"Pulling {paths['IMAGE']} …")
    subprocess.run(["docker", "pull", paths["IMAGE"]], check=True)

# ─── Build Docker command factory ───────────────────────────────────────────
def docker_cmd(participant: str | None):
    p_arg = [] if participant is None else ["--participant-label", participant]
    home  = os.environ["HOME"]
    return [
        "docker", "run", "--rm",
        "-u", f"{os.getuid()}:{os.getgid()}",
        "-v", f"{paths['BIDS_DIR']}:/data:ro",
        "-v", f"{paths['OUT_DIR']}:/out",
        "-v", f"{paths['WORK_DIR']}:/work",
        "-v", f"{paths['FS_DIR']}:/reconall",
        "-v", f"{paths['FS_LICENSE']}:/opt/freesurfer/license.txt:ro",
        "-v", f"{home}/.cache/templateflow:{home}/.cache/templateflow",
        "-e",  f"TEMPLATEFLOW_HOME={home}/.cache/templateflow",
        paths["IMAGE"],
        "/data", "/out", "participant",
        *p_arg,
        "--fs-subjects-dir", "/reconall",
        "--skip-bids-validation",
        "--output-spaces",
        "T1w:res-native", "fsnative:den-41k",
        "MNI152NLin2009cAsym:res-native",
        "fsaverage:den-41k", "fsaverage",
        "--nthreads", threads,
        "--mem_mb", "32000",
        "--work-dir", "/work",
        "--no-submm-recon",
    ]

# ─── Execute per subject, capturing logs ­───────────────────────────────────
stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
for subj in subjects:
    tag      = subj if subj != "ALL" else "all"
    log_file = cfg_dir / f"fmriprep_{project}_{tag}_{stamp}.log"
    print(f"▶ Running fMRIPrep for {tag}  →  {log_file.name}")

    with log_file.open("wb") as fh:
        proc = subprocess.Popen(docker_cmd(None if subj == "ALL" else subj),
                                stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT)
        for line in proc.stdout:
            sys.stdout.buffer.write(line)
            fh.write(line)
        proc.wait()
        if proc.returncode:
            print(f"❌ {tag} failed (exit {proc.returncode}) — see log.")
            sys.exit(proc.returncode)

print("✅ All requested runs finished successfully")

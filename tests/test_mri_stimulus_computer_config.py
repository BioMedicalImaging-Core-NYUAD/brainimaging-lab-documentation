# tests/test_mri_stimulus_computer_config.py
import os
import sys
import time
import subprocess


def _prefix_from_env():
    """
    Build an optional prefix like ['/usr/bin/arch', '-arm64'] if ARCH_* are set.
    Keep these in your env file (no quotes):
        ARCH_BIN=/usr/bin/arch
        ARCH_ARGS=-arm64
    """
    arch_bin = os.environ.get("ARCH_BIN", "").strip()
    arch_args = os.environ.get("ARCH_ARGS", "").strip()
    return ([arch_bin] + arch_args.split()) if arch_bin else []


def _run_streaming(cmd, timeout=300):
    """
    Run a subprocess and stream stdout/stderr live to the console.
    Returns (return_code, elapsed_seconds).
    """
    print("\n--- run ----------------------------------------------------")
    print("Command:", " ".join(cmd))
    print("-----------------------------------------------------------")
    sys.stdout.flush()

    t0 = time.time()
    with subprocess.Popen(
        cmd,
        stdout=sys.stdout,   # stream live to console
        stderr=sys.stderr,   # stream live to console
        text=True,
    ) as p:
        try:
            rc = p.wait(timeout=timeout)
        except subprocess.TimeoutExpired:
            p.kill()
            raise
    elapsed = time.time() - t0

    print("\n--- result -------------------------------------------------")
    print(f"Return code: {rc}")
    print(f"Elapsed: {elapsed:.2f}s")
    print("-----------------------------------------------------------\n")
    return rc, elapsed


def _matlab_bin_from_env():
    """
    Resolve MATLAB binary path from env. Your workflow should export:
      - MATLAB_BIN (preferred) or MATLAB_PATH
    """
    matlab_bin = os.environ.get("MATLAB_BIN") or os.environ.get("MATLAB_PATH")
    assert matlab_bin, "MATLAB_BIN or MATLAB_PATH must be set in the CI environment"
    return matlab_bin


def test_matlab_runs_from_env():
    """
    Test 1: Verify MATLAB launches headlessly via the absolute path from env.
    Pass if MATLAB exits with status 0 and prints a confirmation line.
    """
    matlab_bin = _matlab_bin_from_env()
    cmd = _prefix_from_env() + [
        matlab_bin,
        "-nodisplay", "-nosplash", "-nojvm",
        "-r",
        "try, disp('MATLAB command OK'); exit(0); "
        "catch ME, disp(getReport(ME,'extended')); exit(1); end",
    ]

    print("TEST: Verify MATLAB launches headlessly and runs a simple command.")
    rc, _ = _run_streaming(cmd)

    assert rc == 0, "MATLAB did not run successfully"

def test_psychtoolbox_version():
    """
    Test 3: Verify that Psychtoolbox is installed and MATLAB can report its version.
    Pass criteria: MATLAB exits with status 0 and prints a PsychtoolboxVersion line.
    """
    matlab_bin = os.environ.get("MATLAB_BIN") or os.environ.get("MATLAB_PATH")
    assert matlab_bin, "MATLAB_BIN or MATLAB_PATH must be set in the CI environment"

    prefix = _prefix_from_env()
    cmd = prefix + [
        matlab_bin,
        "-nodisplay", "-nosplash", "-nojvm",
        "-r",
        (
            "try;"
            "v = PsychtoolboxVersion; "
            "fprintf('PsychtoolboxVersion: %s\\n', v); "
            "exit(0); "
            "catch ME; "
            "disp(getReport(ME,'extended')); "
            "exit(1); "
            "end"
        ),
    ]

    print("TEST: Verify Psychtoolbox is installed and accessible via PsychtoolboxVersion.")
    rc, _ = _run_streaming(cmd)
    assert rc == 0, "PsychtoolboxVersion failed — Psychtoolbox may not be installed correctly"

def test_eyelink_init_dummy():
    """
    Test 2: EyelinkInit in dummy mode (no hardware required).
    Pass if MATLAB exits with status 0 after EyelinkInit(1) and Shutdown.
    """
    matlab_bin = _matlab_bin_from_env()
    cmd = _prefix_from_env() + [
        matlab_bin,
        "-nodisplay", "-nosplash", "-nojvm",
        "-r",
        "try; EyelinkInit(1); Eyelink('Shutdown'); "
        "disp('EyelinkInit dummy mode completed'); exit(0); "
        "catch ME; disp(getReport(ME,'extended')); exit(1); end",
    ]

    print("TEST: Run EyelinkInit in dummy mode and shut down cleanly.")
    rc, _ = _run_streaming(cmd)

    assert rc == 0, "EyelinkInit dummy mode failed"


def test_matlab_ptb_demo_exits_in_10s():
    """
    Run the PTB demo in a tiny 1x1 window (no fullscreen) without modifying the MATLAB script.
    Streams MATLAB/PTB output live, fails on any error, and checks wall-clock ~10s.
    """
    matlab_bin = _matlab_bin_from_env()

    # MATLAB one-liner:
    #  - make PTB CI-tolerant (skip sync tests, quiet logs)
    #  - force a 1x1 GUI window just for this session (PsychDebugWindowConfiguration)
    #  - add the demo folder to path, run it, and print elapsed time
    ml_code = (
        "try, "
        "AssertOpenGL; "
        "Screen('Preference','SkipSyncTests',1); "
        "Screen('Preference','Verbosity',1); "
        "Screen('Preference','VisualDebugLevel',4); "
        "PsychDebugWindowConfiguration([],0,[],[0 0 1 1]); "
        "addpath(fullfile(pwd,'experiments','FMRI','simple_demos')); "
        "t0=tic; smoothcolor_demo; e=toc(t0); "
        "fprintf('PTB demo elapsed: %.3fs\\n', e); "
        "exit(0); "
        "catch ME, "
        "fprintf(2,'\\n===== MATLAB/PTB ERROR =====\\n'); "
        "fprintf(2,'%s\\n', getReport(ME,'extended','hyperlinks','off')); "
        "exit(1); "
        "end"
    )

    cmd = _prefix_from_env() + [
        matlab_bin,
        "-nodisplay", "-nosplash", "-nojvm",
        "-r", ml_code,
    ]

    print("TEST: Run PTB smoothcolor_demo headless-ish (1x1 window) and ensure it auto-terminates.")
    rc, elapsed = _run_streaming(cmd, timeout=120)

    assert rc == 0, "MATLAB/PTB run returned non-zero exit code"
    assert 8.5 <= elapsed <= 15.0, f"Demo duration out of expected range: {elapsed:.2f}s"


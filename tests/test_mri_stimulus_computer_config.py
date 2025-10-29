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

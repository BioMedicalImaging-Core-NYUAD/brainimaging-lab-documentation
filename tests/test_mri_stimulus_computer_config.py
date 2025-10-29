import os
import subprocess
import sys
import time

def _prefix_from_env():
    arch_bin = os.environ.get("ARCH_BIN", "").strip()
    arch_args = os.environ.get("ARCH_ARGS", "").strip()
    return [arch_bin] + arch_args.split() if arch_bin else []

def _run(cmd):
    print("\n--- run ----------------------------------------------------")
    print("Command:", " ".join(cmd))
    print("-----------------------------------------------------------")
    t0 = time.time()
    result = subprocess.run(cmd, text=True, capture_output=True, timeout=300)
    elapsed = time.time() - t0

    print("\n--- stdout -------------------------------------------------")
    sys.stdout.write(result.stdout or "")
    print("\n--- stderr -------------------------------------------------")
    sys.stderr.write(result.stderr or "")
    print("\n--- result -------------------------------------------------")
    print(f"Return code: {result.returncode}")
    print(f"Elapsed: {elapsed:.2f}s")
    print("-----------------------------------------------------------\n")
    return result, elapsed

def test_matlab_runs_from_env():
    """
    Test 1: MATLAB starts headlessly via the absolute path from env.
    Pass criteria: MATLAB exits with status 0 and prints a confirmation line.
    """
    matlab_bin = os.environ.get("MATLAB_BIN") or os.environ.get("MATLAB_PATH")
    assert matlab_bin, "MATLAB_BIN or MATLAB_PATH must be set in the CI env"

    prefix = _prefix_from_env()
    cmd = prefix + [
        matlab_bin,
        "-nodisplay", "-nosplash", "-nojvm",
        "-r",
        "try, disp('MATLAB command OK'); exit(0); "
        "catch ME, disp(getReport(ME,'extended')); exit(1); end",
    ]

    print("TEST: Verify MATLAB launches headlessly and runs a simple command.")
    result, _ = _run(cmd)

    assert result.returncode == 0, "MATLAB did not run successfully"
    assert "MATLAB command OK" in result.stdout, "Confirmation text not found in MATLAB output"
    print("PASS: MATLAB launched and executed the command.")

def test_eyelink_init_dummy():
    """
    Test 2: EyelinkInit in dummy mode.
    Pass criteria: MATLAB exits with status 0 after EyelinkInit(1) and Shutdown.
    NOTE: This does not check hardware; dummy mode is CI-safe.
    """
    matlab_bin = os.environ.get("MATLAB_BIN") or os.environ.get("MATLAB_PATH")
    assert matlab_bin, "MATLAB_BIN or MATLAB_PATH must be set in the CI env"

    prefix = _prefix_from_env()
    cmd = prefix + [
        matlab_bin,
        "-nodisplay", "-nosplash", "-nojvm",
        "-r",
        "try; EyelinkInit(1); Eyelink('Shutdown'); "
        "disp('EyelinkInit dummy mode completed'); exit(0); "
        "catch ME; disp(getReport(ME,'extended')); exit(1); end",
    ]

    print("TEST: Run EyelinkInit in dummy mode and shut down cleanly.")
    result, _ = _run(cmd)

    assert result.returncode == 0, "EyelinkInit dummy mode failed"
    assert "EyelinkInit dummy mode completed" in result.stdout, "Expected completion text not found"
    print("PASS: EyelinkInit(1) succeeded and shut down.")

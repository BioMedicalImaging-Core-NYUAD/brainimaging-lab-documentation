import os
import subprocess
import sys

def test_eyelink_init():
    matlab_bin = os.environ.get("MATLAB_BIN") or os.environ.get("MATLAB_PATH")
    assert matlab_bin, "MATLAB_BIN or MATLAB_PATH must be set"

    arch_bin = os.environ.get("ARCH_BIN", "").strip()
    arch_args = os.environ.get("ARCH_ARGS", "").strip()
    prefix = [arch_bin] + arch_args.split() if arch_bin else []

    cmd = prefix + [
        matlab_bin,
        "-nodisplay", "-nosplash", "-nojvm",
        "-r",
        (
            "try; "
            "EyelinkInit(1); "
            "Eyelink('Shutdown'); "
            "disp('EyelinkInit completed successfully'); "
            "exit(0); "
            "catch ME; "
            "disp(getReport(ME,'extended')); "
            "exit(1); "
            "end"
        ),
    ]

    result = subprocess.run(cmd, capture_output=True, text=True, timeout=180)
    sys.stdout.write(result.stdout)
    sys.stderr.write(result.stderr)
    assert result.returncode == 0, f"EyelinkInit failed, return code {result.returncode}"

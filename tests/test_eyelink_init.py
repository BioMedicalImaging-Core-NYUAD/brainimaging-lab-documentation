import os
import shlex
import subprocess
import sys

def test_eyelink_init():
    matlab_bin = os.environ.get("MATLAB_BIN") or os.environ.get("MATLAB_PATH")
    assert matlab_bin, "MATLAB_BIN or MATLAB_PATH must be set"

    arch_prefix = os.environ.get("ARCH_PREFIX", "").strip()
    prefix = shlex.split(arch_prefix) if arch_prefix else []

    cmd = prefix + [
        matlab_bin,
        "-nodisplay", "-nosplash", "-nojvm",
        "-r", (
            "try; "
            "EyelinkInit(1); "
            "Eyelink('Shutdown'); "
            "disp('EyelinkInit completed successfully'); "
            "exit(0); "
            "catch ME; "
            "disp(getReport(ME,'extended')); "
            "exit(1); "
            "end"
        )
    ]

    result = subprocess.run(cmd, capture_output=True, text=True, timeout=180)
    sys.stdout.write(result.stdout)
    sys.stderr.write(result.stderr)
    assert result.returncode == 0, "EyelinkInit failed"

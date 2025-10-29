import os
import subprocess
import sys

def test_eyelink_init():
    """Run MATLAB headlessly to check EyelinkInit can execute."""
    matlab_bin = os.environ.get("MATLAB_BIN")
    assert matlab_bin, "MATLAB_BIN must be set (workflow should export it from the env file)."

    cmd = [
        matlab_bin,
        "-nodisplay", "-nosplash", "-nojvm",
        "-r", (
            "try; "
            "EyelinkInit(1); "  # dummy mode so hardware is not required
            "Eyelink('Shutdown'); "
            "disp('EyelinkInit completed successfully'); "
            "exit(0); "
            "catch ME; "
            "disp(getReport(ME,'extended')); "
            "exit(1); "
            "end"
        )
    ]

    result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
    sys.stdout.write(result.stdout)
    sys.stderr.write(result.stderr)
    assert result.returncode == 0, "EyelinkInit failed"

import subprocess
import sys

def test_eyelink_init():
    """Run MATLAB headlessly to check EyelinkInit can execute."""
    cmd = [
        "matlab",
        "-nodisplay", "-nosplash", "-nojvm",
        "-r", (
            "try; "
            "EyelinkInit(1); "  # use dummy mode so it doesn't need hardware
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

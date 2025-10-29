import os, shlex, subprocess, sys

def test_eyelink_init():
    matlab_bin = os.environ.get("MATLAB_BIN") or os.environ.get("MATLAB_PATH")
    assert matlab_bin, "MATLAB_BIN or MATLAB_PATH must be set"

    arch_prefix = os.environ.get("ARCH_PREFIX", "").strip()
    # Parse ARCH_PREFIX safely into a list
    prefix = shlex.split(arch_prefix) if arch_prefix else []
    print("ARCH_PREFIX split to:", prefix, file=sys.stderr)

    # Build final command
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

    print("Command:", cmd, file=sys.stderr)

    result = subprocess.run(cmd, capture_output=True, text=True, timeout=180)
    sys.stdout.write(result.stdout)
    sys.stderr.write(result.stderr)
    assert result.returncode == 0, f"EyelinkInit failed, return code {result.returncode}"

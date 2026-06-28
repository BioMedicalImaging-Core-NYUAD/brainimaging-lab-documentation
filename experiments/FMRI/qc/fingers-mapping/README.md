# Six Fingers Motor Execution QC Template

This is a template-style QC version of the six-fingers Motor Execution task.
It keeps the original execution design but follows the MRI-center template
structure used in `tests/template-experiment`.

## Structure

- `main.m`: entry point.
- `utils/setup`: setup, trigger, keyboard, save/cleanup helpers.
- `utils/stimuli`: rest, execution cue, and end-screen drawing helpers.
- `images`: neutral hand plus five execution finger cue images.

The main structs match the MRI-center template style:

- `debugConfig`: debug/scanner/laptop behavior.
- `VP`: display and viewing parameters.
- `pa`: experiment parameters, design, data, and output paths.
- `kb`: keyboard mappings.

## Design

- Task: Motor Execution only.
- Fingers: thumb, index, middle, ring, pinky.
- Blocks per run: 3.
- Trials per block: 5, one per finger.
- Finger order: randomized separately for each block via `randperm`.
- Timing: 12 s rest image, then 12 s execution cue.
- Final rest: one extra 12 s rest image.
- Planned design duration: 372 s, excluding trigger wait and end screen.

## Running

In MATLAB:

```matlab
cd('/path/to/six-fingers-execution')
main
```

Use `debugConfig` near the top of `main.m` to switch between laptop/manual
testing and scanner/VPixx behavior.

For laptop testing, keep:

```matlab
debugConfig.useVPixx = 0;
debugConfig.displayMode = 2;
debugConfig.manualTrigger = 1;
```

For MRI-center use, the expected production-style settings are:

```matlab
debugConfig.useVPixx = 1;
debugConfig.displayMode = 1;
debugConfig.manualTrigger = 0;
```

## Outputs

Outputs are saved under:

```text
data/exp/sub-<subject>/ses-<session>/
```

The QC version saves:

- `.mat` file containing `pa`
- `_events.tsv` timing file
- `_dm.csv` design matrix with columns `thumb,index,middle,ring,pinky`

## Note About Original Run Order

This code runs one ME scan each time `main` is launched. It does not automate
the full original interleaved order. The observed session order was:

```text
MI, ME, MI, ME, MI, ME, MI, MI
```

So the original ME design-file numbers were `2`, `4`, and `6`, even though
the BIDS execution runs are `run-01`, `run-02`, and `run-03`.

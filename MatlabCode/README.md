# MatlabCode (Active)

This is the primary MATLAB/Simulink workspace for the wearable insole modeling project.

## What Is In This Folder

- `models/`: current Simulink models (`FullHopper_baseline.slx`, `FullHopper_k.slx`, `FullHopper_kb.slx`, `FullHopper_kb_splines.slx`).
- `helpers/`: shared utility functions (`analyze_sole_output.m`, `assemble_sim_inputs.m`, `eval_all_objectives.m`, `load_params.m`, and `parfor_progress/`).
- `generated_data/`: produced `.mat` sweep outputs plus `figures/`.
- Core scripts:
  - `bayesian_optimization_spline.m`: optimize spline control points + sole thickness.
  - `bayesian_optimization_test.m`: baseline Bayesian optimization script.
  - `gen_data.m`: run parameter sweeps and save outputs.
  - `gen_figures.m`: build contour plots from saved sweeps.
  - `fixed_height_test.m`: run sweeps with fixed jump-height handling.
  - `gen_fixed_height_figures.m`: plots for fixed-height runs.
  - `performance_eval.m`: quick 1D checks.
  - `splines_test.m`: helper/testing script for spline behavior.

## Model Variants (High Level)

- `FullHopper_baseline.slx`: baseline/reference behavior.
- `FullHopper_k.slx`: stiffness-focused model variant.
- `FullHopper_kb.slx`: stiffness + damping variant.
- `FullHopper_kb_splines.slx`: spline-based sole force-displacement variant.

## Data Snapshot

`generated_data/` currently contains:
- `baseline.mat`,
- many files named `k_<stiffness>_maxcomp_<value>.mat`,
- and a `figures/` folder for generated plots.

Treat generated data as reproducible output that can be rebuilt by rerunning scripts.

## Typical Run Order

1. Run `bayesian_optimization_spline.m` when updating spline parameters.
2. Run `gen_data.m` to regenerate parameter sweep outputs.
3. Run `gen_figures.m` to regenerate contour figures.
4. Optionally run `fixed_height_test.m` and `gen_fixed_height_figures.m`.

## Dependencies

- MATLAB/Simulink 2020a or later
- Statistics and Machine Learning Toolbox
- Parallel Computing Toolbox

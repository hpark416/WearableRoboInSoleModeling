# MatlabCode

This folder contains the MATLAB/Simulink implementation for the wearable insole modeling study, including baseline and modified hopper models, parameter-sweep scripts, generated `.mat` data, and colormap figures.

## Current Folder Structure

- `FullHopper_alt.slx`: modified Simulink hopper model with shoe parameters.
- `gen_data.m`: runs simulation sweeps and saves outputs to `generated_data/`.
- `gen_figures.m`: loads sweep outputs and generates contour heatmaps.
- `performance_eval.m`: preliminary 1D evaluation script for stiffness and max compression.
- `original/FullHopper_baseline.slx`: baseline model used for comparison.
- `generated_data/`: saved simulation outputs (`baseline.mat` and sweep `.mat` files).
- `generated_data/figures/`: generated heatmaps.

## Parameter Sweep Data

`gen_data.m` currently sweeps:

- `K_shoe` from `20000` to `70000` N/m (step `2500`),
- `thickness` (used as max compression) from `0.01` to `0.035` m (step `0.0025`).

The dataset in `generated_data/` currently includes:

- `baseline.mat` (baseline simulation output),
- 231 sweep outputs named like `k_<stiffness>_maxcomp_<value>.mat`,
- 232 `.mat` files total in the folder.

## Generated Figures

`gen_figures.m` produces contour maps in `generated_data/figures/`:

- `GRF_colormap.png`
- `mean_Pmet_colormap.png`
- `dpMass_colormap.png`

These summarize how peak GRF, mean metabolic proxy (`mean_Pmet`), and peak mass displacement vary across the 2D parameter grid.

## Typical Workflow

1. Run `gen_data.m` to generate or refresh sweep data.
2. Run `gen_figures.m` to regenerate heatmaps from saved `.mat` files.
3. Use `performance_eval.m` for quick 1D exploratory checks of stiffness or max compression trends.

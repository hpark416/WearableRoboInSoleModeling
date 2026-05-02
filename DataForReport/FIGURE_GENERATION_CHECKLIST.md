# Figure Generation Checklist

Companion checklist mapping report figures to scripts and expected outputs.

## Quick Note on Script Names

- The active entry-point in this repo is `MatlabCode/sweep_walkthrough.m`.
- It calls helper functions in `MatlabCode/helpers/`:
  - `gen_baseline_data.m`
  - `gen_sweep_data.m`
  - `visualization/gen_sweep_colormaps.m`
- Older names mentioned in some docs (`gen_data.m`, `gen_figures.m`, etc.) are not present in the current tree.

## 0) Setup

- Set MATLAB current folder to `MatlabCode/`.
- Ensure `generated_data/` exists (scripts also create it automatically).
- Confirm model files are available in `MatlabCode/models/`.

## 1) Baseline Reference Assets

- **Run**
  - `gen_baseline_data(false)` for baseline time series.
  - `gen_baseline_data(true)` for fixed-height baseline objectives.
- **Script**
  - `MatlabCode/helpers/gen_baseline_data.m`
- **Expected outputs**
  - `MatlabCode/generated_data/baseline.mat`
  - `MatlabCode/generated_data/height_<des_dp_Mass>_baseline_objectives.mat`
- **Used for**
  - Baseline values in colormap titles/captions.
  - Baseline-vs-designed comparison text/table.

## 2) Sweep Data for Heatmaps (Full Time-Series Mode)

- **Run**
  - `gen_sweep_data('FullHopper_kb', false, false)`
  - `gen_sweep_data('FullHopper_kb_splines', false, true)` (sanity check path)
- **Script**
  - `MatlabCode/helpers/gen_sweep_data.m`
- **Expected outputs**
  - Folder: `MatlabCode/generated_data/<model_name>/`
  - Files: `k_<K_shoe>_maxcomp_<thickness>.mat` (one per grid point)
- **Used for**
  - Reconstructing objective landscapes from full simulation outputs.

## 3) Sweep Data for Fixed-Height Mode

- **Run**
  - `gen_sweep_data('FullHopper_kb', true, false)`
  - `gen_sweep_data('FullHopper_kb_splines', true, true)`
- **Script**
  - `MatlabCode/helpers/gen_sweep_data.m`
- **Expected outputs**
  - `MatlabCode/generated_data/<model_name>/height_<des_dp_Mass>_objectives.mat`
  - Contains `out = [max_GRF, max_dpMass, mean_Pmet, amplitude_res]`
  - Contains `param_combinations`
- **Used for**
  - Fair comparisons at matched `max_dpMass` target.
  - Amplitude-resolved analyses.

## 4) Colormap Figure Exports

- **Run (examples)**
  - `gen_sweep_colormaps('FullHopper_kb', "./generated_data/", false, true, true)`
  - `gen_sweep_colormaps('FullHopper_kb', "./generated_data/", true, false, false)`
  - `gen_sweep_colormaps('FullHopper_kb_splines', "./generated_data/", false, true, true)`
  - `gen_sweep_colormaps('FullHopper_kb_splines', "./generated_data/", true, false, false)`
- **Script**
  - `MatlabCode/helpers/visualization/gen_sweep_colormaps.m`
- **Expected outputs**
  - Folder: `MatlabCode/generated_data/figures/`
  - `<model_name>_GRF_colormap.png`
  - `<model_name>_mean_Pmet_colormap.png`
  - `<model_name>_dpMass_colormap.png`
  - `<model_name>_height_<des_dp_Mass>_GRF_colormap.png`
  - `<model_name>_height_<des_dp_Mass>_mean_Pmet_colormap.png`
  - `<model_name>_height_<des_dp_Mass>_dpMass_colormap.png`
  - Optional (fixed-height objective file mode): `<model_name>_height_<des_dp_Mass>_amplitude_colormap.png`
- **Used for**
  - Main results figures in the report.

## 5) BO-Derived Spline Shape Figures

- **Run**
  - `bayesian_optimization_spline`
- **Script**
  - `MatlabCode/bayesian_optimization_spline.m`
- **Expected outputs**
  - MAT files:
    - `MatlabCode/generated_data/optimal_spline_GRF.mat`
    - `MatlabCode/generated_data/optimal_spline_Pmet.mat`
    - `MatlabCode/generated_data/optimal_spline_Normalized.mat`
  - MATLAB figures (rendered during run): optimal force-displacement curve per objective.
- **Used for**
  - "Baseline vs optimized force-displacement profile" figure panel.

## 6) Figures Requiring Small Custom Post-Processing

- **Pareto tradeoff (`max_GRF` vs `mean_Pmet`)**
  - Source: `height_<des_dp_Mass>_objectives.mat` from each model.
  - Action: small plotting script/notebook to scatter `out(:,1)` vs `out(:,3)`.

- **BO convergence**
  - Source: BO result object in workspace during `bayesian_optimization_spline.m`.
  - Action: add explicit save/export of BO trace if this figure is needed in final report.

- **Baseline vs optimized profile overlay**
  - Source: optimized `best` structs + baseline-equivalent straight profile.
  - Action: script to load each `optimal_spline_*.mat`, call `generate_lookup`, and overlay curves.

## 7) Copy Curated Assets to Report Folder

- Create `DataForReport/figures/` when ready.
- Copy only finalized figure files used in the report.
- Add a small provenance note per figure (source script, model, fixed-height flag, date).

## 8) Scope Reminder

- No demographics figures/tables (participant subgroups, age/sex analyses, etc.).
- Keep framing at model-mechanics and simulation-performance level.

# MatlabCode vs Richy Code Comparison

## Scope

This document compares the two MATLAB/Simulink implementations in this repository:

- `MatlabCode/`
- `MiscMatlabCode/Richy/`

Both are based on hopper-style running models with shoe-compliance ideas, but they differ in model packaging, sweep strategy, outputs, and analysis depth.

## High-Level Summary

- `MatlabCode/` is organized around **large 2D parameter sweeps** (`k_shoe` x max compression) with batch data generation and figure generation.
- `Richy/` is organized around a **mechanics-focused model variant** with explicit signal exports and dedicated scripts for GRF comparison and metabolic proxy optimization.
- `Richy/` includes a clearer cycle-averaged optimization workflow (`metaCostStiffness2.m`) for selecting a best tested stiffness.

## Folder and File Structure Differences

### `MatlabCode/`

- Models:
  - `FullHopper_alt.slx` (modified model)
  - `original/FullHopper_baseline.slx` (baseline reference)
- Scripts:
  - `gen_data.m` (batch sweep + `.mat` export)
  - `gen_figures.m` (heatmaps from saved data)
  - `performance_eval.m` (preliminary 1D checks)
- Data outputs:
  - `generated_data/` with many sweep `.mat` files
  - `generated_data/figures/` with contour plots

### `MiscMatlabCode/Richy/`

- Models:
  - `FullHopper.slx` (main modified model)
  - `ShoeSoleImpact.slx` (auxiliary/focused model)
- Scripts:
  - `stiffnessSweepGRFcomp.m` (GRF overlay vs stiffness)
  - `metabolicVsStiffness.m` (first-pass metabolic proxy vs stiffness)
  - `metaCostStiffness2.m` (cycle-averaged metabolic proxy + best stiffness)
- Data outputs:
  - `signal_data_output.mat` (saved output data)
  - direct workspace logging via `*_out` signals

## Model-Level Differences

- `MatlabCode` model path:
  - uses `FullHopper_alt` plus baseline comparison against `original/FullHopper_baseline`.
- `Richy` model path:
  - uses `FullHopper` as primary model and `ShoeSoleImpact` for focused shoe/contact behavior.

- `Richy` explicitly logs:
  - `GRF_out`, `F_mt_out`, `dL_MT_out`, `dL_MT_rate_out`, `stance_out`,
  - plus debug-like outputs `dp_sole_out`, `dp_sub_out`.
- `MatlabCode` scripts rely on saved `simout` structures and post-process fields such as:
  - `simout.GRF`, `simout.dp_Mass`, `simout.int_mean_Pmet`.

## Sweep Strategy Differences

### `MatlabCode`

- Main sweep in `gen_data.m` is **2D**:
  - `K_shoe = 20000:2500:70000`
  - `thickness = 0.01:0.0025:0.035`
- Writes one `.mat` file per parameter pair.
- Designed for broad parameter map exploration and later visualization.

### `Richy`

- Sweeps are mostly **1D over stiffness** with fixed thickness (`0.03` in scripts).
- Tested stiffness set:
  - `[5000, 10000, 20000, 50000, 100000, 200000, 500000]`
- Focuses on interpretable curve comparisons and cost/GRF metrics for each tested `k_shoe`.

## Metrics and Post-Processing Differences

### `MatlabCode` Metrics

- Computes averaged cycle-like metrics from `simout`:
  - max GRF,
  - max `dp_Mass`,
  - `mean_Pmet` proxy from integrated model signal (`int_mean_Pmet`).
- Produces contour maps:
  - `GRF_colormap.png`
  - `mean_Pmet_colormap.png`
  - `dpMass_colormap.png`

### `Richy` Metrics

- Computes MTU power proxy explicitly in script:
  - `P = F_mt_out .* dL_MT_rate_out`
  - positive part integrated with `trapz`.
- Also tracks peak GRF vs stiffness.
- Improved script computes **cycle-averaged** cost and standard deviation over final cycles.

## Optimization/Decision Logic Differences

- `MatlabCode`:
  - emphasizes parameter-space mapping and visual interpretation of trends.
  - no single built-in “best stiffness picker” script in the same explicit form as Richy’s cycle-average method.

- `Richy`:
  - `metaCostStiffness2.m` selects best tested stiffness by minimizing mean positive MTU work per cycle over the last steady cycles.
  - includes robustness features:
    - longer simulation time (`10 s`),
    - cycle segmentation from `stance_out`,
    - standard deviation reporting.

## Practical Trade-Offs

- `MatlabCode` strengths:
  - broad coverage of stiffness/compression combinations,
  - reusable data/figure pipeline for report-ready heatmaps.
- `MatlabCode` limitations:
  - heavier data generation workload,
  - less direct “single optimum” logic in current scripts.

- `Richy` strengths:
  - clear mechanics-to-metric chain for GRF and MTU power proxy,
  - explicit cycle-based optimization workflow.
- `Richy` limitations:
  - narrower sweep grid in provided scripts,
  - results depend on threshold-based cycle detection and sign conventions.

## Suggested Combined Workflow

To combine strengths of both approaches:

1. Use `Richy/metaCostStiffness2.m` to quickly identify promising stiffness regions.
2. Run targeted 2D sweeps in `MatlabCode/gen_data.m` around promising regions.
3. Use `MatlabCode/gen_figures.m` for visual reporting and sensitivity analysis.
4. Validate top candidates with cycle-averaged metrics (Richy-style) before final conclusions.

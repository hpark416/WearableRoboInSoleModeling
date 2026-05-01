# Spline Modeling Notes (Legacy Folder)

This document describes the spline-based sole approach implemented in `MiscMatlabCode/SplineMatlabCode/`.  
That folder is retained for reference; the active workflow is now in `../../MatlabCode/`.

## Spline Sole Concept

The sole is represented as a nonlinear force-displacement curve defined by control points:
- fixed origin `(0 m, 0 N)`,
- two optimizable middle points `(x2, F2)` and `(x3, F3)`,
- fixed high-load endpoint near `(0.023 m, 2300 N)`.

`generate_lookup.m` converts these control points into lookup arrays used by Simulink.

## Main Legacy Scripts

- `bayesian_optimization_spline.m`: optimize spline point values and thickness.
- `generate_lookup.m` and `spline_force.m`: spline utility functions.
- `gen_data.m` / `gen_figures.m`: run sweeps and generate plots.
- `fixed_height_test.m` / `gen_fixed_height_figures.m`: fixed-height study flow.

## Notes On Interpretation

- In the spline model, effective stiffness is curve-dependent rather than a single global spring constant.
- If you are reproducing newer results, prefer the scripts and models under `../MatlabCode/`.

## Dependencies

- MATLAB/Simulink 2020a or later
- Statistics and Machine Learning Toolbox
- Parallel Computing Toolbox

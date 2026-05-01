# SplineMatlabCode (Legacy Snapshot)

This folder is an older standalone spline-modeling workspace kept for reference.

## Status

- This is **not** the primary working directory anymore.
- Active development and the latest model variants live in `../MatlabCode/`.
- Keep this folder for historical comparison and reproducing older spline experiments.

## What Is In This Folder

- `models/`: includes `FullHopper_baseline.slx`, `FullHopper_alt.slx`, and `ComSSModel.slx`.
- `helpers/`: utility functions used by the older scripts.
- `bayesian_optimization_spline.m`, `generate_lookup.m`, `spline_force.m`: spline-related optimization and lookup utilities.
- `gen_data.m`, `gen_figures.m`, `fixed_height_test.m`, `gen_fixed_height_figures.m`: legacy study scripts.
- `README_SPLINE.md`: detailed notes about spline parameterization and optimization assumptions.

## Recommendation

Use `MatlabCode/` for current runs. Use this folder only when you specifically need to compare against the earlier spline branch.

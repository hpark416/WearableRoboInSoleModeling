# MatlabCode (Active)

This is the primary MATLAB/Simulink workspace for the wearable insole modeling project.

## What Is In This Folder

- `models/`: current Simulink models (`FullHopper_baseline.slx`, `FullHopper_k.slx`, `FullHopper_kb.slx`, `FullHopper_kb_splines.slx`).
- `helpers/`: shared utility functions (`analyze_sole_output.m`, `assemble_sim_inputs.m`, `eval_all_objectives.m`, `load_params.m`, and `parfor_progress/`).
- `generated_data/`: produced `.mat` sweep outputs plus `figures/` (**gitignored** — not in the remote repo; run sweeps/plots locally to create it).
- Core scripts (see **Typical run order** below for the current pipeline):
  - `bayesian_optimization_spline.m` / `bayesian_optimization_test.m`: BO on splines and baseline.
  - `helpers/gen_sweep_data.m` + `helpers/visualization/gen_sweep_colormaps.m`: main sweeps and colormaps.
  - `plot_fixed_height_Pmet_analysis.m`, `plot_pareto_GRF_Pmet.m`, `plot_BO_spline_profiles_comparison.m`, `compare_fixed_vs_free_height_plots.m`: report-style figures.
  - `gen_data.m` / `gen_figures.m` / `fixed_height_test.m` / `gen_fixed_height_figures.m`: older one-off study scripts; prefer `gen_sweep_data` for new work.
  - `performance_eval.m`, `splines_test.m`: quick checks.

## Model Variants (High Level)

- `FullHopper_baseline.slx`: baseline/reference behavior.
- `FullHopper_k.slx`: stiffness-focused model variant.
- `FullHopper_kb.slx`: stiffness + damping variant.
- `FullHopper_kb_splines.slx`: spline-based sole force-displacement variant.

## Data Snapshot

If present (after you run the pipeline), `generated_data/` may contain:
- `baseline.mat`,
- many files named `k_<stiffness>_maxcomp_<value>.mat`,
- and a `figures/` folder for generated plots.

Treat generated data as reproducible output that can be rebuilt by rerunning scripts.

**Report summaries:** [`../DataForReport/figures/heightPmetAnalysisFigures/FINDINGS_AND_NEXT_STEPS.md`](../DataForReport/figures/heightPmetAnalysisFigures/FINDINGS_AND_NEXT_STEPS.md).

## Typical Run Order

1. Sweeps: `helpers/gen_sweep_data.m` (see `sweep_walkthrough.m` or your walkthrough).
2. Figures: `helpers/visualization/gen_sweep_colormaps.m`; fixed-height / Pareto / BO comparison scripts in repo root (`plot_fixed_height_Pmet_analysis.m`, etc.).
3. BO: `bayesian_optimization_spline.m`.

## Dependencies

- MATLAB/Simulink 2020a or later
- Statistics and Machine Learning Toolbox
- Parallel Computing Toolbox

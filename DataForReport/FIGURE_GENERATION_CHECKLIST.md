# Figure generation checklist

Maps scripts in **`MatlabCode/`** to outputs. Curated PNGs for the report live under **`DataForReport/figures/`** (copy or export there when stable).

**Note:** paths under **`MatlabCode/generated_data/`** are **gitignored**; they exist only after local runs. For versioned figure files, use **`DataForReport/figures/`**.

**Setup:** `cd MatlabCode`; ensure models load from `models/`.

## Sweeps and objectives

| Step | Run | Output |
|------|-----|--------|
| Free-height grid | `gen_sweep_data('<model>', false, use_curve)` | `generated_data/<model>/k_*_maxcomp_*.mat` |
| Fixed-height grid | `gen_sweep_data('<model>', true, use_curve)` | `generated_data/<model>/height_<des>_objectives.mat` |
| Heatmaps | `gen_sweep_colormaps(...)` (see `helpers/visualization/`) | `generated_data/figures/*_colormap.png` |

## Specialized plots

| Figure | Script | MATLAB output | Often copied to |
|--------|--------|---------------|-----------------|
| Fixed-height `Pmet` | `plot_fixed_height_Pmet_analysis.m` | `generated_data/figures/heightPmetAnalysisFigures/` | `DataForReport/figures/heightPmetAnalysisFigures/` |
| Fixed vs free | `compare_fixed_vs_free_height_plots.m` | `generated_data/figures/fixed_vs_free_height/` | `DataForReport/figures/fixed_vs_free_height/` |
| BO vs linear F–Δx | `plot_BO_spline_profiles_comparison.m` | `generated_data/figures/BO_splines_vs_linear_force_displacement.png` | `DataForReport/figures/fig_force_displacement_BO_splines_vs_linear_reference.png` |
| Pareto scatter | `plot_pareto_GRF_Pmet.m` | `generated_data/figures/pareto_GRF_vs_meanPmet_*.png` | `DataForReport/figures/fig_pareto_GRF_vs_meanPmet.png` |

## BO

- **`bayesian_optimization_spline.m`** → `generated_data/optimal_spline_*.mat`
- Convergence plot: not exported by default; save `bayesopt` trace if needed.

## Scope

No demographics analyses; mechanics and simulation metrics only.

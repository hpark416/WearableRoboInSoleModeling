# MatlabCode

This folder contains the MATLAB/Simulink implementation for the wearable insole modeling study, including baseline and modified hopper models, parameter-sweep scripts, Bayesian optimization, generated `.mat` data, and colormap figures.

## Current Folder Structure

* `models`: Simulink hopper models.
   * `FullHopper_alt.slx`: modified Simulink hopper model with shoe parameters. Uses a nonlinear spline lookup table for shoe sole force-displacement behavior.
   * `FullHopper_baseline.slx`: baseline model used for comparison. Uses a linear spring model for the shoe sole.
* `generated_data/`: saved simulation outputs (`baseline.mat` and sweep `.mat` files).
   * `figures/`: generated heatmaps.
* `helpers`: functions folder
   * `parfor_progress`: function to support parfor progress printing, from matlab file exchange.
   * `analyze_sole_output.m`: extracts GRF, jump height and metabolic rate from simulation output object.
   * `assemble_sim_inputs.m`: given parameters, generates a single or an array of SimulationInput objects. Accepts `force_table` and `disp_table` for spline-based sole modeling.
   * `eval_all_objectives.m`: function that directly outputs objectives, supports fixing jump height. Updated to pass spline lookup tables through to simulation.
   * `init_contourf.m`: boilerplate to initialize heatmap figure.
   * `load_params.m`: generate sweep parameters for consistency.
* `generate_lookup.m`: builds a force-to-displacement lookup table from 4 spline control points (2 fixed endpoints + 2 optimizable middle points).
* `bayesian_optimization_spline.m`: runs Bayesian optimization over spline middle points and sole thickness to minimize peak GRF.
* `bayesian_optimization_test.m`: original Bayesian optimization script sweeping K_shoe and thickness with linear spring model.
* `fixed_height_test.m`: run simulation sweeps with fixed jump height.
* `gen_fixed_height_figures.m`: generate figures for `fixed_height_test.m`.
* `gen_data.m`: runs simulation sweeps and saves outputs to `generated_data/`.
* `gen_figures.m`: loads sweep outputs and generates contour heatmaps.
* `performance_eval.m`: preliminary 1D evaluation script for stiffness and max compression.
* `spline_force.m`: helper function that evaluates the spline force at a given displacement.

---

## Shoe Sole Modeling Approach

### Linear Spring (Baseline)
The original model approximates the shoe sole as a linear spring:
```
dp_sole = GRF / K_shoe
```
where `K_shoe` is a fixed stiffness value and `dp_sole` is the sole compression.

### Nonlinear Spline (Updated Model)
The updated model replaces the linear spring with a **nonlinear spline** that better reflects real shoe sole behavior. The sole is parameterized by 4 control points:

| Point | Displacement | Force | Description |
|-------|-------------|-------|-------------|
| 1 | 0 m | 0 N | Fixed — unloaded sole |
| 2 | x2 (optimizable) | F2 (optimizable) | Middle point 1 |
| 3 | x3 (optimizable) | F3 (optimizable) | Middle point 2 |
| 4 | 0.023 m | 2300 N | Fixed — max load from literature |

The spline is **inverted** to produce a force-to-displacement lookup table, which is fed into a 1D Lookup Table block in Simulink. This means:
- **Input to Simulink block:** GRF (Ground Reaction Force, N)
- **Output from Simulink block:** dp_sole (sole compression, m)

Since the spline directly defines the force-displacement profile, `K_shoe` is no longer an independent parameter — the shape of the curve implicitly defines the stiffness at each compression level.

---

## Spline Optimization

`bayesian_optimization_spline.m` optimizes the following parameters simultaneously using Bayesian optimization:

| Parameter | Range | Description |
|-----------|-------|-------------|
| `thickness` | 0.005 – 0.025 m | Maximum sole compression (hard stop) |
| `x2` | 0.004 – 0.010 m | Displacement at middle point 1 |
| `F2` | 100 – 1000 N | Force at middle point 1 |
| `x3` | 0.011 – 0.020 m | Displacement at middle point 2 |
| `F3` | 1500 – 2200 N | Force at middle point 2 |

**Constraints enforced:**
- `F3 > F2 + 500 N` — ensures the curve stiffens progressively
- `x2 < x3` — ensures points are in order

**Objective:** minimize peak GRF (ground reaction force)

**Result:** The optimizer found a dual-density sole profile — firm initial contact, soft cushioning middle zone, stiff hard stop — reducing peak GRF by ~13% compared to baseline (1240N → 1082N).

---

## Parameter Sweep Data

`gen_data.m` sweeps:

* `K_shoe` from `20000` to `55000` N/m
* `thickness` (max compression) from `0.005` to `0.025` m (step `0.0025`)

With the spline model, `K_shoe` no longer affects simulation results since the force-displacement profile is fully defined by the spline. The sweep is retained for comparison with the linear spring baseline.

The dataset in `generated_data/` includes:
* `baseline.mat` (baseline simulation output)
* sweep outputs named like `k_<stiffness>_maxcomp_<value>.mat`

---

## Generated Figures

`gen_figures.m` produces contour maps in `generated_data/figures/`:

* `GRF_colormap.png` — peak ground reaction force across parameter grid
* `mean_Pmet_colormap.png` — mean metabolic power proxy
* `dpMass_colormap.png` — peak center of mass displacement (jump height proxy)

---

## Typical Workflow

**Important:** Always make sure MATLAB current folder is set to `MatlabCode/` before running any script. Run `addpath('./helpers')` in the command window if MATLAB cannot find helper functions.

### Step 1 — Run the Spline Optimization
1. Run `bayesian_optimization_spline.m`
2. After 30 iterations it will automatically:
   - Print the optimal parameters (`results.XAtMinObjective`)
   - Save them to `generated_data/optimal_spline.mat`
   - Plot the optimal force-displacement curve

### Step 2 — Run the Parameter Sweep
1. Run `gen_data.m` — loads optimal spline automatically from `optimal_spline.mat`, runs sweep across K_shoe and thickness (uses parallel computing, may take several minutes)
2. Run `gen_figures.m` — generates contour heatmaps in `generated_data/figures/`

### Step 3 — Run Fixed Jump Height Sweep
1. Run `fixed_height_test.m` — sweeps K_shoe and thickness while keeping jump height fixed, loads optimal spline automatically
2. Run `gen_fixed_height_figures.m` — generates contour heatmaps for fixed height results

### Quick 1D Checks
Use `performance_eval.m` for exploratory checks of stiffness or max compression trends.

### Visualizing the Optimal Spline Manually
After running the optimizer, plot the spline anytime using:
```matlab
d = load('./generated_data/optimal_spline.mat');
best = d.best;
[force_table, disp_table] = generate_lookup(best.x2, best.F2, best.x3, best.F3);
plot(disp_table * 1000, force_table)
xlabel('Displacement (mm)'); ylabel('Force (N)')
title('Optimal Spline Force-Displacement')
grid on
```

---

## Dependencies

* MATLAB/Simulink 2020a or later
* Statistics and Machine Learning Toolbox (for Bayesian Optimization)
* Parallel Computing Toolbox (for `parsim` in `gen_data.m`)

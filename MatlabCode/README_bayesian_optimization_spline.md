# `bayesian_optimization_spline.m`

This document describes what [`bayesian_optimization_spline.m`](bayesian_optimization_spline.m) does, how its optimization variables relate to the sole spline, and how it connects to [`helpers/eval_all_objectives.m`](helpers/eval_all_objectives.m) and [`helpers/generate_lookup.m`](helpers/generate_lookup.m).

## Purpose

This script runs **Bayesian optimization** (`bayesopt`) over **six incremental parameters** that define a **piecewise monotone sole force–displacement curve**. For each candidate parameter vector it:

1. Converts deltas to absolute control points (`to_control_points`).
2. Builds lookup tables with [`generate_lookup`](helpers/generate_lookup.m) (PCHIP spline, sampled displacement grid).
3. Evaluates a **scalar objective** by simulating [`FullHopper_kb_splines`](models/FullHopper_kb_splines.slx) through [`eval_all_objectives`](helpers/README_eval_all_objectives.md) at a **fixed jump-height** setting (search over `amplitude` with target peak COM displacement **0.04** m).

Outputs are saved under `generated_data/` as `optimal_spline_<objective_name>.mat`, each containing a struct `best` with absolute control-point positions and forces.

## How to run

1. Set MATLAB’s current folder to **`MatlabCode/`** (the script uses relative paths `./helpers`, `./models`, `./generated_data`).
2. Run the script in the Command Window: `bayesian_optimization_spline`.

### Important: the script runs three optimizations in one execution

The file is structured so that **three separate `bayesopt` runs** execute **back-to-back**:

| Block (approx.) | Objective handle | `objective_name` | Output file |
|-----------------|-------------------|------------------|-------------|
| First call | `@eval_minimize_GRF` | `'GRF'` | `generated_data/optimal_spline_GRF.mat` |
| Second call | `@eval_minimize_Pmet` | `'Pmet'` | `generated_data/optimal_spline_Pmet.mat` |
| Third call | `@eval_normalized_weighted` | `'Normalized'` | `generated_data/optimal_spline_Normalized.mat` |

If you only want one study, **comment out** the other `run_force_disp_BO(...)` blocks (or the middle assignments that switch `objective_fn` / `objective_name`).

To switch a single run manually, set:

```matlab
objective_fn = @eval_minimize_GRF;   % or @eval_minimize_Pmet, @eval_normalized_weighted
objective_name = 'GRF';              % 'Pmet' or 'Normalized' must match
run_force_disp_BO(objective_fn, objective_name)
```

## Model and simulation setup

Inside `run_force_disp_BO`:

- **`model_name`**: `'FullHopper_kb_splines'`.
- Loads the model from `./models/<model_name>.slx` via `load_system`.
- Sets **`SimulationMode`** to **`accelerator`** and **`FastRestart`** to **`off`** (before and after the run).
- **`rng(1)`** for reproducible Bayesian optimization behavior.

## Optimization variables (what `bayesopt` sees)

The optimizer does **not** search raw `(x2, F2), …` directly. It searches **positive increments** (`dx2`, `dx3`, `dx4`, `dF2`, `dF3`, `dF4`), then maps them to absolute control points in `to_control_points`:

```text
x2 = dx2
x3 = x2 + dx3
x4 = x3 + dx4

F2 = dF2
F3 = F2 + dF3
F4 = F3 + dF4
```

So **monotonicity in index** (each displacement and force step adds a nonnegative delta over the previous point) is built into the parameterization, assuming the optimization intervals keep deltas nonnegative.

### Variable bounds

Bounds are derived from [`load_params`](helpers/load_params.m):

- `K_shoes = 20000:2500:55000` and `thicknesses = 0.005:0.0025:0.025`.
- `max_endpoint = [thicknesses(end), thicknesses(end)*K_shoes(end)]` — caps the **last** displacement and the product at the last point (used in constraints and as a scale for search intervals).
- `dx_interval = [0.001, max_endpoint(1)/2]`, `dF_interval = [100, max_endpoint(2)/2]` for the six `optimizableVariable` definitions.

See the script for exact `optimizableVariable` construction.

## `bayesopt` configuration

```matlab
bayesopt(@(params) objective_fn(model_name, params), ...
    [dx2_var, dF2_var, dx3_var, dF3_var, dx4_var, dF4_var], ...
    'IsObjectiveDeterministic', true, ...
    'UseParallel', true, ...
    'MaxObjectiveEvaluations', 30, ...
    'XConstraintFcn', @(params) profile_constraints(params, max_endpoint, K_shoes_interval));
```

- **30** objective evaluations per run (per objective block).
- **Parallel** workers for evaluating candidates (requires Parallel Computing Toolbox behavior consistent with your MATLAB setup).
- **`XConstraintFcn`**: custom nonlinear constraints on the spline end state and an “overall stiffness” proxy (see below).

## Objective wrappers (what is minimized)

Each wrapper builds `mat_params.force_table` and `mat_params.disp_table` from `generate_lookup(to_control_points(params))`, then calls:

```matlab
eval_all_objectives(model_name, mat_params, [0.8, 1.0], 0.04);
```

So every objective uses:

- **Amplitude search range** `[0.8, 1.0]`.
- **Target peak COM displacement** `des_max_dpMass = 0.04` (third argument to `eval_all_objectives` in range mode).

### Choosing a reasonable target peak COM displacement

In this repo, two targets already appear:

- `0.04` m in `bayesian_optimization_spline.m` (current BO setting).
- `0.06` m in `helpers/load_params.m` (`des_dp_Mass` default).

So a practical range for this workflow is **`0.04-0.06` m**, with `0.05` m as a sensible midpoint if you want one standard target.

Selection guidance:

- Use the lower end (`~0.04`) when you want conservative hopping demand and easier feasibility within `[0.8, 1.0]`.
- Use the upper end (`~0.06`) for more aggressive hopping demand, accepting that more candidates may hit range/constraint limits.
- Prefer targets that sit comfortably inside the achievable `max_dpMass` interval over the amplitude range, rather than close to either endpoint.

Brief literature context: reported vertical COM oscillation during running is often on the order of about **6-10 cm** (method-dependent), so `0.04-0.06` m is a plausible lower-to-mid locomotion regime for fixed-height studies in this model family.

- Heiderscheit et al., "Measurements of vertical displacement in running, a methodological comparison," *Gait Posture* (2009), [PubMed](https://pubmed.ncbi.nlm.nih.gov/19356933/).
- Sanno et al., "The use of a single sacral marker method to approximate the centre of mass trajectory during treadmill running," *Journal of Biomechanics* (2021), [ScienceDirect](https://www.sciencedirect.com/science/article/abs/pii/S0021929020303092).

Details of fixed-height search and metrics are documented in [`README_eval_all_objectives.md`](helpers/README_eval_all_objectives.md).

| Wrapper | Scalar returned to `bayesopt` |
|---------|-------------------------------|
| `eval_minimize_GRF` | `max_GRF` |
| `eval_minimize_Pmet` | `mean_Pmet` |
| `eval_normalized_weighted` | `(max_GRF / 1371.1) + (mean_Pmet / 162.895)` — **hard-coded** baseline divisors in the script |

The normalized objective is a **sum of two dimensionless terms**, not a weighted average with tunable weights (unless you edit the script).

### What "normalized weighted" means here

In `eval_normalized_weighted`, the objective is:

```matlab
objective = (max_GRF / 1371.1) + (mean_Pmet / 162.895);
```

- **Normalized**: each metric is divided by a baseline-scale constant, so both terms are unitless.
- **Weighted (implicitly)**: the divisors act like inverse weights. A smaller divisor gives that metric more influence on the total objective.
- **Not a weighted average**: there are no explicit user-tunable weights (for example, no `w1`, `w2`, and no division by `w1 + w2`).

### How the hard-coded divisors work

The constants `1371.1` and `162.895` are fixed reference scales used to put `max_GRF` and `mean_Pmet` on comparable magnitudes before summation.

Practical interpretation:

- If both metrics are near their reference values, each normalized term is near `1`.
- If one normalized term is consistently much larger than the other, that metric dominates optimization pressure.
- Updating these constants changes the GRF-vs-metabolic tradeoff even when model outputs are unchanged.

If you want stable interpretation across studies, compute divisors from a clearly defined baseline run and keep that baseline documented with the results.

## Constraints (`profile_constraints`)

Given `max_endpoint` and `K_shoes_interval = [K_shoes(1), K_shoes(end)]`:

1. **Endpoint feasibility**: last displacement `x4` and last force `F4` must satisfy `x4 ≤ max_endpoint(1)` and `F4 ≤ max_endpoint(2)`.
2. **Overall stiffness proxy**: `overall_k = F4 / x4` must lie in `[K_shoes(1), K_shoes(end)]`.

Returned value `satisfied` is a logical **column vector** (one row per candidate point), as required by `bayesopt` for `XConstraintFcn`.

## Outputs

After each `bayesopt` run:

- **`generated_data/optimal_spline_<objective_name>.mat`** contains **`best`**, the result of `to_control_points(results.XAtMinObjective)` — absolute `x2`, `x3`, `x4`, `F2`, `F3`, `F4`.
- A **figure** plots force vs displacement (displacement in mm) for the optimal curve.

`mkdir('./generated_data')` is called if the folder is missing.

## Related files

| File | Role |
|------|------|
| [`helpers/eval_all_objectives.m`](helpers/eval_all_objectives.m) | Simulates and returns objectives; fixed-height mode used here. |
| [`helpers/README_eval_all_objectives.md`](helpers/README_eval_all_objectives.md) | Deep dive on objectives and amplitude search. |
| [`helpers/generate_lookup.m`](helpers/generate_lookup.m) | Builds PCHIP-based `force_table` / `disp_table` from control points. |
| [`helpers/load_params.m`](helpers/load_params.m) | Shared stiffness/thickness grids and `des_dp_Mass` (note: BO uses **0.04** for evaluation, not necessarily `load_params`’s current `des_dp_Mass`). |
| [`models/FullHopper_kb_splines.slx`](models/FullHopper_kb_splines.slx) | Simulink model consuming the lookup tables. |

## Practical tips

- Expect **long runtime** when all three objective blocks run sequentially (3 × 30 evaluations × simulation cost, plus amplitude search inside each evaluation).
- If parallel pool fails, try `'UseParallel', false` in `bayesopt` (edit script).
- To reuse an optimum elsewhere, `load` the `.mat` file and pass `best` into `generate_lookup` or your sweep scripts as needed.

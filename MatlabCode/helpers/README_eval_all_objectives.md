# `eval_all_objectives.m`

This document describes what [`eval_all_objectives.m`](eval_all_objectives.m) does, how it fits into the simulation pipeline, and where it is used in this repository.

## Purpose

`eval_all_objectives` is the **standard entry point for turning model parameters into scalar objectives** without saving full time-series logs. It:

1. Builds a Simulink `SimulationInput` for the chosen model and material parameters (`assemble_sim_inputs`).
2. Runs one simulation (`sim`).
3. Pulls three metrics from the output (`analyze_sole_output`).

Optionally, when you care about **fixed jump height** (fixed peak center-of-mass displacement), it **searches** over the simulation parameter `amplitude` until the achieved `max_dpMass` is close to a target value.

The top-of-file comment notes that this function is **not** meant to be passed directly to `bayesopt`. Bayesian optimization scripts wrap thin objective functions that call `eval_all_objectives` and then combine or weight outputs as needed.

## Function signature

```matlab
[max_GRF, max_dpMass, mean_Pmet, amplitude_res] = ...
    eval_all_objectives(model_name, material_params, amplitude, varargin)
```

### Inputs

| Argument | Meaning |
|----------|---------|
| `model_name` | String name of the loaded Simulink model (e.g. `'FullHopper_kb_splines'`). |
| `material_params` | Struct describing sole/material behavior, or **empty** for the baseline model with no sole-parameter sweep. See [`assemble_sim_inputs.m`](assemble_sim_inputs.m): may include `K_shoe` / `thickness`, or `force_table` / `disp_table` for spline lookup tables. |
| `amplitude` | Either a **scalar** (prescribed hop amplitude) or a **two-element vector** `[low, high]` giving an allowable range for `amplitude` when doing fixed-height search. |
| `varargin` | Used only in the **range** mode: **first extra argument must be** `des_max_dpMass`, the desired peak COM displacement (`max_dpMass`) to hit via search. |

### Outputs

| Output | Meaning |
|--------|---------|
| `max_GRF` | Peak ground reaction force metric (see below). |
| `max_dpMass` | Peak center-of-mass displacement metric (jump-height proxy). |
| `mean_Pmet` | Metabolic proxy from integrated mean power over a cycle window. |
| `amplitude_res` | If `amplitude` was a **scalar**, this equals that scalar. If `amplitude` was a **range**, this is the `amplitude` value found by search (the one that approximately achieves `des_max_dpMass`). |

## Two operating modes

### 1. Prescribed amplitude (scalar `amplitude`)

```matlab
[max_GRF, max_dpMass, mean_Pmet, amplitude_res] = ...
    eval_all_objectives(model_name, material_params, 1.0);
```

- Runs **one** simulation at that amplitude.
- `amplitude_res` is just the same scalar you passed in.

Use this when amplitude is fixed and you only want objectives for a given material parameter set.

### 2. Fixed jump height — search inside `[amplitude_low, amplitude_high]`

```matlab
des_dp_Mass = 0.04;  % example target peak COM displacement
[max_GRF, max_dpMass, mean_Pmet, amplitude_res] = ...
    eval_all_objectives(model_name, material_params, [0.8, 1.0], des_dp_Mass);
```

- `amplitude` must be a **2-element vector** (search range).
- You **must** supply `des_max_dpMass` as the first `varargin` argument.

Internally this calls `search_amplitude`, which:

- Evaluates objectives at the **ends** of the range (two simulations).
- Stops early if the target lies outside what those endpoints can produce (uses objectives at min or max amplitude).
- Otherwise performs a **recursive interval halving** style search: evaluates at the midpoint, compares achieved `max_dpMass` to `des_max_dpMass`, and narrows the interval.
- Stops when `abs(mid_max_dpMass - des_max_dpMass) < 0.001` (hard-coded in `search_amplitude`), or after **10 iterations** (then takes a fallback midpoint / endpoint behavior per the implementation).

**Important:** Fixed-height search runs **multiple** simulations per call. Scripts that run many parameter combinations in `parfor` (e.g. `gen_sweep_data`) therefore pay this cost per combination. The comment in code warns that `search_amplitude` is not used with nested parallelization in a way that parallelizes the inner search itself.

## Internal pipeline (single simulation)

For each trial amplitude used inside `eval_params`:

```text
assemble_sim_inputs(model_name, material_params, amplitude)
    → sim(simIn)
        → analyze_sole_output(simOut)
            → max_GRF, max_dpMass, mean_Pmet
```

No full signal bundle is returned; only the three scalars (plus possibly `amplitude_res` after search).

## What the three objectives actually are

Metrics come from [`analyze_sole_output.m`](analyze_sole_output.m):

- **`max_GRF`**: For each of the **last three** hop cycles (using a stimulus period `T_stim = 0.4` s), take the max GRF in that cycle, then **average** those three maxima.
- **`max_dpMass`**: Same pattern for `dp_Mass` (peak COM displacement per cycle, averaged over the last three cycles). This is the quantity matched when doing fixed-height search.
- **`mean_Pmet`**: Uses integrated mean metabolic signal `int_mean_Pmet` between two cycle windows to obtain a **difference** (mean power proxy over the relevant interval).

So these are **robust cycle-averaged** metrics, not single-peak values from the entire run.

## Private helpers inside the file

The `.m` file also defines local functions used only here:

- **`eval_params`**: One simulation + `analyze_sole_output`.
- **`search_amplitude`**: Binary-search-like recursion over amplitude for fixed `des_max_dpMass`.
- **`eval_and_pack` / `unpack`**: Pack the three objectives into a row vector for the search bookkeeping.

## Where this function is used in the repo

| Location | Role |
|----------|------|
| [`bayesian_optimization_spline.m`](../bayesian_optimization_spline.m) | Objective wrappers (`eval_minimize_GRF`, `eval_minimize_Pmet`, `eval_normalized_weighted`) call `eval_all_objectives` with **`[0.8, 1.0]`** and **`0.04`** as target COM displacement — i.e. fixed-height evaluation while optimizing spline control points. |
| [`gen_sweep_data.m`](gen_sweep_data.m) | Parameter sweeps in `parfor`: for each material combination, calls `eval_all_objectives` with an amplitude **range** and `des_dp_Mass` to produce comparable objectives at a fixed jump height. |
| [`gen_baseline_data.m`](gen_baseline_data.m) | Optional fixed-height baseline: `material_params` is **`struct([])`** for `FullHopper_baseline`, amplitude range `[0.5, 1]`, and `des_dp_Mass` from `load_params()`. |

If you add new callers, keep the contract clear:

- Scalar `amplitude` → no extra args.
- Two-element `amplitude` → **must** pass `des_max_dpMass` as first `varargin`.

## Practical notes

- Ensure the model is **loaded** (`load_system`) before calling, matching how your calling script does it.
- Add `helpers` (and often `models`) to the path (`addpath(genpath('./helpers'))`) so `assemble_sim_inputs`, `analyze_sole_output`, and any lookup helpers resolve.
- For baseline-only evaluation with empty `material_params`, behavior is delegated to `assemble_sim_inputs` as documented there.

## Related files

- [`assemble_sim_inputs.m`](assemble_sim_inputs.m) — builds `SimulationInput` from model name, material struct, and amplitude.
- [`analyze_sole_output.m`](analyze_sole_output.m) — defines how `max_GRF`, `max_dpMass`, and `mean_Pmet` are computed from `simOut`.

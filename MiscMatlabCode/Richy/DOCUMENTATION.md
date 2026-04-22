# Hopper Shoe-Compliance Model Documentation

## Project Purpose

This folder contains a biomechanics course project implementation that uses a vertical hopper model as a simplified representation of running. The model is modified to include shoe sole compliance so we can study how shoe stiffness changes:

- ground reaction force (GRF),
- and a metabolic-cost proxy derived from MTU mechanics.

The central modeling idea is to separate true body displacement from MTU-effective displacement by modeling shoe compression explicitly.

## Files and Roles

- `FullHopper.slx`
  - Main integrated model used for simulation and analysis.
  - Contains the shoe-compression modification inside load dynamics.
  - Exports key analysis signals to workspace:
    - `GRF_out`
    - `F_mt_out`
    - `dL_MT_out`
    - `dL_MT_rate_out`
    - `stance_out`
    - debug signals including `dp_sole_out` and `dp_sub_out`
  - Includes a `Memory` block on the shoe-compression path to break an algebraic loop.

- `ShoeSoleImpact.slx`
  - Auxiliary/focused model for shoe-ground interaction behavior.
  - Preserves the same core shoe-compression logic (`GRF`, `k`, `thickness` -> `dp_sole`) and displacement correction concept.

- `stiffnessSweepGRFcomp.m`
  - Sweeps shoe stiffness and overlays GRF curves for comparison.
  - Useful for direct impact-shape/peak inspection versus stiffness.

- `metabolicVsStiffness.m`
  - First-pass stiffness sweep script for both:
    - positive MTU-work proxy,
    - peak GRF.
  - Computes total positive MTU power integral after initial transient.

- `metaCostStiffness2.m`
  - Improved cycle-averaged metabolic analysis.
  - Detects hop cycles from stance transitions, averages final cycles, and picks minimum mean cycle cost in tested stiffness range.

- `signal_data_output.mat`
  - Saved simulation output data file associated with this model workflow.

## Main Model Modification (Step-by-Step)

1. Start from original hopper dynamics where CoM motion directly influences MTU kinematics.
2. Keep `dp_Mass` as true body/CoM displacement.
3. Define stance by `dp_Mass < 0`.
4. Interpret `dp_Mass = 0` as the uncompressed sole just touching the ground.
5. Add shoe-compression function block with:
   - `dp_sole = 0` when `GRF <= 0`,
   - otherwise `dp_sole = GRF / k_shoe`,
   - compression saturation: `dp_sole <= thickness`.
6. Compute corrected displacement:
   - `dp_sub = dp_Mass - dp_sole`
7. Compute MTU length change from `dp_sub` (not directly from `dp_Mass`).
8. Log force/kinematic/debug outputs for post-processing scripts.
9. Insert `Memory` in the shoe path to prevent algebraic-loop solve issues.

## Signal Definitions

- `dp_Mass`
  - True vertical body/CoM displacement state from hopper dynamics.

- `dp_sole`
  - Shoe compression magnitude due to GRF and shoe stiffness/thickness limits.

- `dp_sub`
  - Effective displacement seen by MTU mechanics:
  - `dp_sub = dp_Mass - dp_sole`

- `GRF`
  - Ground reaction force from contact dynamics.
  - Also the shoe-compression block input.

- `F_mt_out`
  - MTU force output used in power/cost proxy calculations.

- `dL_MT_out`
  - MTU length change output (computed from corrected displacement path).

- `dL_MT_rate_out`
  - Time derivative of MTU length change.
  - Used with force to estimate MTU mechanical power proxy.

- `stance_out`
  - Stance/contact indicator output used for cycle segmentation.

## Modeling Assumptions

- Vertical hopper approximates important running bounce dynamics.
- Shoe compliance is modeled as linear spring compression with saturation:
  - `x = GRF / k_shoe`, capped by `thickness`.
- No contact (`GRF <= 0`) implies no shoe compression.
- Positive MTU mechanical power is a first-order proxy for metabolic demand.
- Shoe behavior is represented by a small parameter set (`k_shoe`, `thickness`) without full material complexity.

## Stiffness Sweep Method

In `stiffnessSweepGRFcomp.m` and related scripts:

1. Set model workspace parameters (`k_shoe`, `thickness`).
2. Simulate `FullHopper`.
3. Read exported timeseries signals (for example `GRF_out`).
4. Ignore early transient portion (`t >= 0.5 s` in quick sweeps).
5. Compare GRF curves and peak values across stiffness levels.

Tested stiffness range in scripts:

- `[5000, 10000, 20000, 50000, 100000, 200000, 500000]` N/m.

## Metabolic Proxy Computation

In `metabolicVsStiffness.m`:

1. Compute MTU power proxy:
   - `P_mtu = F_mt_out .* dL_MT_rate_out`
2. Keep positive-only component:
   - `P_pos = max(P_mtu, 0)`
3. Integrate over analysis window:
   - `Cost = trapz(t, P_pos)`

This produces a positive mechanical-work proxy (in Joule-like units) used to compare stiffness settings.

## Note on Metabolic Cost Estimation

The scripts `metabolicVsStiffness.m` and `metaCostStiffness2.m` estimate energetic expenditure using a mechanical proxy, rather than a full physiological metabolic model.

### Method Overview

Metabolic cost is approximated from muscle-tendon unit (MTU) mechanical power:

- `P_MTU(t) = F_mt(t) * dL_MT_rate(t)`

Only positive mechanical power is counted:

- `P_plus(t) = max(P_MTU(t), 0)`

The energetic proxy is:

- `E_proxy = integral(P_plus(t) dt)`

In `metaCostStiffness2.m`, this quantity is:

- computed per hop cycle,
- averaged over multiple steady-state cycles,
- used to identify the stiffness that minimizes energetic cost.

### Interpretation

This proxy represents positive MTU work, which is a major contributor to locomotion energy demand.

Lower values suggest:

- less mechanical work required from muscle action,
- potentially improved energetic efficiency.

### Limitations

This method is not a full metabolic-energy model. It does not explicitly include:

- activation and deactivation energetic costs,
- force-maintenance (isometric) energy consumption,
- different efficiencies for shortening versus lengthening contractions,
- explicit separation of muscle-fiber and tendon energetics.

Also, MTU power includes elastic tendon contributions, which do not map one-to-one to direct metabolic energy consumption.

### Justification

Despite these limitations, positive MTU work is commonly used in simplified studies because it:

- captures key trends in energetic demand,
- is computationally efficient,
- supports consistent comparisons across design parameters such as shoe stiffness.

### Conclusion

Results should be interpreted as relative changes in energetic demand, not absolute metabolic energy expenditure. A more physiologically accurate estimate would require explicit muscle energetics (for example activation dynamics and heat-production terms).

## Cycle-Averaged Optimization Method

In `metaCostStiffness2.m`:

1. Run longer simulation (`10 s`) to capture repeated hop cycles.
2. Detect stance starts from `stance_out` rising transitions.
3. Build cycles from one stance start to the next.
4. For each cycle compute:
   - positive MTU work proxy,
   - cycle peak GRF.
5. Use final `n` cycles (default 5) to approximate steady behavior.
6. Compute mean and standard deviation of cycle cost.
7. Select stiffness with minimum mean cycle cost as the best tested value.

## Limitations and Likely Failure Points

- Hopper abstraction omits many full-body running mechanics.
- Linear spring + saturation shoe model omits damping, hysteresis, and rate effects.
- Power sign convention may require validation (`P = F*v` vs `P = -F*v` depending on model sign choices).
- Cycle detection depends on clean stance transitions and thresholding.
- Reported optimum is discrete-grid dependent, not a continuous optimum.
- `Memory` resolves loop numerically but introduces a one-step delay approximation.

## Quick Onboarding Path for New Teammates

1. Read `metaCostStiffness2.m` to understand current evaluation and optimization workflow.
2. Read `metabolicVsStiffness.m` for the simpler cost-proxy implementation.
3. Run `stiffnessSweepGRFcomp.m` to build intuition from GRF overlays.
4. Open `FullHopper.slx` and inspect the shoe-compression function and logged outputs.
5. Use `ShoeSoleImpact.slx` to study the shoe-contact sublogic in a more focused form.

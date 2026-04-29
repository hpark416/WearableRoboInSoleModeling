# Models Overview

This folder contains Simulink models used for hopper and insole simulations.

## Model Files

- `FullHopper_baseline.slx`
  - Baseline full hopper model used as the reference configuration.

- `FullHopper_alt.slx`
  - Alternate full hopper model variant used by current data-generation scripts.

- `Copy_of_FullHopper_alt.slx`
  - Development copy where the algebraic `shoe_disp` block was replaced with a dynamic spring-damper shoe subsystem, with related rewiring and function-block updates while behavior is being validated.
  - Changed blocks are highlighted in orange for quick visual identification.
  - Main dampening control parameter is `b_shoe` (default: `500`).

## Note

Prefer using `FullHopper_alt.slx` or `FullHopper_baseline.slx` for reproducible runs. Use `Copy_of_FullHopper_alt.slx` as the active dampening sandbox until it is validated and promoted.

## Dampening Modeling Note

Running-shoe studies often discuss midsole stiffness, compliance, and energy return as key mechanical properties that affect running economy and loading. Exact vertical stiffness values vary significantly with test method, shoe region, load level, and deformation amplitude. In this model, treat these as simulation parameters spanning soft, moderate, and stiff behavior, not universal shoe constants. Literature on midsole mechanical characteristics and footwear stiffness supports this parameter-sweep approach rather than assuming one fixed "true" stiffness.

### Expected Good Behavior

- `dp_sole` stays between `0` and `thickness`.
- `dp_sole` rarely sits flat at `thickness`.
- `dp_sub` is smoother than the no-damping version.
- `GRF` remains bounded and does not blow up.

### Candidate Parameter Sets

```matlab
% Soft / cushioned
k_shoe = 20000;
b_shoe = 400;
thickness = 0.04;

% Moderate baseline
k_shoe = 50000;
b_shoe = 500;
thickness = 0.035;

% Stiffer shoe
k_shoe = 100000;
b_shoe = 700;
thickness = 0.03;
```

### Quick Validation Procedure

1. Select one candidate parameter set (`k_shoe`, `b_shoe`, `thickness`) and run the model long enough to include multiple hop cycles (for example, `2-5 s`).
2. Plot `dp_sole`, `dp_sub`, and `GRF` versus time for visual inspection.
3. Confirm `dp_sole` remains in `[0, thickness]` and does not remain pinned at `thickness` for long intervals.
4. Compare `dp_sub` against the no-damping case and verify the damped result is smoother.
5. Check `GRF` for numerical blow-up, unrealistic spikes, or sustained divergence.
6. Repeat across soft, moderate, and stiff settings and keep the set that provides stable and physically reasonable behavior.

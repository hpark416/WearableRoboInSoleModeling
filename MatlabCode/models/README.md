# Models Overview

This folder contains the active Simulink model variants used by scripts in `MatlabCode/`.

## Model Files

- `FullHopper_baseline.slx`
  - Baseline reference model used for comparisons.

- `FullHopper_k.slx`
  - Variant focused on shoe stiffness (`k`) effects.

- `FullHopper_kb.slx`
  - Variant with stiffness + damping (`k`, `b`) style sole behavior.

- `FullHopper_kb_splines.slx`
  - Variant with spline-defined nonlinear sole force-displacement behavior.

## Usage Notes

- Most parameter-sweep scripts target the non-baseline variants through `SimulationInput` assembly in `MatlabCode/helpers/`.
- If results look unstable, first verify `thickness`, stiffness, and damping/spline settings are physically consistent.
- Keep model-level naming consistent with script expectations; scripts assume these exact file names.

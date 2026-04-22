# Matlab Code

This folder contains MATLAB and Simulink code for modeling and evaluating wearable insole design effects on running dynamics.

## Intended Contents

- simulation scripts (`.m`) for parameter sweeps and post-processing,
- model files (`.slx`) for hopper-based or derived locomotion simulations,
- helper functions for force-displacement, stiffness, and damping formulations.

## Suggested Organization

- `models/`: Simulink models and variants.
- `scripts/`: runnable experiment scripts.
- `functions/`: reusable utility functions.
- `outputs/`: optional intermediate data files (if kept in-repo).

## Project Context

Code in this folder should align with the proposal goals:

- compare sole stiffness assumptions (spring / spring-damper formulations),
- evaluate effects on GRF-related behavior and energetic proxies,
- support scenario comparisons across demographic and environment parameters.

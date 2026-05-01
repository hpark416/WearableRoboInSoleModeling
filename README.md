# Wearable Robo Insole Modeling

MATLAB/Simulink project for studying how shoe sole mechanical behavior changes running dynamics in a hopper-style model.

## Current Focus

The active workflow in this repo is:
- model the sole as a nonlinear force-displacement curve (spline),
- optimize spline control points and thickness with Bayesian optimization,
- run sweep studies and fixed-jump-height studies,
- and compare peak GRF, displacement, and metabolic proxy metrics.

## Main Dependencies

- MATLAB/Simulink 2020a or later
- Statistics and Machine Learning Toolbox (Bayesian optimization)
- Parallel Computing Toolbox (`parsim`-based sweep runs)

## Repository Layout

- `MatlabCode/`: primary and actively updated simulation codebase (models, helpers, optimization, sweeps, and generated outputs).
- `MatlabCode/models/`: current Simulink model variants (`FullHopper_baseline.slx`, `FullHopper_k.slx`, `FullHopper_kb.slx`, `FullHopper_kb_splines.slx`).
- `MiscMatlabCode/SplineMatlabCode/`: older parallel branch/snapshot of spline experiments retained for reference.
- `Project Proposal/`: original scope document and project report PDF.
- `PapersResearch/`: literature tracking notes and references.
- `DataForReport/`: placeholder folder for curated report assets (currently minimal).
- `MiscMatlabCode/`: archived comparison material and external/reference model files.

## Where To Start

1. Open `MatlabCode/README.md` for the active workflow.
2. Use `MatlabCode/models/README.md` for model-level details.
3. Use `MiscMatlabCode/SplineMatlabCode/README_SPLINE.md` only as legacy background/reference.

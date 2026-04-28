# Wearable Robo Insole Modeling

This repository contains a course project investigating optimal shoe sole and insole design for running performance and impact mitigation.

## Matlab Toolbox dependencies
This repository is developed with MATLAB/Simulink 2020a. Additional toolboxes are: 
- Statistics and Machine Learning Toolbox (for Bayesian Optimization)
- Parallel Computing Toolbox (to speed up simulation, but not implemented yet)

## Project Focus

Based on the proposal in `Project Proposal/Wearable_Robotics_Project_Report.pdf`, the project explores:

- how sole stiffness (and potentially thickness/material behavior) affects running dynamics,
- how demographic factors may change ideal insole properties,
- and how surface/task differences may influence outcomes.

The modeling approach is based on a hopper-style simulation framework intended to approximate key running dynamics such as elastic energy storage/return and aerial stance phases.

## Repository Structure

- `Project Proposal/`: Source proposal and planning documentation.
- `PapersResearch/`: Literature notes and reference tracking.
- `DataForReport/`: Curated key figures, datasets, and assets used in reports and other project deliverables.

## Expected Outputs

- simulation/model updates for insole behavior,
- parameter studies across sole properties and user/environment assumptions,
- and quantitative comparisons (e.g., force profile or energetic implications) supported by figures and references.

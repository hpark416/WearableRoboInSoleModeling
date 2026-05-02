# Wearable Insole Modeling for Hopping: Parameter Sweeps and Bayesian Optimization

**Authors:** [Name 1], [Name 2], [Name 3]  
**Affiliation:** Georgia Institute of Technology, Mechanical Engineering  
**Course/Project:** Wearable Robotics Project  
**Date:** [Insert date]

## Abstract

This report presents a simulation-based workflow for evaluating wearable insole designs using a hopping model. We first study a low-dimensional sole design space using two parameters (effective stiffness and maximum compression/thickness) and generate objective landscapes for peak ground reaction force (`max_GRF`), peak center-of-mass displacement (`max_dpMass`), and metabolic proxy (`mean_Pmet`). We then apply Bayesian optimization (BO) to identify high-performing designs and verify whether BO solutions align with low regions of sweep-based colormaps. After validating the pipeline in the simple setting, we extend the design to a spline-based nonlinear force-displacement profile with higher-dimensional control points and re-run BO for multi-objective tradeoffs. Current results establish a reproducible framework and show that nonlinear profile shaping is practical in this modeling environment. We also document key constraints and open questions, including mass-scaling limits in the single-leg model and the observed behavior of metabolic cost under prescribed jump-height constraints.

**Keywords:** wearable robotics, insole modeling, hopping, Bayesian optimization, force-displacement spline, metabolic proxy

## I. Introduction

Wearable footwear and lower-limb assistive systems are often evaluated through competing objectives, including impact mitigation and energetic cost. In simulation, this appears as a tradeoff between lowering peak force and lowering metabolic effort. Our project studies this tradeoff in a hopping-based model where sole mechanics can be varied from simple linear parameterizations to nonlinear spline-based profiles.

The immediate goals are:

1. build an interpretable baseline using low-dimensional parameter sweeps,
2. validate optimization behavior in that low-dimensional space,
3. scale to a richer nonlinear sole representation,
4. generate figure-ready outputs for report-quality comparison.

At this stage, no demographics or subgroup analyses are included; the emphasis is model mechanics and optimization behavior.

## II. Methods

### A. Simulation Models and Metrics

The workflow uses model variants in the `FullHopper_*` family, including baseline, stiffness/damping variants, and a spline-based sole model. For each simulation, objective metrics are extracted as:

- `max_GRF`: impact-related peak force metric,
- `max_dpMass`: peak center-of-mass displacement proxy,
- `mean_Pmet`: metabolic power proxy.

For fixed-height comparisons, actuation amplitude is searched within a bounded interval to approximately match a prescribed `max_dpMass`.

### B. Simple Design Space (2 Parameters)

The low-dimensional sweep uses:

- `K_shoe` (effective stiffness),
- `thickness` (maximum compression/thickness scale).

This forms a 2D landscape where colormaps are generated for each objective. These maps provide global context and act as a reference for BO validation.

### C. Bayesian Optimization in Low- and High-Dimensional Spaces

In the simple setting, BO is used as a consistency check: BO minima should be near favorable regions observed in the sweep colormaps.

In the advanced setting, BO is applied to spline control-point increments that define a monotone nonlinear force-displacement profile. This parameterization expands the design space beyond practical exhaustive sweeps.

Current BO scalar objectives include:

- minimize `max_GRF`,
- minimize `mean_Pmet`,
- minimize normalized sum:

\[
J = \frac{\mathrm{max\_GRF}}{1371.1} + \frac{\mathrm{mean\_Pmet}}{162.895}
\]

where divisors are fixed normalization constants in the current implementation.

### D. Practical Constraints and Current Operating Regime

Based on project guidance and model behavior:

- single-leg runs currently use `35 kg`,
- `70 kg` single-leg cases are not currently robust under present control limits,
- activation is bounded in `[0,1]`,
- pulse width is currently held at `10%` (with possible sensitivity checks at `20%`).

## III. Results (Current Progress)

### A. Completed Implementation Milestones

- Hopping behavior achieved in simulation.
- Damping introduced and integrated into model variants.
- Spline force-displacement formulation implemented.
- BO pipeline operational for multiple objective formulations.

### B. Figure Artifacts Ready/Planned

Current scripts and notes support generation of:

- baseline vs optimized force-displacement curves,
- sweep colormaps for `max_GRF`, `mean_Pmet`, and `max_dpMass`,
- fixed-height colormap variants,
- BO-derived best-candidate parameter files.

Planned additions include:

- BO convergence traces,
- GRF-vs-Pmet tradeoff scatter (Pareto-style),
- overlay plots comparing simple and spline-derived candidate profiles.

### C. Key Observation Requiring Interpretation

A recurring observation is that prescribing baseline jump height can increase `mean_Pmet` in some conditions, and metabolic contours may remain similar between prescribed-height and non-prescribed settings.

Current working interpretation: energetic proxy is driven not only by movement amplitude but also by force-generation timing/rate and actuator operating regime. Under a height constraint, control solutions may shift into less favorable conditions even if displacement target is reduced.

## IV. Discussion

### A. Why Compare Simple Sweep vs Spline BO?

The comparison serves both methodological and design purposes:

- **Method check:** low-dimensional sweep gives a visible objective landscape against which BO behavior can be judged.
- **Design insight:** if spline BO outperforms the simple-model frontier, then nonlinear profile shaping adds value beyond selecting a single stiffness/thickness pair.

In practical footwear terms, this moves from "choose one stiffness" toward "engineer the full compression-response curve."

### B. Why 70 kg May Be Infeasible in Current Setup

A plausible explanation is a force-time/impulse limitation under bounded activation and fixed pulse width. Higher mass increases required support impulse and active work; if controller and actuation bounds cannot supply sufficient support in stance, stable target behavior fails.

This should be reported as a model-capacity limitation under current assumptions, not a general human biomechanics conclusion.

### C. Pulse Width Context

Model pulse width is a control abstraction rather than a direct physiological measurement. Still, locomotion timing literature supports the idea that stance timing differs substantially across gaits (longer in walking, shorter in running), making pulse-width sensitivity studies (for example, 10% vs 20%) reasonable for robustness analysis.

## V. Limitations

- No human-subject demographics analysis is included.
- Some interpretations are currently hypothesis-based and require dedicated diagnostic plots.
- Combined normalized objective depends on fixed divisors; tradeoff emphasis changes with normalization choices.
- Final quantitative claims should be delayed until figure set and statistics are frozen.

## VI. Conclusion

We have established a functioning and extensible simulation-to-optimization pipeline for wearable insole design in hopping. The current work demonstrates:

1. reproducible low-dimensional sweep analysis,
2. operational BO for both simple and spline-based design spaces,
3. a clear path toward final report figures and comparative conclusions.

The next phase is to finalize fixed-height comparison figures, run targeted analyses for the `mean_Pmet` height-constraint behavior, and lock report-ready quantitative summaries.

## Acknowledgment

This project benefited from course office-hours feedback on practical model constraints and control assumptions.

## References (Working)

[1] D. A. Heiderscheit et al., "Measurements of vertical displacement in running, a methodological comparison," *Gait & Posture*, 2009. [PubMed](https://pubmed.ncbi.nlm.nih.gov/19356933/)  
[2] M. Sanno et al., "The use of a single sacral marker method to approximate the centre of mass trajectory during treadmill running," *Journal of Biomechanics*, 2021. [ScienceDirect](https://www.sciencedirect.com/science/article/abs/pii/S0021929020303092)  
[3] G. Cappellini et al., "Motor patterns in human walking and running," *Journal of Neurophysiology*, 2006. [JNP](https://journals.physiology.org/doi/full/10.1152/jn.00081.2006)  
[4] T. F. Novacheck, "The biomechanics of running," *Gait & Posture*, 1998. [PubMed](https://pubmed.ncbi.nlm.nih.gov/10200376/)  
[5] A. Hasaneini et al., "Elastic energy savings and active energy cost in a simple model of running," *PLOS Computational Biology*, 2021. [PLOS](https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1009608)  
[6] C. J. Arellano and R. Kram, "Partitioning the metabolic cost of human running: a task-by-task approach," *Integrative and Comparative Biology*, 2014. [PMC](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4296200/)

## Appendix: Fill-In Checklist Before Submission

- Insert final author names and affiliations.
- Replace qualitative language with finalized numeric results where available.
- Link each figure reference to final file names in `DataForReport/figures/`.
- Add exact BO settings and selected fixed-height target(s) used for final comparisons.
- Verify all references in final citation style required by your instructor/template.

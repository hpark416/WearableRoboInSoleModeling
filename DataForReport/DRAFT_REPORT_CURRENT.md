# Wearable Insole Modeling Project - Draft Report (Current)

## Project Status Snapshot

This draft summarizes what is currently implemented and what conclusions are reasonable at this stage of the project.

Completed items:

- Hopping model behavior has been achieved and simulated.
- Damping has been added to improve smoothness of displacement behavior (for example, `dp_sub` behavior).
- Spline-based force-displacement sole modeling has been implemented.
- Bayesian optimization (BO) is working for spline parameter search under multiple objective definitions.

Current constraints from office-hours guidance:

- For single-leg modeling, use the original mass setting of `35 kg`.
- The model is not currently robust/feasible at `70 kg` for single-leg conditions.
- Activation is bounded in `[0, 1]` and is the primary tunable control variable.
- Pulse width guidance is currently `10%` (with possible sensitivity checks at `20%`).

## Motivation and Framing

The project studies how insole mechanics affect hopping-related performance metrics using simulation. The goal is to identify sole parameter choices that reduce impact-related load and/or energetic proxy cost, while maintaining target movement behavior.

The central tradeoff is between:

- reducing peak ground reaction force (`max_GRF`), and
- reducing metabolic proxy (`mean_Pmet`),

under consistent task demand (including fixed-height comparisons when needed).

## Modeling and Optimization Pipeline

Current simulation pipeline:

1. Define sole parameters (simple or spline-based).
2. Run Simulink model variants (`FullHopper_*`).
3. Extract objectives (`max_GRF`, `max_dpMass`, `mean_Pmet`).
4. Use either:
   - parameter sweeps (for landscape mapping), or
   - Bayesian optimization (for efficient search in larger parameter spaces).

### Objective definitions used in optimization

- **GRF objective:** minimize `max_GRF`.
- **Metabolic objective:** minimize `mean_Pmet`.
- **Normalized combined objective:** minimize

\[
J = \frac{\mathrm{max\_GRF}}{1371.1} + \frac{\mathrm{mean\_Pmet}}{162.895}
\]

This objective is a sum of normalized terms (dimensionless), with implicit weighting through divisor choice.

## Simple Model vs Advanced Model (Key Deliverable Logic)

### Simple model (2-parameter sweep)

The simple model uses two interpretable parameters:

- `K_shoe` (effective sole stiffness),
- `thickness` (compression/thickness scale).

These are swept on a grid to produce colormaps of `max_GRF`, `mean_Pmet`, and `max_dpMass`.

Why this matters:

- gives a global landscape view,
- helps identify tradeoff regions,
- provides an interpretable baseline for optimization behavior.

### BO on simple model (validation step)

Using BO in this low-dimensional setting serves as a method check:

- if BO finds points near colormap minima, optimization setup is likely working correctly;
- if not, investigate objective scaling, constraints, or evaluation settings.

### Advanced spline model (higher-dimensional BO)

The spline model parameterizes nonlinear force-displacement behavior with multiple control-point variables (via monotone deltas mapped to `x2,x3,x4,F2,F3,F4`).

Why BO is appropriate here:

- the space is too high-dimensional for dense exhaustive grid sweeps,
- BO can sample efficiently and still discover strong candidates.

Real-world interpretation:

- simple model corresponds to "pick stiffness and thickness,"
- spline model corresponds to "shape the full nonlinear sole response curve."
- gains in spline BO beyond simple-model frontiers suggest value in profile-shaping design, not just single stiffness selection.

## Fixed-Height Evaluation and Target Selection

To compare designs fairly, the workflow can search actuation amplitude to match target peak COM displacement (`max_dpMass`).

Current practical target range in this project:

- `0.04 m` (used in spline BO script),
- `0.06 m` (used in shared parameters),
- with `0.05 m` as a practical midpoint candidate.

## Current Observation to Explain: Prescribed Height vs `mean_Pmet`

Team observation:

- prescribing baseline jump height can increase metabolic proxy (`mean_Pmet`) in some cases,
- and metabolic contours may not change much between constrained-height and unconstrained settings.

Working explanation (hypothesis):

- energetic cost depends on force-production timing/rate and muscle operating regime, not only COM excursion magnitude;
- matching a target height can force actuation patterns that are metabolically less favorable;
- therefore, lower height does not automatically imply lower metabolic cost in the model.

Recommended follow-up analysis:

- plot `mean_Pmet` vs `amplitude_res` for fixed-height runs,
- compare alongside `max_GRF` and achieved `max_dpMass`,
- inspect whether control saturation or short force windows correlate with higher `mean_Pmet`.

## Why 70 kg May Fail While 35 kg Works

At higher modeled mass, required impulse and active work increase. With bounded activation (`[0,1]`) and fixed pulse width assumptions, the actuator may be unable to produce sufficient force-time support during stance, leading to failure to sustain target hopping behavior.

Interpretation for reporting:

- this is a model operating-range limitation under current control/parameter assumptions,
- not a general claim about human locomotion limits.

## Pulse Width Context (for Discussion)

Model pulse width is a control abstraction, but gait literature gives context for plausible timing windows:

- walking commonly has larger stance fraction (often around 60% of cycle),
- running has shorter stance and duty factor below 50% due to flight phase.

Therefore:

- `10%` pulse width is a strict/short actuation assumption,
- `20%` sensitivity checks are reasonable for robustness testing, especially at higher demand.

## Figures and Tables to Include (Current Plan)

Primary figures:

1. pipeline overview,
2. baseline vs optimized force-displacement curves,
3. 2D colormaps (`max_GRF`, `mean_Pmet`, `max_dpMass`),
4. fixed-height comparison panels,
5. GRF-vs-Pmet tradeoff scatter,
6. BO convergence traces.

Primary tables:

- model variant summary,
- objective definition summary,
- best BO candidate summary (for each objective mode).

## Limitations (Current Stage)

- No demographics or subgroup analysis (out of scope).
- Some explanations are currently hypothesis-driven and need direct confirmation from additional diagnostics.
- Combined normalized objective depends on fixed divisors; tradeoff balance is sensitive to these choices.

## Next Steps

1. Finalize standardized fixed-height target(s) for main figures.
2. Generate/copy finalized figures to `DataForReport/figures/`.
3. Add one focused analysis on `mean_Pmet` vs prescribed height mechanism.
4. Add one focused analysis comparing successful `35 kg` vs failing `70 kg` attempts (if reruns are planned).
5. Freeze a report-ready set of objective normalizers and document baseline source.

## References (Working List)

- Heiderscheit et al. (2009). Measurements of vertical displacement in running, a methodological comparison. *Gait & Posture*. [PubMed](https://pubmed.ncbi.nlm.nih.gov/19356933/)
- Sanno et al. (2021). The use of a single sacral marker method to approximate the centre of mass trajectory during treadmill running. *Journal of Biomechanics*. [ScienceDirect](https://www.sciencedirect.com/science/article/abs/pii/S0021929020303092)
- Cappellini et al. (2006). Motor patterns in human walking and running. *Journal of Neurophysiology*. [JNP](https://journals.physiology.org/doi/full/10.1152/jn.00081.2006)
- Novacheck (1998). The biomechanics of running. *Gait & Posture*. [PubMed](https://pubmed.ncbi.nlm.nih.gov/10200376/)
- Hasaneini et al. (2021). Elastic energy savings and active energy cost in a simple model of running. *PLOS Computational Biology*. [PLOS](https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1009608)
- Arellano and Kram (2014). Partitioning the metabolic cost of human running: a task-by-task approach. *Integrative and Comparative Biology*. [PMC](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4296200/)

---

This draft is intentionally scoped to current implemented work and known observations. It can be expanded into final report prose after figure generation and final result checks.

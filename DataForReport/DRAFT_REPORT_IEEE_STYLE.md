# Investigation on Optimal Shoe Sole Design: Simulation, Sweeps, and Optimization in a Hopper Model

**Authors:** Kaitlyn Bagnoni, Hyungjun Park, Junling Mei  
**Affiliation:** Georgia Institute of Technology, Mechanical Engineering  
**Course/Project:** Wearable Robotics Project (ME 6409)  
**Date:** May 6, 2026  

*Internal draft: technical results and figure paths align with **[REPORT_DRAFTING_NOTES.md](REPORT_DRAFTING_NOTES.md)** and **[figures/heightPmetAnalysisFigures/FINDINGS_AND_NEXT_STEPS.md](figures/heightPmetAnalysisFigures/FINDINGS_AND_NEXT_STEPS.md)**.*

This document merges the **original project proposal** (*Wearable Robotics Project Report*, PDF in `Project Proposal/`) with the **current simulation workflow**. The proposal motivated broad questions (demographics, terrain); the present report emphasizes what is implemented in MATLAB/Simulink and what can be concluded from those simulations.

## Abstract

Many sports shoes use thick, flexible soles aimed at comfort, but relatively little work ties everyday sole choices to **quantitative** user outcomes such as **metabolic cost** and **ground impact force**. It is also natural to ask how sole material and geometry should be tuned across **people** and **environments** (e.g., surface stiffness, incline). Motivated by those questions, we study **sole stiffness** and related parameters—notably **thickness / compression range** and, in an extended formulation, **nonlinear force–displacement curves**—using a **hopper-based simulation** as a tractable surrogate for **running**, where elastic tissues and bouncing CoM motion play a central role [4].

This report documents the **simulation-to-optimization pipeline** in the `FullHopper_*` model family: **two-parameter sweeps** (`K_shoe`, `thickness`) that map objectives including peak ground reaction force (`max_GRF`), peak center-of-mass displacement (`max_dpMass`), and metabolic proxy (`mean_Pmet`); **Bayesian optimization (BO)** to recover high-performing designs and validate against sweep landscapes; and **spline-based soles** with higher-dimensional control. We compare **fixed-height** (bounded amplitude search to a target peak COM lift) and **free-height** (fixed stimulation) protocols on the same grid, and summarize **iso-height** variation in `mean_Pmet` using stimulation and kinematic proxies (**FINDINGS_AND_NEXT_STEPS.md**). Figure-ready assets include force–displacement overlays (linear reference soles vs BO splines), colormaps, fixed vs free-height panels, and an objective-space scatter of sweep points vs BO optima.

**Scope note:** the original proposal discussed **demographic** variation and richer environments; **no human-subject or subgroup analysis** appears here—only model-based results under stated mass and control assumptions.

**Keywords:** wearable footwear, insole modeling, hopping, running surrogate, Bayesian optimization, force-displacement spline, metabolic proxy

## I. Introduction

### A. Problem motivation (from the original proposal)

Commercial athletic footwear often emphasizes **thick, compliant soles** and perceived comfort. Despite widespread use, design choices are not always connected to **measurable** benefits such as reduced impact loading or reduced energetic cost. Open questions include how **sole stiffness and geometry** interact with the user and task, and whether **optimization** should depend on **population** (e.g., body mass, muscle–tendon properties) and **context** (surface stiffness, slope, speed).

### B. Task choice and modeling simplification

We target **running**, a demanding activity associated with **injury risk** under unfavorable loading [4]. Full human locomotion is high-dimensional; we follow the course-provided **hopper model** (`FullHopper`) because running and hopping share **elastic energy exchange**, **aerial phases**, and bouncing CoM motion—making the hopper a **deliberately simplified** but mechanistically related testbed.

### C. Current project goals (simulation emphasis)

Within that framing, the implemented work aims to:

1. Express sole mechanics in the hopper (compression affecting **effective** CoM motion relative to the foot).
2. Map a **low-dimensional** design space with sweeps and interpret **tradeoffs** among impact (`max_GRF`) and metabolic proxy (`mean_Pmet`).
3. Use **BO** first as a **validation** tool in low dimensions, then to explore **nonlinear** spline soles where exhaustive grids are impractical.
4. Produce **report-quality figures** and a concise statistical summary for **matched jump-height** conditions.

## II. Background and Related Work

**Shoe and foot stiffness.** Oleson et al. [1] relate **shoe bending stiffness** to **forefoot** mechanics in running; human forefoot stiffness can dominate the **combined** foot–shoe stiffness, so shoe bending stiffness may be secondary—yet timing near **toe-off** may increase the role of shoe stiffness.

**Flexibility and energetics.** McDonald et al. [2] show that adding flexibility at a prosthetic toe can alter **push-off work** in walking—motivating that **local compliance** at the **foot–ground interface** can change task energetics.

**GRF and sole hardness.** Zanetti and Brennan [3] compare **GRF models** that incorporate footwear; **hard soles** can yield a **sharper initial impact peak** than **soft soles**, while other phases of the GRF may remain similar. That supports the intuition that **sole mechanical behavior** shapes **impact-related** loading traces.

**Running and hopping dynamics.** Farley and Ferris [4] review **CoM motion** and muscle action in walking and running; characteristics such as **flight phases** and elastic bouncing overlap with the hopper abstraction used here.

## III. Sole–Body Coupling in the Hopper (Conceptual Formulation)

The original proposal outlined modifying the provided hopper so that **sole compression** contributes to **body CoM displacement**; only the motion **after** subtracting sole compression—displacement of the body relative to the **bottom of the foot**—should drive **muscle–tendon unit (MTU)** kinematics as intended by the course model.

Let **sole displacement** be \(dp_{\mathrm{sole}} = x_k(F_{\mathrm{GRF}})\) from a (possibly nonlinear) **force–displacement** relation, with conventions chosen so compression is consistent with the Simulink implementation. The **subtracted** CoM track is \(dp_{\mathrm{sub}} = dp_{\mathrm{COM}} - dp_{\mathrm{sole}}\), which feeds MTU length changes (via the model’s `EMA` path). The proposal discussed **linear spring**, **spring–damper**, and **mass–spring–damper** idealizations; **monotonicity** of the stress–strain curve matters for unique force-from-displacement maps.

**Load mass.** Running is predominantly **single-leg** support; the proposal noted using **35 kg** as in the provided single-leg hopper, with awareness that **doubling** mass might better mimic alternating legs—an item left for future refinement.

The **implemented** repository realizes these ideas through `FullHopper_k`, `FullHopper_kb`, and `FullHopper_kb_splines` variants (`MatlabCode/models/`), with shared assembly and objective extraction in `MatlabCode/helpers/`.

## IV. Planned Variables and Study Scope (Proposal vs Current Repo)

The proposal listed **independent variables** to examine over time:

1. **Demographic / anthropometric differences** (e.g., weight, MTU parameters, activation)—**not** parameterized as population cohorts in the current simulation-only report.
2. **Sole properties** — **implemented** as `K_shoe` and `thickness` sweeps, plus **spline** shape parameters for BO.
3. **Environment and task** — surface stiffness/incline and gait demands were named in the proposal; **current scripts** focus on the hopper task with prescribed protocols (**fixed** vs **free** peak height) rather than full terrain models.

This section documents **intent** from the proposal; quantitative claims in **Sections VI–VII** refer to the **actual** sweeps and assets cited.

## V. Methods (Implemented Workflow)

### A. Simulation models and metrics

Model variants: baseline, stiffness (`FullHopper_k`), stiffness + damping (`FullHopper_kb`), and spline-based nonlinear soles (`FullHopper_kb_splines`). For each run, objectives include:

- `max_GRF` — peak ground reaction force (impact-related),
- `max_dpMass` — peak COM displacement proxy,
- `mean_Pmet` — metabolic power proxy (averaged per project conventions).

**Fixed-height** mode searches stimulation **amplitude** in a bounded interval (e.g. `[0.8, 1]` in current sweep scripts) to match a prescribed peak displacement target from shared **`load_params.m`**. **Free-height** mode holds stimulation fixed (typically `amplitude = 1`) so peak displacement **floats** with sole parameters; overlays (`compare_fixed_vs_free_height_plots.m`) separate **task constraint** from **sole mechanics**.

### B. Simple design space (two parameters)

Sweeps use `K_shoe` and `thickness` to build **2D colormaps** for each objective—global context and a reference for BO behavior.

### C. Bayesian optimization

In low dimension, BO checks **consistency** with sweep minima. For splines, BO searches control-point adjustments defining a **monotone** force–displacement curve—expanding the design space beyond a coarse grid.

Scalar BO objectives used in the codebase include: minimize `max_GRF`, minimize `mean_Pmet`, and minimize

\[
J = \frac{\mathrm{maxGRF}}{1371.1} + \frac{\mathrm{meanPmet}}{162.895},
\]

with fixed normalizers as in the implementation.

### D. Operating constraints (office-hours and robustness)

- Single-leg runs use **35 kg**; **70 kg** single-leg cases are **not** robust under present control limits.
- Activation is bounded in `[0, 1]`; pulse width is often **10%** (20% as a possible sensitivity case).

## VI. Results (Current Progress)

### A. Milestones

- Stable hopping in simulation; damping integrated for smoother sole-related motion.
- Spline **force–displacement** formulation and BO pipeline for multiple objectives.
- Fixed-height correlation analysis and figure export (`plot_fixed_height_Pmet_analysis.m`).

### B. Figures and summary artifacts

Curated paths under **`DataForReport/figures/`** (see **REPORT_DRAFTING_NOTES.md**). **`MatlabCode/generated_data/`** is **gitignored** — colormap paths below are **local regeneration targets**, not files shipped with the repo.

- Pipeline overview: `draft_system_pipeline_overview.svg`.
- Force–displacement: `fig_force_displacement_BO_splines_vs_linear_reference.png` (`plot_BO_spline_profiles_comparison.m`).
- Sweeps: colormaps from `gen_sweep_colormaps` → `MatlabCode/generated_data/figures/` (e.g. `FullHopper_kb_*_colormap.png`).
- Fixed-height `Pmet` analysis: `figures/heightPmetAnalysisFigures/` plus **`FINDINGS_AND_NEXT_STEPS.md`**.
- Fixed vs free height: `figures/fixed_vs_free_height/`.
- Objective-space scatter: `fig_pareto_GRF_vs_meanPmet.png` (`plot_pareto_GRF_Pmet.m`).

Optional: **BO convergence** plots if traces are saved from `bayesian_optimization_spline.m`.

### C. Prescribed height and metabolic proxy

Team observation: prescribing baseline jump height can **raise** `mean_Pmet` in some conditions, and **contour maps** may look similar across prescribed vs free-height protocols.

The **iso-height** sweep summary indicates that with peak COM displacement held near target, `mean_Pmet` still **spans a wide range** across soles; it tracks **resolved stimulation** and **dynamic/muscle proxies** more than residual height error. Prescribed and free-height sweeps are **different control protocols**—contour similarity alone does not prove absence of an effect. **Peak GRF** is not a simple substitute for `mean_Pmet` (nonlinear association). Details: **`figures/heightPmetAnalysisFigures/FINDINGS_AND_NEXT_STEPS.md`**.

## VII. Hypotheses and Interpretation (Proposal Meets Data)

**Original hypothesis (proposal).** From GRF-style plots where **hard soles** show a **higher impact peak** than **soft soles** [3], the team hypothesized that **increasing sole stiffness** could increase **energy dissipation or unfavorable loading**, implying **higher metabolic cost** for the same task speed—while noting caveats for populations with altered tendon function (e.g., elderly) who might favor **softer** soles [proposal text].

**Simulation-supported nuance (current work).** The **fixed-height** datasets show that **`mean_Pmet` variation** at matched height is **not** explained by small peak-height residuals alone; **drive and dynamics** matter. The **GRF–`mean_Pmet`** relationship is **not** a clean one-dimensional tradeoff (see correlation discussion in **FINDINGS_AND_NEXT_STEPS.md**). **Spline BO** can reach objective combinations **outside** the straight-table sweep cloud—supporting the design intuition that **nonlinear profile shaping** matters beyond picking a single stiffness/thickness pair.

## VIII. Discussion

### A. Simple sweep vs spline BO

The 2D sweep gives an interpretable **landscape**; BO on splines targets **shapes** that exhaustive gridding cannot cover. If BO improves beyond the simple frontier, **engineered nonlinear profiles** are justified in this model—not only “pick stiffness.”

### B. Mass scaling and 70 kg

Higher mass raises required **impulse** and **active work**; with bounded activation and narrow pulse width, the model can hit **force–time limits**. Report this as a **model-capacity** limitation under current assumptions.

### C. Pulse width

Model pulse width is a **control abstraction**, not a direct physiological measure; gait-timing literature still motivates **sensitivity** checks (e.g., 10% vs 20%).

## IX. Limitations

- **No demographic** or subgroup analysis; proposal motivations on populations are **not** tested here.
- Terrain/incline extensions from the proposal are **not** fully implemented in reported figures.
- Normalized BO objective weights depend on **fixed divisors**; emphasis shifts if normalizers change.
- Claims should be frozen against a specific figure generation commit and `des_dpMass` target.

## X. Conclusion

The original proposal framed a **testable**, **quantifiable** course project: connect **sole design** to **impact and metabolic proxies** using a hopper surrogate, with room to grow toward **high-dimensional search** (e.g., “smart insole” ideas). The **present repository** realizes a substantial subset: **reproducible sweeps**, **BO on nonlinear soles**, **protocol-aware** fixed vs free-height comparisons, and a **documented** interpretation of **`mean_Pmet`** under matched peak height.

Remaining packaging items: optional **BO convergence** figures; one **primary** `des_dpMass` in the main text; frozen normalizers and provenance per figure.

## Acknowledgment

Thanks to course office hours for feedback on mass, activation bounds, and control assumptions.

## References

[1] M. Oleson, D. Adler, and P. Goldsmith, “A comparison of forefoot stiffness in running and running shoe bending stiffness,” *Journal of Biomechanics*, vol. 38, no. 9, pp. 1886–1894, 2005.

[2] K. A. McDonald et al., “Adding a toe joint to a prosthesis: walking biomechanics, energetics, and preference of individuals with unilateral below-knee limb loss,” *Scientific Reports*, vol. 11, no. 1, p. 1924, 2021.

[3] L. Zanetti and M. Brennan, “A new approach to modelling the ground reaction force from a runner,” *Journal of Biomechanics*, vol. 127, p. 110639, 2021.

[4] C. T. Farley and D. P. Ferris, “Biomechanics of walking and running: Center of mass movements to muscle action,” *Exercise and Sport Sciences Reviews*, vol. 26, no. 1, pp. 253–286, 1998.

[5] D. A. Heiderscheit et al., “Measurements of vertical displacement in running, a methodological comparison,” *Gait & Posture*, 2009. [PubMed](https://pubmed.ncbi.nlm.nih.gov/19356933/)

[6] M. Sanno et al., “The use of a single sacral marker method to approximate the centre of mass trajectory during treadmill running,” *Journal of Biomechanics*, 2021. [ScienceDirect](https://www.sciencedirect.com/science/article/abs/pii/S0021929020303092)

[7] G. Cappellini et al., “Motor patterns in human walking and running,” *Journal of Neurophysiology*, 2006. [JNP](https://journals.physiology.org/doi/full/10.1152/jn.00081.2006)

[8] T. F. Novacheck, “The biomechanics of running,” *Gait & Posture*, 1998. [PubMed](https://pubmed.ncbi.nlm.nih.gov/10200376/)

[9] A. Hasaneini et al., “Elastic energy savings and active energy cost in a simple model of running,” *PLOS Computational Biology*, 2021. [PLOS](https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1009608)

[10] C. J. Arellano and R. Kram, “Partitioning the metabolic cost of human running: a task-by-task approach,” *Integrative and Comparative Biology*, 2014. [PMC](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4296200/)

## Appendix: Submission Checklist

- Final author block and any instructor-required formatting.
- Replace qualitative phrases with **numbers** from **FINDINGS_AND_NEXT_STEPS.md** where appropriate.
- Each figure: model variant, `des_dpMass` / amplitude protocol, script path; curated files under **`DataForReport/figures/`**.
- BO: evaluation count, constraints; note any height mismatch between BO training and sweep.
- Optional: BO convergence exports from **`bayesian_optimization_spline.m`**.
- Match reference style to venue/instructor template.

# Report Drafting Notes

Working notes for later report writing.  
Focus: simulation/modeling outcomes from the wearable insole pipeline.

## Scope Notes

- No demographics or participant subgroup analyses are included.
- Emphasis is on model behavior, optimization outcomes, and baseline-vs-designed comparisons.
- Keep all figures reproducible from scripts in `MatlabCode/` when possible.

## Proposal-Aligned Storyline (Working)

- Baseline model establishes reference performance.
- Parameterized sole models explore stiffness/damping/nonlinear profile effects.
- Fixed-height comparisons isolate performance tradeoffs at matched task demand.
- Bayesian optimization finds spline profile candidates minimizing selected objectives.

## High-Priority Figures to Prepare

1. **System/Pipeline Overview Diagram**
   - Flow: parameter definition -> simulation (`FullHopper_*`) -> objective extraction -> optimization/sweep outputs.
   - Why useful: anchors methodology section quickly.

2. **Baseline vs Optimized Force-Displacement Curves**
   - Plot force vs displacement for representative candidates (GRF-optimal, Pmet-optimal, normalized objective).
   - Why useful: directly visualizes the mechanical design differences the optimizer found.

3. **2D Sweep Heatmaps (Stiffness x Max Compression)**
   - Metrics: `max_GRF`, `mean_Pmet`, and optionally `max_dpMass`.
   - Why useful: shows landscape structure and feasible/improving regions.

4. **Fixed-Height Comparison Plot**
   - Compare objectives at matched target `max_dpMass` (for example 0.04 m and/or 0.06 m).
   - Why useful: supports fair comparison by controlling jump-height demand.

5. **Pareto-Style Tradeoff Figure**
   - Scatter of `max_GRF` vs `mean_Pmet` for sweep points and BO best points.
   - Why useful: makes tradeoff between impact mitigation and energetic proxy explicit.

6. **BO Progress / Convergence Plot**
   - Objective value vs evaluation number for each BO run (`GRF`, `Pmet`, `Normalized`).
   - Why useful: demonstrates optimizer behavior and whether 30 evaluations were sufficient.

## Secondary Figures (If Space Allows)

- **Constraint Feasibility Map**: feasible vs infeasible regions under endpoint and overall stiffness constraints.
- **Amplitude-at-Solution Distribution**: `amplitude_res` values used to meet fixed-height targets across sweeps.
- **Cycle-Level Metric Stability Check**: show that last-3-cycle averaging is stable for chosen cases.
- **Sensitivity Tornado/Bar Plot**: local effect of control points (`x2..x4`, `F2..F4`) on objectives near best solution.

## Suggested Tables

- **Table A: Model Variants**
  - `FullHopper_baseline`, `FullHopper_k`, `FullHopper_kb`, `FullHopper_kb_splines` and what each changes.

- **Table B: Objective Definitions**
  - `max_GRF`, `mean_Pmet`, `max_dpMass`, and normalized objective formula.

- **Table C: Best Candidates Summary**
  - Best parameters and outcomes for each BO objective mode.

## Figure Captions - Must Include

- Which model variant is used.
- Whether amplitude is fixed or searched (`[low, high]` and target `des_max_dpMass`).
- Objective definition and units.
- Data source script and generation date.

## Literature Context Notes (for framing, not demographics)

- Running COM vertical oscillation is often reported around roughly 6-10 cm (method dependent), which can help frame fixed-height targets in simulation.
- Candidate citations for report intro/discussion:
  - Heiderscheit et al. (2009), *Gait & Posture*: methodological comparison of vertical displacement in running.
  - Sanno et al. (2021), *Journal of Biomechanics*: sacral marker approximation of COM trajectory during treadmill running.

## To-Do for Asset Curation

- Export final figure set into `DataForReport/figures/` (create folder when ready).
- Save compact processed CSV/MAT sources for each final plot.
- Add a short provenance note per figure (script, commit/date, parameters).

## Progress + Office-Hours Notes (May 2026)

- Model hopping behavior: done.
- Added damping to smooth `dp_sub`: done.
- Implemented spline force-displacement profile: done.
- Current constraint from office hours: single-leg case should use original model mass (`35 kg`), not `70 kg`.
- Activation in `[0, 1]` is the tuning parameter; current guidance is pulse width near `10%`.

### Why the model may fail at 70 kg (single-leg)

Working interpretation for report discussion:

- In this model family, increasing mass raises required support impulse and positive work per hop.
- If activation is bounded to `[0,1]` and pulse width is fixed/narrow, the actuator can hit a force-time (impulse) limit.
- When required impulse exceeds what the active element can generate in stance, hopping amplitude/height targets become infeasible or unstable.
- This is a model-capacity limitation, not necessarily a claim about human impossibility.

Potential quantitative check to add later:

- Compare successful `35 kg` and failed `70 kg` runs using peak force, stance-time impulse, and achieved `max_dpMass`.
- If available, log whether activation saturates at `1` for substantial portions of stance.

### Pulse-width context for report framing

Use cautious language: "pulse width" in this model is a control parameter, not a direct one-to-one biological measurement. Still, gait timing literature can justify plausible ranges.

- Walking commonly has stance occupying roughly around `60%` of gait cycle.
- Running has shorter stance and duty factor below `50%` (with flight phase), so narrower effective force-production windows are expected.
- Therefore, a `10%` pulse can be treated as a strict/short actuation assumption; exploring `20%` as a sensitivity case is defensible, especially when testing robustness at higher demand.

Candidate references:

- Cappellini et al., "Motor patterns in human walking and running," *Journal of Neurophysiology* (2006), [JNP](https://journals.physiology.org/doi/full/10.1152/jn.00081.2006).
- Novacheck, "The biomechanics of running," *Gait & Posture* (1998), [PubMed](https://pubmed.ncbi.nlm.nih.gov/10200376/).

## Clarified Deliverables Narrative (Simple vs Advanced Model)

### What are the "2 parameters" in the simple model?

In your current scripts, the simple sweep is over:

- `K_shoe` (effective sole stiffness),
- `thickness` (used as max compression scale in linear-sole cases).

This gives a 2D design map (colormap) for metrics like `max_GRF`, `mean_Pmet`, and `max_dpMass`.

### Why compare simple sweep with Bayesian optimization?

Simple terms:

- The 2D sweep is a "map" of all combinations on a coarse grid.
- BO is a "smart search" that should find low-value regions quickly.
- If BO's best point is near the minimum area seen on the colormap, that validates both methods and builds trust.

Technical/report terms:

- The 2-parameter grid provides global landscape intuition and baseline tradeoff structure.
- BO on the low-dimensional model is a validation step for optimizer setup (objective definition, constraints, reproducibility).
- After validation, move to spline model (`x2,x3,x4,F2,F3,F4` control points via deltas), where exhaustive gridding is impractical and BO is more appropriate.

### Real-world interpretation of this comparison

- Simple model: approximates high-level footwear tuning (how stiff and how much compression range).
- Spline model: approximates detailed nonlinear sole behavior shaping through the compression cycle.
- If advanced BO improves objectives beyond the simple-model frontier, it suggests value in engineered nonlinear profiles beyond "just pick one stiffness/thickness."

## Note on Fixed-Height Observation: Lower Height but Higher `Pmet`

Teammate observation to preserve:

- "When prescribing baseline jump height, metabolic rate can increase; contours may not change much between prescribed-height and non-prescribed-height cases."

Possible explanation to include (as a hypothesis, not final claim):

- At fixed target height, the controller/search may choose amplitudes that alter muscle operating conditions (timing, shortening velocity, and force-rate demands), not just total COM excursion.
- Energetic cost can remain high or rise when force must be produced in less favorable contractile regimes, even if kinematic height is reduced.
- In spring-mass style running/hopping analyses, metabolic cost is strongly tied to active work and force-generation demands, not solely COM displacement magnitude.

Supporting context references:

- Hasaneini et al., "Elastic energy savings and active energy cost in a simple model of running," *PLOS Computational Biology* (2021), [PLOS](https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1009608).
- Arellano and Kram, "Partitioning the metabolic cost of human running: a task-by-task approach," *Integrative and Comparative Biology* (2014), [PMC](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4296200/).

Follow-up analysis task to firm this up:

- For matched-height runs, plot `Pmet` against `amplitude_res`, peak force, and (if available) muscle velocity proxies to test whether velocity/force-rate shifts explain the increase.

### Implemented: fixed-height `Pmet` correlation script (MatlabCode)

**What was added**

- [`plot_fixed_height_Pmet_analysis.m`](../MatlabCode/plot_fixed_height_Pmet_analysis.m) — main script. Loads `generated_data/<model_name>/height_<des_dp_Mass>_objectives.mat` (target `des_dp_Mass` comes from [`load_params.m`](../MatlabCode/helpers/load_params.m)) and plots `mean_Pmet` vs `amplitude_res`, vs `max_GRF` (peak-force metric from the objectives file), plus a histogram of achieved `max_dp_Mass` vs the prescribed target.
- [`analyze_sole_output_extended.m`](../MatlabCode/helpers/analyze_sole_output_extended.m) — optional re-run path: adds kinematic proxies from logged `dp_Mass` and `GRF` (max \|d(`dp_Mass`)/dt\|, max \|d(`GRF`)/dt\| over the last three hop cycles) and can average a user-named logged Simulink signal over the last cycle if present on `simOut`.
- [`straight_spline_tables_from_kb.m`](../MatlabCode/helpers/straight_spline_tables_from_kb.m) — rebuilds straight monotone spline force/disp tables from `K_shoe` and `thickness` so re-simulation matches [`gen_sweep_data`](../MatlabCode/helpers/gen_sweep_data.m) when `param_combinations` in the `.mat` file are linear only (as saved for `FullHopper_kb_splines`).

**How to use it**

1. Set MATLAB current folder to **`MatlabCode/`**.
2. Ensure fixed-height sweep output exists: run `gen_sweep_data(model_name, true, use_curve)` (or your walkthrough) so `height_<des_dp_Mass>_objectives.mat` is present under `generated_data/<model_name>/`.
3. Run `plot_fixed_height_Pmet_analysis` (default **`cfg.rerun_sim = false`**) for fast plots from the saved `out` matrix only (`max_GRF`, `max_dpMass`, `mean_Pmet`, `amplitude_res`).
4. For derivative / muscle-signal panels: edit the **CONFIG** block at the top of `plot_fixed_height_Pmet_analysis.m` — set **`cfg.rerun_sim = true`**, optionally **`cfg.max_rerun_points`** (e.g. `50` or `inf`), and **`cfg.muscle_signal_name`** to a variable name actually logged to `simOut` (leave `''` if unknown; COM and GRF-rate proxies still plot).
5. Optional: set **`cfg.export_figures = true`** to write PNGs under `MatlabCode/generated_data/figures/`.

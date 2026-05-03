# Report Drafting Notes

Working notes for later report writing.  
Focus: simulation/modeling outcomes from the wearable insole pipeline.

## Scope Notes

- No demographics or participant subgroup analyses are included.
- Emphasis is on model behavior, optimization outcomes, and baseline-vs-designed comparisons.
- Keep all figures reproducible from scripts in `MatlabCode/` when possible.
- **`MatlabCode/generated_data/`** is **gitignored**; pointers to files there describe **local outputs after runs**, not guaranteed repo contents. Curated figures for writeups: **`DataForReport/figures/`**.

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
  - **Report asset:** `[figures/fig_force_displacement_BO_splines_vs_linear_reference.png](figures/fig_force_displacement_BO_splines_vs_linear_reference.png)` — **F–Δx comparison:** dashed lines = linear reference soles (min/max `K_shoe` and `thickness` from `[load_params.m](../MatlabCode/helpers/load_params.m)`); solid lines = BO optima (`optimal_spline_*.mat`) for **GRF**, **Pmet**, and **Normalized** objectives. Regenerate via `[plot_BO_spline_profiles_comparison.m](../MatlabCode/plot_BO_spline_profiles_comparison.m)` → `generated_data/figures/BO_splines_vs_linear_force_displacement.png` (same content; curated copy here for the report).
  - **Caption (paste/adapt):** *Sole force vs compression: Bayesian-optimized spline profiles (minimize peak GRF, minimize mean metabolic proxy, normalized combined objective) compared to linear reference curves at the sweep grid corners. Optimizer setup: `[bayesian_optimization_spline.m](../MatlabCode/bayesian_optimization_spline.m)`.*
3. **2D Sweep Heatmaps (Stiffness x Max Compression)**
  - Metrics: `max_GRF`, `mean_Pmet`, and optionally `max_dpMass`.
  - Why useful: shows landscape structure and feasible/improving regions.
4. **Fixed-Height Comparison Plot**
  - Compare objectives at matched target `max_dpMass` (for example 0.04 m and/or 0.06 m).
  - Why useful: supports fair comparison by controlling jump-height demand.
  - **Status (repo):** **Matched-height-only figures:** `[plot_fixed_height_Pmet_analysis.m](../MatlabCode/plot_fixed_height_Pmet_analysis.m)` + `generated_data/<model_name>/height_<des_dp_Mass>_objectives.mat` from `[gen_sweep_data.m](../MatlabCode/helpers/gen_sweep_data.m)` (`is_fixed_height = true`); see `[FINDINGS_AND_NEXT_STEPS.md](figures/heightPmetAnalysisFigures/FINDINGS_AND_NEXT_STEPS.md)`. `**des_dp_Mass`** from `[load_params.m](../MatlabCode/helpers/load_params.m)` (currently **0.06 m**; **0.04 m** after changing `des_dp_Mass` and regenerating). **Fixed vs free-height overlay:** run `[compare_fixed_vs_free_height_plots.m](../MatlabCode/compare_fixed_vs_free_height_plots.m)` after both sweeps exist (`gen_sweep_data(..., false, ...)` for `k_*_maxcomp_*.mat`, and `..., true, ...` for `height_*_objectives.mat`). Outputs under `MatlabCode/generated_data/figures/fixed_vs_free_height/` (copies often kept in `[figures/fixed_vs_free_height/](figures/fixed_vs_free_height/)`) plus optional `free_height_objectives_cache.mat`.
  - **Report (brief):** Same stiffness–thickness grid; **fixed height** = search stimulation to hit target peak COM lift; **free height** = fixed stimulation, floating peak lift. Overlay figures separate **task constraint** from **sole tradeoffs**; cite `f1`/`f2` for protocol difference, `f4` for paired Δ`Pmet`. Details: FINDINGS section *Fixed vs free height*.
  - **Several targets (e.g. 0.04 m, 0.06 m, reference height):** Regenerate only `**height_<des>_objectives.mat`** per target (`load_params` → `gen_sweep_data(..., true, ...)`); **reuse** the same free-height `k_*_maxcomp_*.mat` set. Run `**compare_fixed_vs_free_height_plots`** each time (filenames can include the target, e.g. `fixed0.04_vs_free_*`). In the report: feature **one** target in the main text; use others for sensitivity or supplement. **f2** / **f4** strip well as a row of panels; keep captions identical except peak-COM target. Free-height points are common across targets — only the fixed-height cloud and reference line move.
5. **Pareto-Style Tradeoff Figure**
  - Scatter of `max_GRF` vs `mean_Pmet` for sweep points and BO best points.
  - Why useful: makes tradeoff between impact mitigation and energetic proxy explicit.
  - **Generate:** `[plot_pareto_GRF_Pmet.m](../MatlabCode/plot_pareto_GRF_Pmet.m)` — loads `height_<des>_objectives.mat`, re-evaluates each `optimal_spline_*.mat` at `**des_dp_Mass`** from `[load_params.m](../MatlabCode/helpers/load_params.m)` so BO points match the sweep task height.
  - **Status (generated):** Working export for spline model: `[MatlabCode/generated_data/figures/pareto_GRF_vs_meanPmet_FullHopper_kb_splines.png](../MatlabCode/generated_data/figures/pareto_GRF_vs_meanPmet_FullHopper_kb_splines.png)`. Curated mirror (same script, `cfg.export_png_to_data_for_report`): `[figures/fig_pareto_GRF_vs_meanPmet.png](figures/fig_pareto_GRF_vs_meanPmet.png)` if present. Figure title/subtitle encodes `**des_dp_Mass`** used when the script ran — repeat for other targets after regenerating `height_<des>_objectives.mat` and rerunning.
  - **Read for text:** Gray sweep shows multi-branch structure in objective space; BO markers sit **left/inside** much of the sweep cloud — spline optimization explores shapes **outside** the straight-table `(K_shoe, thickness)` grid. Not a formal Pareto front (only three BO points); phrase as **tradeoff scatter** or **objective-space comparison** if reviewers are strict.
  - **Caption (paste/adapt):** *Peak ground-reaction force vs mean metabolic proxy for the fixed-height stiffness–thickness sweep (gray, n = grid size) and Bayesian-optimized spline soles (filled markers: GRF-, Pmet-, and normalized-objective optima). Task height matches `des_dp_Mass` in `load_params` at generation time.*
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

- Keep `DataForReport/figures/` in sync with stable MATLAB exports (regenerate, then copy PNG/CSV as needed).
- Optional: per-figure provenance line (script + parameters).

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

### Clearer explanation (single narrative you can paste)

**Why prescribing the baseline jump height can *increase* `Pmet`**

You are no longer letting the hop settle wherever the shoe + fixed drive naturally go. You are **adding a constraint**: “hit this peak COM height.” In our pipeline that means **searching stimulation** (`amplitude`) until height matches. For many parameter sets that **raises drive** compared to an easier, lower hop — and in the matched-height sweep, `**mean_Pmet` rises strongly with the resolved stimulation** (`amplitude_res`). So “prescribe baseline height” often means **more demanding control**, not just a different label on the same motion.

**Why `Pmet` contours can look *similar* prescribed vs not**

The two cases are usually **not the same experiment**. Unprescribed-height sweeps often use **fixed** stimulation while **height floats** with the sole. Prescribed-height runs **adjust** stimulation to lock height. The **landscape in (stiffness, thickness)** can look alike in a contour plot (similar color ranges, same model, overlapping operating points) even though **how each point was produced** (floating height vs fixed height + search) differs. Interpreting “contours don’t change” as “prescribing height doesn’t matter” is easy to over-read — it can mean **the map is shallow in that slice**, or **the plot scales hide shifts**, or **the protocols shouldn’t be compared pointwise without matching height *or* matching drive**.

**Muscle velocities — now less hand-wavy**

The fixed-height re-analysis adds **kinematic and muscle-velocity proxies** (e.g. mean `m_FV`, force-rate and COM-acceleration rates). They **track `mean_Pmet` about as strongly as `amplitude_res`** on the iso-height grid (FINDINGS Table 3). That supports the Figma intuition: **metabolic proxy moves with how “hard / snappy” the muscle-side dynamics are**, not with tiny residual differences in peak height once height is matched.

**One sentence for a slide**

Prescribing jump height **forces a different stimulation and motion history**; in this model **cost follows that history** (drive + dynamics / muscle velocity proxy) **more than** it follows small peak-height wiggle — and **contour similarity** between prescribed vs unprescribed cases needs a **protocol-aware** read, not a literal “no effect.”

---

Narrow explanation to include (simulation-supported + one literature bridge):

1. **Separate two readings of the observation.**
  - *Same narrative family:* prescribing how high the hop must be **changes the control problem** (here: binary search on stimulation `amplitude` in `[0.8, 1]` to hit `des_dpMass`). That is **not** the same comparison as an unconstrained sweep with **fixed** `amplitude = 1`, where peak height **floats** with the shoe. “Similar `Pmet` / similar contours” across those two protocols can happen without contradicting a height effect — the **tasks differ**.  
  - *Literal “lower height but higher `Pmet`”:* in general that can occur if **smaller COM excursion** is achieved with **worse** muscle timing, velocity, or force-rate demands; our **iso-height** grid does not test “lower target height” directly — it tests **matched** height (~0.06 m).
2. **What the fixed-height sweep adds (tight wording for the report).**
  With peak COM displacement held to ~0.06 m (mean absolute error ~0.38 mm; worst ~±1 mm), `**mean_Pmet` still spans ~160–191 W/kg** across shoes (FINDINGS Table 1). So **height is not the knob explaining that spread** on this dataset. `**Pmet` co-varies strongly with the resolved stimulation `amplitude_res`** and with **kinematic/muscle proxies** (max d(`dp_Mass`)/dt, max d(`GRF`)/dt, mean `m_FV`; FINDINGS Table 3). **Plain language:** hitting the same jump height can still require **more drive** and **sharper** dynamics for some soles — the model’s metabolic proxy tracks that bundle, not millimeter height residuals.
3. **Peak GRF is a weak one-dimensional story.**
  `max_GRF` vs `mean_Pmet` is **moderately negative** in Pearson terms but **more negative** in Spearman (FINDINGS Table 3), consistent with **nonlinear** structure — do not claim “lower impact force ⇒ lower metabolism” without qualification.
4. **One-sentence hypothesis line (optional in Discussion).**
  Prescribing jump height **reshapes feasible stimulation and force–time trajectories**; in this model, **metabolic cost tracks those trajectories** (drive + transients + muscle velocity proxy) **more than** it tracks small changes in achieved peak height.

Supporting context references (mechanism framing, not duplicate evidence):

- Hasaneini et al., "Elastic energy savings and active energy cost in a simple model of running," *PLOS Computational Biology* (2021), [PLOS](https://journals.plos.org/ploscompbiol/article?id=10.1371/journal.pcbi.1009608).
- Arellano and Kram, "Partitioning the metabolic cost of human running: a task-by-task approach," *Integrative and Comparative Biology* (2014), [PMC](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4296200/).

Follow-up (implemented): matched-height `Pmet` vs `amplitude_res`, peak force, and muscle/kin proxies — see `[FINDINGS_AND_NEXT_STEPS.md](figures/heightPmetAnalysisFigures/FINDINGS_AND_NEXT_STEPS.md)`.

### Implemented: fixed-height `Pmet` correlation script (MatlabCode)

**What was added**

- `[plot_fixed_height_Pmet_analysis.m](../MatlabCode/plot_fixed_height_Pmet_analysis.m)` — main script. Loads `generated_data/<model_name>/height_<des_dp_Mass>_objectives.mat` (target `des_dp_Mass` comes from `[load_params.m](../MatlabCode/helpers/load_params.m)`) and plots `mean_Pmet` vs `amplitude_res`, vs `max_GRF` (peak-force metric from the objectives file), plus a histogram of achieved `max_dp_Mass` vs the prescribed target.
- `[analyze_sole_output_extended.m](../MatlabCode/helpers/analyze_sole_output_extended.m)` — optional re-run path: adds kinematic proxies from logged `dp_Mass` and `GRF` (max d(`dp_Mass`)/dt, max d(`GRF`)/dt over the last three hop cycles) and can average a user-named logged Simulink signal over the last cycle if present on `simOut`.
- `[straight_spline_tables_from_kb.m](../MatlabCode/helpers/straight_spline_tables_from_kb.m)` — rebuilds straight monotone spline force/disp tables from `K_shoe` and `thickness` so re-simulation matches `[gen_sweep_data](../MatlabCode/helpers/gen_sweep_data.m)` when `param_combinations` in the `.mat` file are linear only (as saved for `FullHopper_kb_splines`).

**How to use it**

1. Set MATLAB current folder to `**MatlabCode/`**.
2. Ensure fixed-height sweep output exists: run `gen_sweep_data(model_name, true, use_curve)` (or your walkthrough) so `height_<des_dp_Mass>_objectives.mat` is present under `generated_data/<model_name>/`.
3. Run `plot_fixed_height_Pmet_analysis` (default `**cfg.rerun_sim = false**`) for fast plots from the saved `out` matrix only (`max_GRF`, `max_dpMass`, `mean_Pmet`, `amplitude_res`).
4. For derivative / muscle-signal panels: edit the **CONFIG** block at the top of `plot_fixed_height_Pmet_analysis.m` — set `**cfg.rerun_sim = true`**, optionally `**cfg.max_rerun_points**` (e.g. `50` or `inf`), and `**cfg.muscle_signal_name**` to a variable name actually logged to `simOut` (leave `''` if unknown; COM and GRF-rate proxies still plot).
5. Optional: set `**cfg.export_figures = true**` to write PNGs under `MatlabCode/generated_data/figures/`.

### How this supports the report

See `**[figures/heightPmetAnalysisFigures/FINDINGS_AND_NEXT_STEPS.md](figures/heightPmetAnalysisFigures/FINDINGS_AND_NEXT_STEPS.md)**` for tables and evidence-backed claims. **Methods:** amplitude search and targets. **Results:** Tables 1–3 and `f1`–`f3`. **Discussion:** `Pmet` tracks drive and dynamics under matched height; contrast fixed-height vs free-height protocols; cite associations, not causality.
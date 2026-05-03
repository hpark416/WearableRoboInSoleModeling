# Fixed-height Pmet analysis — findings

**Script:** `MatlabCode/plot_fixed_height_Pmet_analysis.m` · **Models:** `FullHopper_kb`, `FullHopper_kb_splines` · **Grid:** n = 135 (`K_shoe` × `thickness`)

**Sweep:** Straight monotone F–Δx tables from each `(K_shoe, thickness)` → **`kb`** and **`kb_splines`** match numerically (sanity check only). Nonlinear shape comparisons need BO or non-straight splines.

**Figures `f1`–`f3`:** Each point = one grid combo after amplitude search hit **`des_dpMass`** from `load_params` (example stats below used **`height_0.06_objectives.mat`**). **`f1`:** `Pmet` vs `amplitude_res`, vs `max_GRF`, colored third variable — strong `Pmet`–`amplitude_res` trend; **`max_GRF` vs `Pmet`** not a simple line. **`f2`:** achieved `max_dpMass` histogram vs target. **`f3`:** (needs `rerun_sim`) kin/muscle proxies vs `Pmet`.

---

## Tables (iso-height sweep, extended rerun)

Source columns: `[max_GRF, max_dpMass, mean_Pmet, amplitude_res]`; Table 3 outcome = `mean_Pmet`. Values below for **0.06 m** target (`kb` ≡ `kb_splines` here).

### Table 1 — Distribution

| Quantity | Min | 25th | Median | 75th | Max | Unit |
|----------|-----|------|--------|------|-----|------|
| `mean_Pmet` | 159.91 | 165.30 | 168.69 | 173.91 | 190.83 | W/kg |
| `max_GRF` | 1135.59 | 1247.88 | 1308.34 | 1343.04 | 1362.86 | N |
| `amplitude_res` | 0.9125 | 0.9188 | 0.9375 | 0.9563 | 1.000 | — |
| `max_dpMass` | 0.05904 | 0.05963 | 0.05999 | 0.06034 | 0.06099 | m |

### Table 2 — Height error vs 0.06 m target

Mean |error| ≈ **0.38 mm**; worst ≈ **±1 mm**.

### Table 3 — Correlations with `mean_Pmet` (n = 135)

| Predictor | r (Pearson) | ρ (Spearman) |
|-----------|-------------|----------------|
| `amplitude_res` | 0.887 | 0.884 |
| `max_GRF` | −0.428 | −0.651 |
| `max_abs_ddpdt` | 0.912 | 0.905 |
| `max_abs_dGRFdt` | 0.897 | 0.886 |
| `muscle_mean_abs` (`m_FV`) | 0.896 | 0.895 |

Associations only. **`max_GRF` vs `Pmet`** is nonlinear (Spearman ≫ Pearson in magnitude).

---

## Takeaways

1. Height is matched tightly — **`Pmet` spread is not explained by height** on this grid.
2. **`Pmet`** tracks **`amplitude_res`** and dynamic/muscle proxies — cost follows **how** the hop is produced.
3. Report **`kb` vs straight-table splines`** here as implementation validation, not nonlinear sole physics.

**Plain language:** Prescribing peak COM fixes one output; metabolic proxy still varies with drive and dynamics. For teammate context on prescribed vs free protocols, see **`compare_fixed_vs_free_height_plots`** outputs under [`../fixed_vs_free_height/`](../fixed_vs_free_height/).

---

## Next (report only if needed)

Repeat Table 1–3 for a **nonlinear sole** set (e.g. BO shapes only), not for duplicate straight-table sweeps.

# DataForReport

Curated assets for writeups: figures, draft markdown, and short notes. Full simulation outputs are written to **`MatlabCode/generated_data/`** when you run MATLAB locally — that folder is **gitignored** and will not appear in a fresh clone until you regenerate sweeps and figures.

## Figures (`figures/`)

| Location | Contents |
|----------|----------|
| **Root** | `draft_system_pipeline_overview.svg`, `fig_force_displacement_BO_splines_vs_linear_reference.png`, `fig_pareto_GRF_vs_meanPmet.png` |
| **`heightPmetAnalysisFigures/`** | Fixed-height `Pmet` analysis PNGs, stats CSVs, canonical **`FINDINGS_AND_NEXT_STEPS.md`** |
| **`fixed_vs_free_height/`** | Fixed vs free-height comparison PNGs (`compare_fixed_vs_free_height_plots.m`) |

## Docs in this folder

- **`REPORT_DRAFTING_NOTES.md`** — figure checklist and narrative bullets  
- **`FIGURE_GENERATION_CHECKLIST.md`** — script → output mapping  
- **`DRAFT_REPORT_CURRENT.md`**, **`DRAFT_REPORT_IEEE_STYLE.md`** — drafts  

Regenerate figures from **`MatlabCode/`** (see checklist); copy finals here when stable.

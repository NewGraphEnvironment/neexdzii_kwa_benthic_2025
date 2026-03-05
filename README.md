# Neexdzii Kwa Benthic 2025

Benthic invertebrate community assessment for the Neexdzii Kwa (Upper Bulkley River), 2025 field season. Prepared for the Office of the Wet'suwet'en.

**Report:** [www.newgraphenvironment.com/neexdzii_kwa_benthic_2025](https://www.newgraphenvironment.com/neexdzii_kwa_benthic_2025/)

Three mainstem sites were sampled in triplicate using the CABIN wadeable streams protocol. Samples were processed by Cordillera Consulting Inc. (Summerland, BC). This report presents the full community composition analysis, diversity metrics, ordination, and indicator species results. Key findings are summarized in the companion [Wedzin Kwa Restoration Planning Report](https://github.com/NewGraphEnvironment/restoration_wedzin_kwa_2024).

All data pipelines are scripted from raw source to final output. Processed datasets are version-controlled so the report can be rebuilt without re-downloading sources. Methodological decisions and planned work are tracked as [GitHub Issues](https://github.com/NewGraphEnvironment/neexdzii_kwa_benthic_2025/issues). See [NEWS.md](NEWS.md) for the version history.

## Getting Started

### Prerequisites

- [Git](https://git-scm.com/)
- [R](https://cran.r-project.org/) (>= 4.4)
- [RStudio](https://posit.co/download/rstudio-desktop/) (recommended)
- SSH tunnel to newgraph DB on port 63333 — only required to refresh spatial data; the report builds from files in this repository

### First-time setup

```bash
git clone https://github.com/NewGraphEnvironment/neexdzii_kwa_benthic_2025.git
```

1. Open the `.Rproj` file in RStudio
2. Set `update_packages: TRUE` in `index.Rmd` params for first-time package installation, then build

### Build the report

```r
source('scripts/run.R')
```

### Update data from sources

Edit params in `index.Rmd` to re-run individual pipelines:

```yaml
params:
  update_ems: TRUE           # EMS water quality data (rems API + plots)
  update_benthic: TRUE       # Cordillera Excel parsing + taxonomy + metrics
```

Then `source('scripts/run.R')`. Set params back to `FALSE` for subsequent builds. Each param triggers its prep script at the start of the relevant chapter.

**Note on `update_ems`:** Re-running pulls fresh data from the BC EMS historic database via the `rems` R package, regenerates filtered CSVs, and rebuilds all EMS plots including the ammonia guideline evaluation. The intermediate `ems_raw.csv` (~50 MB) is gitignored; filtered CSVs in `data/processed/` provide standalone reproducibility.

## Data Pipeline

```
Cordillera Excel workbook (email)
  ↓ manual save
data/raw/cordillera_*.xlsx
  ↓ scripts/prep_benthic.R (update_benthic)
data/processed/benthic_*.csv (analysis-ready)
  ↓ Rmd chapters
Report output (docs/)

BC EMS historic database (rems API)
  ↓ scripts/ems_prep.R (update_ems)
data/processed/ems_*.csv (filtered by watershed)
  ↓ scripts/plot_ems.R (update_ems)
fig/ems/*.png (time series, boxplots, guideline evaluation)
  ↓ 0850-appendix-ems.Rmd
Report output (docs/)
```

## Repository Structure

```
index.Rmd                 # Master config, YAML params, setup
0100-intro.Rmd            # Introduction
0200-background.Rmd       # Watershed context, land use, water quality
0300-methods.Rmd          # Sampling, lab processing, analysis
0400-results.Rmd          # Community composition, diversity
0500-results-ordination.Rmd  # NMDS, indicator species, PERMANOVA
0600-discussion.Rmd       # Discussion and recommendations
0850-appendix-ems.Rmd     # Historical water quality (EMS)

scripts/
  run.R                   # Build script
  setup.R                 # Shared paths and parameters
  packages.R              # Package management
  functions.R             # Project-specific helper functions
  ems_prep.R              # EMS data download and filtering
  plot_ems.R              # EMS plotting with WQG reference lines
  map_ems-stations.R      # EMS station map (static)
  data_map-study-area.R   # Spatial data caching (requires DB)

data/
  raw/                    # Cordillera Excel workbook(s)
  processed/              # Analysis-ready datasets
  spatial/                # Cached spatial layers (gitignored)

fig/
  ems/                    # EMS water quality plots

NEWS.md                   # Version history and change log
```

## Issues and Planned Work

Active issues are tracked at [github.com/NewGraphEnvironment/neexdzii_kwa_benthic_2025/issues](https://github.com/NewGraphEnvironment/neexdzii_kwa_benthic_2025/issues).

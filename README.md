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

## Data Pipeline

```
Email (Cordillera Excel workbook)
  ↓ manual save
data/raw/cordillera_*.xlsx
  ↓ scripts/prep_benthic.R
data/processed/benthic_counts_tidy.csv
data/processed/benthic_metrics.csv
  ↓ Rmd chapters
Report output (docs/)
```

## Repository Structure

```
index.Rmd                 # Master config, YAML params, setup
0100-intro.Rmd            # Introduction
0200-background.Rmd       # Watershed context, CABIN protocol
0300-methods.Rmd          # Sampling, lab processing, analysis
0400-results.Rmd          # Community composition, diversity
0500-results-ordination.Rmd  # NMDS, indicator species, PERMANOVA
0600-discussion.Rmd       # Discussion and recommendations

scripts/
  run.R                   # Build script
  setup.R                 # Shared paths and parameters
  packages.R              # Package management
  functions.R             # Project-specific helper functions

data/
  raw/                    # Cordillera Excel workbook(s)
  processed/              # Analysis-ready datasets

NEWS.md                   # Version history and change log
```

## Issues and Planned Work

Active issues are tracked at [github.com/NewGraphEnvironment/neexdzii_kwa_benthic_2025/issues](https://github.com/NewGraphEnvironment/neexdzii_kwa_benthic_2025/issues).

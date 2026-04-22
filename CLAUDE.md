# Neexdzii Kwa Benthic 2025

## Company Vision

**New Graph Environment** - With integrity, using sound science and open communication, we build productive relationships between First Nations, regulators, non-profits, proponents, scientists, and stewardship groups. Our value-added deliverables include open-source, collaborative GIS environments and interactive online reporting.

We are biologists and computer programmers that facilitate aquatic ecosystem restoration with an emphasis on inclusive engagement and knowledge sharing.

## Project Overview

Standalone benthic invertebrate community assessment for the Neexdzii Kwa (Upper Bulkley River), 2025 field season. Companion report to `restoration_wedzin_kwa_2024` — the restoration planning report will cite this for detailed benthic analysis and summarize key findings.

**Client:** Wet'suwet'en Treaty Society

**Lab:** Cordillera Consulting Inc. (Summerland, BC) — subsampling and taxonomic identification from kick-net samples.

**Sampling design:** Three mainstem sites, triplicate kick-net samples per site, CABIN wadeable streams protocol.

## Repository Relationships

| Repo | Relationship |
|------|--------------|
| `mybookdown-template` | Upstream bookdown template |
| `restoration_wedzin_kwa_2024` | Parent restoration report — cites this for benthic findings |
| `Sheep` | Reference: Cordillera Excel parsing, taxonomy resolution, vegan community analysis |
| `sred-2025-2026` | SRED tracking — cross-reference issues |

## SRED Tracking

R&D activities tracked in `sred-2025-2026` repository (PRIVATE).

**Cross-Linking:**
```
Relates to NewGraphEnvironment/sred-2025-2026#<issue>
Relates to NewGraphEnvironment/neexdzii_kwa_benthic_2025#<issue>
```

## Planning Files Management

Complex tasks use planning-with-files (PWF) approach for R&D documentation:
- **Active work:** `planning/active/` — Current task_plan.md, findings.md, progress.md
- **Completed work:** `planning/archive/YYYY-MM-issue-N-description/` — Preserved for SRED claims and knowledge transfer
- **Workflow:** See `planning/README.md` for full details

## Report Structure

| File | Content |
|------|---------|
| `0100-intro.Rmd` | Introduction — study context, connection to restoration report |
| `0200-background.Rmd` | Background — watershed, CABIN protocol, previous work |
| `0300-methods.Rmd` | Methods — sampling design, lab processing, analysis approach |
| `0400-results.Rmd` | Results — community composition, diversity metrics, FFG, HBI |
| `0500-results-ordination.Rmd` | Results — NMDS, envfit, indicator species, PERMANOVA |
| `0600-discussion.Rmd` | Discussion and recommendations |
| `2000-references.Rmd` | Auto-generated bibliography |
| `2100-session-info.Rmd` | Reproducibility |

## Data Pipeline

Three-stage architecture:

```
Email (Cordillera Excel workbook)
  ↓ manual save
data/raw/cordillera_*.xlsx (version-controlled)
  ↓ scripts/prep_benthic.R
data/processed/benthic_counts_tidy.csv
data/processed/benthic_metrics.csv
  ↓ read by chapters
Report output
```

### CABIN Upload Pipeline

```
Field cards (manual transcription)
  ↓
data/processed/cabin/pebble_bul0X.csv (100 diameters per site)
  ↓ scripts/cabin_pebble.R (verify + generate PebbleCount strings)
data/processed/cabin/habitat.csv
data/processed/cabin/chemistry.csv
data/processed/cabin/visits.csv
  ↓ scripts/prep_cabin-upload.R
CABIN database upload
```

**Template guide:** `data/templates/templateGuide.xls` — authoritative for all valid field names, units, and alt value codes. Parameter names must match exactly (e.g. `XSEC- DepthStagnation` with space after dash).

**Prep script pattern:** Use STEP comments with trailing dashes for RStudio outline. Verification blocks with cat() output at each stage. See `nrp-nutrient-loading-2025/scripts/prep_fert.R` for canonical example.

## Key Technical Patterns

### Cordillera Excel Parsing

Reference: `Sheep/R/01b_load_invert.R`. Cordillera exports vary by year — expect pivot structures, transposed layouts, or flat "Subsample - Flat" sheets. Key patterns:
- Extract sheet-specific metadata (site, date, replicate)
- Adjust counts by percent_sampled where applicable
- Standardize taxonomy strings (strip rank prefixes, maturity labels, special chars)

### Taxonomy Resolution (taxize)

Resolution chain: `gnr_resolve()` → `tol_resolve()` → `get_ids()` → `classification()`. Known edge cases from Sheep:
- `Neoleptophlebia` → `Paraleptophlebia` (genus not in ITIS)
- `Oribatei` → `Oribatida`
- `Oligochaeta` → `Clitellata`
- Cf. names kept as-is when no alternative exists
- Runtime: ~15 min for `get_ids()` step

### FFG and Tolerance Values

Sources: SAFIT database (primary) and EPA Appendix B (Barbour et al.) for fallback. Fallback chain: SAFIT ffg → Barbour primary → Barbour secondary → Cordillera's original. Standardize abbreviations: GC→CG, FC→CF, PR→P.

### Community Analysis (vegan)

Reference: `Sheep/R/functions.R`. Key functions to adapt:
- `make_matrix()` — long → wide species matrix
- `metaMDS(k=3, trymax=999)` with fixed seed for reproducibility
- `envfit()` for environmental correlation
- `indicspecies::multipatt()` with IndVal.g
- `RVAideMemoire::pairwise.perm.manova()` for pairwise PERMANOVA
- `betadisper()` for multivariate dispersion

<\!-- BEGIN SOUL CONVENTIONS — DO NOT EDIT BELOW THIS LINE -->


# Bookdown Conventions

Standards for bookdown report projects across New Graph Environment.

## Template Repos

These are the canonical references. Child repos inherit their structure and patterns.

- [mybookdown-template](https://github.com/NewGraphEnvironment/mybookdown-template) — General-purpose bookdown starter
- [fish_passage_template_reporting](https://github.com/NewGraphEnvironment/fish_passage_template_reporting) — Fish passage reporting template

When in doubt, match what the template does. When the template and production repos disagree, production wins — update the template.

## Project Structure

```
project/
├── index.Rmd                # Master config, YAML params, setup chunks
├── _bookdown.yml            # book_filename, output_dir: "docs"
├── _output.yml              # Gitbook, pagedown, pdf_book config
├── 0100-intro.Rmd           # Chapter numbering: 4-digit, 100s increment
├── 0200-background.Rmd
├── 0300-methods.Rmd
├── 0400-results.Rmd
├── 0500-*.Rmd               # Discussion/recommendations
├── 0800-appendix-*.Rmd      # Appendices (site-specific in fish passage)
├── 2000-references.Rmd      # Auto-generated from .bib
├── 2090-report-change-log.Rmd  # Auto-generated from NEWS.md
├── 2100-session-info.Rmd    # Reproducibility
├── NEWS.md                  # Changelog (semantic versioning)
├── scripts/
│   ├── packages.R           # Package loading (renv-managed)
│   ├── functions.R          # Project-specific functions
│   ├── staticimports.R      # Auto-generated from staticimports pkg
│   ├── setup_docs.R         # Build helper
│   └── run.R                # Local build (gitbook + PDF)
├── fig/                     # Figures (organized by chapter or type)
├── data/                    # Project data
├── docs/                    # Rendered output (GitHub Pages)
├── renv.lock                # Locked dependencies
└── .Rprofile                # Activates renv
```

## Setup Chunk Pattern

Every `index.Rmd` follows this setup sequence. Order matters.

```r
# 1. Gitbook vs PDF switch
gitbook_on <- TRUE

# 2. Knitr options
knitr::opts_chunk$set(
  echo = identical(gitbook_on, TRUE),  # Show code only in gitbook
  message = FALSE, warning = FALSE,
  dpi = 60, out.width = "100%"
)
options(scipen = 999)
options(knitr.kable.NA = '--')
options(knitr.kable.NAN = '--')

# 3. Source in order: packages → static imports → functions → data
source('scripts/packages.R')
source('scripts/staticimports.R')
source('scripts/functions.R')
```

Responsive settings by output format:

```r
# Gitbook
photo_width <- "100%"; font_set <- 11

# PDF (paged.js)
photo_width <- "80%"; font_set <- 9
```

## YAML Parameters

Parameters live in `index.Rmd` frontmatter (not a separate file). Child repos override by editing these values.

```yaml
params:
  repo_url: 'https://github.com/NewGraphEnvironment/repo_name'
  report_url: 'https://www.newgraphenvironment.com/repo_name/'
  update_packages: FALSE
  update_bib: TRUE
  gitbook_on: TRUE
```

Fish passage repos add project-specific params (`project_region`, `model_species`, `wsg_code`, update flags for forms). These are project-specific — don't add them to the general template.

## Chunk Naming

Embed context and purpose in chunk names. The principle is universal; the codes are project-specific.

**Pattern:** `{type}-{system}-{description}`

| Type | Examples |
|------|---------|
| Tables | `tab-kln-load-int-yr`, `tab-sites-sum`, `tab-wshd-196332` |
| Figures | `plot-wq-kln-quadratic`, `map-interactive`, `map-196332` |
| Photos | `photo-196332-01`, `photo-196332-d01` (dual layout) |

## Cross-References

Bookdown auto-prepends `fig:` or `tab:` to chunk names.

- **Tables:** `Table \@ref(tab:chunk-name)`
- **Figures:** `Figure \@ref(fig:chunk-name)`

No `fig:` or `tab:` prefix in the chunk label itself — bookdown adds it.

## Table Caption Workaround

Interactive tables (DT) can't use standard bookdown captions. Use the `my_tab_caption()` function from `staticimports.R`.

**Pattern:** Separate `-cap` chunk from table chunk.

```r
# Caption chunk — must use results="asis"
{r tab-sites-sum-cap, results="asis"}
my_caption <- "Summary of fish passage assessment procedures."
my_tab_caption()
```

```r
# Table chunk — renders the DT
{r tab-sites-sum}
data |> my_dt_table(page_length = 20, cols_freeze_left = 0)
```

`my_tab_caption()` auto-grabs the chunk label via `knitr::opts_current$get()$label` and wraps it in HTML caption tags that bookdown can cross-reference.

## Photo Layout

Separate prep chunk (find the file) from display chunk (render it).

```r
# Prep — find the photo
{r photo-196332-01-prep}
my_photo1 <- fpr::fpr_photo_pull_by_str(str_to_pull = 'ds_typical_1_')
my_caption1 <- paste0('Typical habitat downstream of PSCIS crossing ', my_site, '.')
```

```r
# Gitbook — full width
{r photo-196332-01, fig.cap=my_caption1, out.width=photo_width, eval=gitbook_on}
knitr::include_graphics(my_photo1)
```

```r
# PDF — side by side with 1% spacer
{r photo-196332-d01, fig.show="hold", out.width=c("49.5%","1%","49.5%"), eval=identical(gitbook_on, FALSE)}
knitr::include_graphics(my_photo1)
knitr::include_graphics("fig/pixel.png")
knitr::include_graphics(my_photo2)
```

## Bibliography

**`references.bib` is auto-generated — never edit it manually.** On each build, `rbbt::bbt_write_bib()` scans all `.Rmd` files for `@citekey` references, pulls the BibTeX from Zotero's Better BibTeX, and overwrites `references.bib`. Any manual additions will be lost on the next build.

To add a reference: add it to the shared Zotero group library, use its BBT citation key (`@key`) in the `.Rmd` text, and build. rbbt handles the rest.

```yaml
bibliography: "`r rbbt::bbt_write_bib('references.bib', overwrite = TRUE)`"
biblio-style: apalike
link-citations: no
```

When `update_bib: FALSE` in params, the build uses the existing `references.bib` without regenerating — useful for offline builds or CI where Zotero isn't running.

Auto-generate package citations:

```r
knitr::write_bib(c(.packages(), 'bookdown', 'knitr', 'rmarkdown'), 'packages.bib')
```

Use `nocite:` in YAML to include references not cited in text.

## Acknowledgement & AI Disclosure

`index.Rmd` contains two separate front-matter sections after the setup chunks:

### Acknowledgement {.front-matter .unnumbered}

Three parts, in order:

1. **Personal connection to land** (template-level, same across all reports):
   > At New Graph Environment, we understand our well-being as inseparable from the health of the land and waters we work within. When we care for ecosystems, we care for ourselves and for the communities connected to them. This relationship is not metaphorical — it is the foundation of our practice.

2. **Colonial acknowledgement** (template-level):
   > Modern civilization has a long journey ahead to acknowledge and address the historic and ongoing impacts of colonialism...

3. **Territorial acknowledgement** (project-specific, must be edited per report): Name the Nations, governance systems, watersheds, and species relevant to the project. Do not use a generic office-location acknowledgement — tie it to the territory where the work happens. See the Wedzin Kwa chinook example for the pattern.

4. **Funding and partners** (project-specific).

### AI Disclosure

Do not use a `#` heading for the disclosure — this creates a separate chapter page in gitbook. Instead, add it to the YAML `date:` field so it renders in the title block:

```yaml
date: |
 |
 | Version X.X.X DRAFT `r format(Sys.Date(), "%Y-%m-%d")`
 |
 | *Claude Sonnet 4.6 (Anthropic) assisted with literature synthesis, drafting, and technical writing. All scientific interpretation, data analysis, and conclusions are the responsibility of the authors.*
```

**Wording principle:** Be accurate about what the LLM did. It assisted with drafting and synthesis — it did not make scientific interpretations or conclusions. Do not say "independently verified by the authors" (redundant) or attribute "ecological assessments" to the LLM.

For regulatory/EGBC-stamped work, use the extended disclaimer from `soul/research/20260212_ai_disclosure_research.md`. See NewGraphEnvironment/mybookdown-template#89.

## Conditional Rendering (Gitbook vs PDF)

A single boolean `gitbook_on` controls output format throughout.

```r
# Show only in gitbook
{r map-interactive, eval=gitbook_on}

# Show only in PDF
{r fig-print-only, eval=identical(gitbook_on, FALSE)}

# Conditional inline content
`r if(identical(gitbook_on, FALSE)) knitr::asis_output("This report is available online...")`

# Page breaks for PDF only
`r if(gitbook_on){knitr::asis_output("")} else knitr::asis_output("\\pagebreak")`
```

## Versioning and Changelog

Reports use MAJOR.MINOR.PATCH versioning with a `NEWS.md` changelog.

**Version in `index.Rmd` YAML:**
```yaml
date: |
 |
 | Version 1.1.0 DRAFT `r format(Sys.Date(), "%Y-%m-%d")`
```

**NEWS.md format:**
```markdown
## 1.1.0 (2026-02-17)

- Add feature X
- Fix issue Y ([Issue #N](https://github.com/Org/repo/issues/N))
```

**Auto-append as appendix** via `my_news_to_appendix()` in `staticimports.R`:
```r
news_to_appendix(md_name = "NEWS.md", rmd_name = "2090-report-change-log.Rmd")
```

**Convention:**
- Bump version in `index.Rmd` and add NEWS entry for every commit to main that changes report content
- Tag releases: `git tag -a v1.1.0 -m "v1.1.0: Brief description"`
- MAJOR: structural changes, new chapters, methodology changes
- MINOR: new content, figures, tables, discussion sections
- PATCH: prose fixes, corrections, formatting

## COG Viewer Embedding

Always use `ngr::ngr_str_viewer_cog()` — never hardcode viewer iframes.

```r
knitr::asis_output(ngr::ngr_str_viewer_cog("https://bucket.s3.us-west-2.amazonaws.com/ortho.tif"))
```

The function includes a cache-busting `?v=` parameter. Bump `v` in the function default when `viewer.html` has breaking changes.

## Dependency Management

Use `renv` for reproducible package management:
- `.Rprofile` activates renv on startup
- `renv::restore()` installs from lockfile
- `renv::snapshot()` updates lockfile after adding packages
- Use `pak::pak("pkg")` to install (not `install.packages`)

## Known Drift

Production repos (2024-2025) have drifted from templates in these areas. When working in a child repo, match what that repo does, not the template:

- **Script naming in `02_reporting/`** — older repos use `tables.R`, `0165-read-sqlite.R`; newer repos use numbered `0130-tables.R`. Follow the repo you're in.
- **Removed packages** — `elevatr`, `rayshader`, `arrow` removed from production but still in template.
- **`staticimports::import()` call** — some repos skip it and source `staticimports.R` directly.
- **Hardcoded vs parameterized years** — older repos hardcode years in file paths; newer repos use `params$project_year`. Prefer parameterized.


# Cartography

## Style Registry

Use the `gq` package for all shared layer symbology. Never hardcode hex color values when a registry style exists.

```r
library(gq)
reg <- gq_reg_main()  # load once per script — 51+ layers
```

**Core pattern:** `reg$layers$lake`, `reg$layers$road`, `reg$layers$bec_zone`, etc.

### Translators

| Target | Simple layer | Classified layer |
|--------|-------------|-----------------|
| tmap | `gq_tmap_style(layer)` → `do.call(tm_polygons, ...)` | `gq_tmap_classes(layer)` → field, values, labels |
| mapgl | `gq_mapgl_style(layer)` → paint properties | `gq_mapgl_classes(layer)` → match expression |

### Custom styles

For project-specific layers not in the main registry, use a hand-curated CSV and merge:

```r
reg <- gq_reg_merge(gq_reg_main(), gq_reg_read_csv("path/to/custom.csv"))
```

Install: `pak::pak("NewGraphEnvironment/gq")`

## Map Targets

| Output | Tool | When |
|--------|------|------|
| PDF / print figures | `tmap` v4 | Bookdown PDF, static reports |
| Interactive HTML | `mapgl` (MapLibre GL) | Bookdown gitbook, memos, web pages |
| QGIS project | Native QML | Field work, Mergin Maps |

## Key Rules

- **`sf_use_s2(FALSE)`** at top of every mapping script
- **Compute area BEFORE simplify** in SQL
- **No map title** — title belongs in the report caption
- **Legend over least-important terrain** — swap legend and logo sides when it reduces AOI occlusion. No fixed convention for which side.
- **Four-corner rule** — legend, logo, scale bar, keymap each get their own corner. Never stack two in the same quadrant.
- **Bbox must match canvas aspect ratio** — compute the ratio from geographic extents and page dimensions. Mismatch causes white space bands.
- **Consistent element-to-frame spacing** — all inset elements should have visually equal margins from the frame edge
- **Map fills to frame** — basemap extends edge-to-edge, no dead bands. Use near-zero `inner.margins` and `outer.margins`.
- **Suppress auto-legends** — build manual ones from registry values
- **ALL CAPS labels appear larger** — use title case for legend labels (gq `gq_tmap_classes()` handles this automatically via `to_title()` fallback)

## Self-Review (after every render)

Read the PNG and check before showing anyone:

1. Correct polygon/study area shown? (verify source data, not just the bbox)
2. Map fills the page? (no white/black bands)
3. Keymap inside frame with spacing from edge?
4. No element overlap? (each in its own corner)
5. Legend over least-important terrain?
6. Consistent spacing across all elements?
7. Scale bar breaks appropriate for extent?

See the `cartography` skill for full reference: basemap blending, BC spatial data queries, label hierarchy, mapgl gotchas, and worked examples.

## Land Cover Change

Use [drift](https://github.com/NewGraphEnvironment/drift) and [flooded](https://github.com/NewGraphEnvironment/flooded) together for riparian land cover change analysis. flooded delineates floodplain extents from DEMs and stream networks; drift tracks what's changing inside them over time.

**Pipeline:**

```r
# 1. Delineate floodplain AOI (flooded)
valleys <- flooded::fl_valley_confine(dem, streams)

# 2. Fetch, classify, summarize (drift)
rasters   <- drift::dft_stac_fetch(aoi, source = "io-lulc", years = c(2017, 2020, 2023))
classified <- drift::dft_rast_classify(rasters, source = "io-lulc")
summary    <- drift::dft_rast_summarize(classified, unit = "ha")

# 3. Interactive map with layer toggle
drift::dft_map_interactive(classified, aoi = aoi)
```

- Class colors come from drift's shipped class tables (IO LULC, ESA WorldCover)
- For production COGs on S3, `dft_map_interactive()` serves tiles via titiler — set `options(drift.titiler_url = "...")`
- See the [drift vignette](https://www.newgraphenvironment.com/drift/articles/neexdzii-kwa.html) for a worked example (Neexdzii Kwa floodplain, 2017-2023)


# Code Check Conventions

Structured checklist for reviewing diffs before commit. Used by `/code-check`.
Add new checks here when a bug class is discovered — they compound over time.

## Shell Scripts

### Quoting
- Variables in double-quoted strings containing single quotes break if value has `'`
- `"echo '${VAR}'"` — if VAR contains `'`, shell syntax breaks
- Use `printf '%s\n' "$VAR" | command` to pipe values safely
- Heredocs: unquoted `<<EOF` expands variables locally, `<<'EOF'` does not — know which you need

### Paths
- Hardcoded absolute paths (`/Users/airvine/...`) break for other users
- Use `REPO_ROOT="$(cd "$(dirname "$0")/<relative>" && pwd)"`
- After moving scripts, verify `../` depth still resolves correctly
- Usage comments should match actual script location

### Silent Failures
- `|| true` hides real errors — is the failure actually safe to ignore?
- Empty variable before destructive operation (rm, destroy) — add guard: `[ -n "$VAR" ] || exit 1`
- `grep` returning empty silently — downstream commands get empty input

### Process Visibility
- Secrets passed as command-line args are visible in `ps aux`
- Use env files, stdin pipes, or temp files with `chmod 600` instead

## Cloud-Init (YAML)

### ASCII
- Must be pure ASCII — em dashes, curly quotes, arrows cause silent parse failure
- Check with: `perl -ne 'print "$.: $_" if /[^\x00-\x7F]/' file.yaml`

### State
- `cloud-init clean` causes full re-provisioning on next boot — almost never what you want before snapshot
- Use `tailscale logout` not `tailscale down` before snapshot (deregister vs disconnect)

### Template Variables
- Secrets rendered via `templatefile()` are readable at `169.254.169.254` metadata endpoint
- Acceptable for ephemeral machines, document the tradeoff

## OpenTofu / Terraform

### State
- Parsing `tofu state show` text output is fragile — use `tofu output` instead
- Missing outputs that scripts need — add them to main.tf
- Snapshot/image IDs in tfvars after deleting the snapshot — stale reference

### Destructive Operations
- Validate resource IDs before destroy: `[ -n "$ID" ] || exit 1`
- `tofu destroy` without `-target` destroys everything including reserved IPs
- Snapshot ID extraction: use `--resource droplet` and `grep -F` for exact match

## Security

### Secrets in Committed Files
- `.tfvars` must be gitignored (contains tokens, passwords)
- `.tfvars.example` should have all variables with empty/placeholder values
- Sensitive variables need `sensitive = true` in variables.tf

### Firewall Defaults
- `0.0.0.0/0` for SSH is world-open — document if intentional
- If access is gated by Tailscale, say so explicitly

### Credentials
- Passwords with special chars (`'`, `"`, `$`, `!`) break naive shell quoting
- `printf '%q'` escapes values for shell safety
- Temp files for secrets: create with `chmod 600`, delete after use

## R / Package Installation

### pak Behavior
- pak stops on first unresolvable package — all subsequent packages are skipped
- Removed CRAN packages (like `leaflet.extras`) must move to GitHub source
- PPPM binaries may lag a few hours behind new CRAN releases

### Reproducibility
- Branch pins (`pkg@branch`) are not reproducible — document why used
- Pinned download URLs (RStudio .deb) go stale — document where to update

## General

### Adopting Existing Config

When importing config from one location into a canonical one (legacy `~/.bash_profile` → dotfiles repo, old script's env → repo, another project's `settings.json` → soul):

- **Verify every referenced path/binary exists.** Dead PATH exports, missing interpreters, stale env vars should be cut, not codified.
  Shell paths: `for p in $(echo "$PATH" | tr ':' ' '); do [ -d "$p" ] || echo "DEAD: $p"; done`
- **Ask before dropping a reference** — it may be something the user forgot to reinstall on this machine, not something to delete.
- **Curated subset, not verbatim copy.** The diff should reflect what you verified, not the whole source.

### Documentation Staleness
- Moving/renaming scripts: update CLAUDE.md, READMEs, usage comments
- New variables: update .tfvars.example
- New workflows: update relevant README


# Comms Conventions

This repo has a `comms/` directory — you're in the cross-repo Claude-to-Claude messaging system. Full protocol in `comms/README.md`. Load-bearing behaviors below.

## On Session Start

1. **Inbound scan.** `<this-repo>/comms/*/` — files with `status: open` and mtime newer than your last `comms/` commit are mail for you.
2. **Outbound scan.** For each peer below, check `<peer>/comms/<this-repo>/*.md` — files with `from: <this-repo>, status: open` are your un-answered sent mail.

If either surfaces open threads, raise to the user before starting other work.

## Peers

Repos with active `comms/` directories (update when new repos adopt):

- rtj
- kdot
- soul
- fresh
- link

## Commit Prefix

- `comms(→peer):` — you committed a file in peer's repo (outbound)
- `comms(←peer):` — you committed a file in your own repo (inbound reply)
- `comms:` — meta (close, reopen, rename, README update)

Arrow points to the repo whose `comms/` contains the file you committed.

## Non-negotiables

- One commit per appended message.
- **Push immediately.** Un-pushed comms is invisible to the other Claude.
- Code + comms = separate commits.
- Status flips bundle with the triggering message.
- **Use `git commit --only <file>`** for any commit in a peer's repo (thread files). Immune to index races from parallel sessions — commits only the named path regardless of what else is staged.

## Propagation: soul publishes, peers pull

Soul is the source of truth for `comms/README.md`. Peers sync by running `/comms-init` in their own repo, from their own Claude session. **Do not push README updates into a peer's repo from another session** — cross-session index races can bundle unrelated staged files into misleading commits.

Within your own session, the only things you commit into a peer's repo are **thread files** (hosted in the receiver's repo per the receiver-hosts rule). Everything else — README syncs, infra — the peer-Claude pulls itself.


# LLM Behavioral Guidelines

<!-- Source: https://github.com/forrestchang/andrej-karpathy-skills/main/CLAUDE.md -->
<!-- Last synced: 2026-02-06 -->
<!-- These principles are hardcoded locally. We do not curl at deploy time. -->
<!-- Periodically check the source for meaningful updates. -->

Behavioral guidelines to reduce common LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.


**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.


# New Graph Environment Conventions

Core patterns for professional, efficient workflows across New Graph Environment repositories.

## Ecosystem Overview

Five repos form the governance and operations layer across all New Graph Environment work:

| Repo | Purpose | Analogy |
|------|---------|---------|
| [compass](https://github.com/NewGraphEnvironment/compass) | Ethics, values, guiding principles | The "why" |
| [soul](https://github.com/NewGraphEnvironment/soul) | Standards, skills, conventions for LLM agents | The "how" |
| [compost](https://github.com/NewGraphEnvironment/compost) | Communications templates, email workflows, contact management | The "who" |
| [rtj](https://github.com/NewGraphEnvironment/rtj) (formerly awshak) | Infrastructure as Code, deployment | The "where" |
| [gq](https://github.com/NewGraphEnvironment/gq) | Cartographic style management across QGIS, tmap, leaflet, web | The "look" |

**Adaptive management:** Conventions evolve from real project work, not theory. When a pattern is learned or refined during project work, propagate it back to soul so all projects benefit. The `/claude-md-init` skill builds each project's `CLAUDE.md` from soul conventions.

**Cross-references:** [sred-2025-2026](https://github.com/NewGraphEnvironment/sred-2025-2026) tracks R&D activities across repos. Compost is the centralized communications workflow — all email drafts, contact registry, and external outreach are authored there, not in individual project repos.

## Issue Workflow

### Before Creating an Issue (non-negotiable)

1. **Check for duplicates:** `gh issue list --state open --search "<keywords>"` -- search before creating
2. **Link to SRED:** If work involves infrastructure, R&D, tooling, or performance benchmarking, add `Relates to NewGraphEnvironment/sred-2025-2026#N` (match by repo name in SRED issue title)
3. **One issue, one concern.** Keep focused.

### Professional Issue Writing

Write issues with clear technical focus:

- **Use normal technical language** in titles and descriptions
- **Focus on the problem and solution** approach
- **Add tracking links at the end** (e.g., `Relates to Owner/repo#N`)

**Issue body structure:**
```markdown
## Problem
<what's wrong or missing>

## Proposed Solution
<approach>

Relates to #<local>
Relates to NewGraphEnvironment/sred-2025-2026#<N>
```

### GitHub Issue Creation - Always Use Files

The `gh issue create` command with heredoc syntax fails repeatedly with EOF errors. ALWAYS use `--body-file`:

```bash
cat > /tmp/issue_body.md << 'EOF'
## Problem
...

## Proposed Solution
...
EOF

gh issue create --title "Brief technical title" --body-file /tmp/issue_body.md
```

## Closing Issues

**DO:** Close issues via commit messages. The commit IS the closure and the documentation.

```
Fix broken DEM path in loading pipeline

Update hardcoded path to use config-driven resolution.

Fixes #20
Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

**DON'T:** Close issues with `gh issue close`. This breaks the audit trail — there's no linked diff showing what changed.

- `Fixes #N` or `Closes #N` — auto-closes and links the commit to the issue
- `Relates to #N` — partial progress, does not close
- Always close issues when work is complete. Don't leave stale open issues.

## Commit Quality

Write clear, informative commit messages:

```
Brief description (50 chars or less)

Detailed explanation of changes and impact.

Fixes #<issue> (or Relates to #<issue>)
Relates to NewGraphEnvironment/sred-2025-2026#<N>

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
```

**When to commit:**
- Logical, atomic units of work
- Working state (tests pass)
- Clear description of changes

**What to avoid:**
- "WIP" or "temp" commits in main branch
- Combining unrelated changes
- Vague messages like "fixes" or "updates"

## LLM Agent Conventions

Rules learned from real project sessions. These apply across all repos.

- **Install missing packages, don't workaround** — if a package is needed, ask the user to install it (e.g. `pak::pak("pkg")`). Don't write degraded fallback code to avoid the dependency.
- **Never hardcode extractable data** — if coordinates, station names, or metadata can be pulled from an API or database at runtime, do that. Don't hardcode values that have a programmatic source.
- **Close issues via commits, not `gh issue close`** — see Closing Issues above.
- **Cite primary sources** — see references conventions.

## Naming Conventions

**Pattern: `noun_verb-detail`** -- noun first, verb second across all naming:

| What | Example |
|------|---------|
| Skills | `claude-md-init`, `gh-issue-create`, `planning-update` |
| Scripts | `stac_register-baseline.sh`, `stac_register-pypgstac.sh` |
| Logs | `20260209_stac_register-baseline_stac-dem-bc.txt` |
| Log format | `yyyymmdd_noun_verb-detail_target.ext` |

Scripts and logs live together: `scripts/<module>/logs/`

## Projects vs Milestones

- **Projects** = daily cross-repo tracking (always add to relevant project)
- **Milestones** = iteration boundaries (only for release/claim prep)
- Don't double-track unless there's a reason

| Content | Project |
|---------|---------|
| R&D, experiments, SRED-related | **SRED R&D Tracking (#8)** |
| Data storage, sqlite, postgres, pipelines | **Data Architecture (#9)** |
| Fish passage field/reporting | **Fish Passage 2025 (#6)** |
| Restoration planning | **Aquatic Restoration Planning (#5)** |
| QGIS, Mergin, field forms | **Collaborative GIS (#3)** |


# Planning Conventions

How Claude manages structured planning for complex tasks using planning-with-files (PWF).

## When to Plan

Use PWF when a task has multiple phases, requires research, or involves more than ~5 tool calls. Triggers:
- User says "let's plan this", "plan mode", "use planning", or invokes `/planning-init`
- Complex issue work begins (multi-step, uncertain approach)
- Claude judges the task warrants structured tracking

Skip planning for single-file edits, quick fixes, or tasks with obvious next steps.

## The Workflow

1. **Explore first** — Enter plan mode (read-only). Read code, trace paths, understand the problem before proposing anything.
2. **Plan to files** — Write the plan into 3 files in `planning/active/`:
   - `task_plan.md` — Phases with checkbox tasks
   - `findings.md` — Research, discoveries, technical analysis
   - `progress.md` — Session log with timestamps and commit refs
3. **Commit the plan** — Commit the planning files before starting implementation. This is the baseline.
4. **Work in atomic commits** — Each commit bundles code changes WITH checkbox updates in the planning files. The diff shows both what was done and the checkbox marking it done.
5. **Code check before commit** — Run `/code-check` on staged diffs before committing. Don't mark a task done until the diff passes review.
6. **Archive when complete** — Move `planning/active/` to `planning/archive/` via `/planning-archive`. Write a README.md in the archive directory with a one-paragraph outcome summary and closing commit/PR ref — future sessions scan these to catch up fast.

## Atomic Commits (Critical)

Every commit that completes a planned task MUST include:
- The code/script changes
- The checkbox update in `task_plan.md` (`- [ ]` -> `- [x]`)
- A progress entry in `progress.md` if meaningful

This creates a git audit trail where `git log -- planning/` tells the full story. Each commit is self-documenting — you can backtrack with git and understand everything that happened.

## File Formats

### task_plan.md

Phases with checkboxes. This is the core tracking file.

```markdown
# Task Plan

## Phase 1: [Name]
- [ ] Task description
- [ ] Another task

## Phase 2: [Name]
- [ ] Task description
```

Mark tasks done as they're completed: `- [x] Task description`

### findings.md

Append-only research log. Discoveries, technical analysis, things learned.

```markdown
# Findings

## [Topic]
[What was found, with source/date]
```

### progress.md

Session entries with commit references.

```markdown
# Progress

## Session YYYY-MM-DD
- Completed: [items]
- Commits: [refs]
- Next: [items]
```

## Directory Structure

```
planning/
  active/          <- Current work (3 PWF files)
  archive/         <- Completed issues
    YYYY-MM-issue-N-slug/
```

If `planning/` doesn't exist in the repo, run `/planning-init` first.

## Skills

| Skill | When to use |
|-------|-------------|
| `/planning-init` | First time in a repo — creates directory structure |
| `/planning-update` | Mid-session — sync checkboxes and progress |
| `/planning-archive` | Issue complete — archive and create fresh active/ |


# Reference Management Conventions

How references flow between Claude Code, Zotero, and technical writing at New Graph Environment.

## Tool Routing

Three tools, different purposes. Use the right one.

| Need | Tool | Why |
|------|------|-----|
| Search by keyword, read metadata/fulltext, semantic search | **MCP `zotero_*` tools** | pyzotero, works with Zotero item keys |
| Look up by citation key (e.g., `irvine2020ParsnipRiver`) | **`/zotero-lookup` skill** | Citation keys are a BBT feature — pyzotero can't resolve them |
| Create items, attach PDFs, deduplicate | **`/zotero-api` skill** | Connector API for writes, JS console for attachments |

**Citation keys vs item keys:** Citation keys (like `irvine2020ParsnipRiver`) come from Better BibTeX. Item keys (like `K7WALMSY`) are native Zotero. The MCP works with item keys. `/zotero-lookup` bridges citation keys to item data.

**BBT citation key storage:** As of Feb 2025+, BBT stores citation keys as a `citationKey` field directly in `zotero.sqlite` (via Zotero's item data system), not in a separate BBT database. The old `better-bibtex.sqlite` and `better-bibtex.migrated` files are stale and no longer updated. Query citation keys with: `SELECT idv.value FROM items i JOIN itemData id ON i.itemID = id.itemID JOIN itemDataValues idv ON id.valueID = idv.valueID JOIN fields f ON id.fieldID = f.fieldID WHERE f.fieldName = 'citationKey'`.

## Adding References Workflow

### 1. Search and flag

When research turns up a reference:
- **DOI available:** Tell the user — Zotero's magic wand (DOI lookup) is the fastest path
- **ResearchGate link:** Flag to user for manual check — programmatic fetch is blocked (403), but full text is often there
- **BC gov report:** Search [ACAT](https://a100.gov.bc.ca/pub/acat/), for.gov.bc.ca library, EIRS viewer
- **Paywalled:** Note it, move on. Don't waste time trying to bypass.

### 2. Add to Zotero

**Preferred order:**
1. DOI magic wand in Zotero UI (fastest, most complete metadata)
2. Web API POST with `collections` array (grey literature, local PDFs — targets collection directly, no UI interaction needed)
3. `saveItems` via `/zotero-api` (batch creation from structured data — requires UI collection selection)
4. JS console script for group library (when connector can't target the right collection)

**Collection targeting:** `saveItems` drops items into whatever collection is selected in Zotero's UI. Always confirm with the user before calling it. **Web API bypasses this** — include `"collections": ["KEY"]` in the POST body. Find collection keys with `?q=name` search on the collections endpoint.

### 3. Attach PDFs

`saveItems` attachments silently fail. Don't use them. Instead:

1. **Web API S3 upload (preferred):** Create attachment item → get upload auth → build S3 body (Python: prefix + file bytes + suffix) → POST to S3 → register with uploadKey. Works without Zotero running. See `/zotero-api` skill section 4.
2. **JS console fallback:** Download with `curl`, attach via `item_attach_pdf.js` in Zotero JS console.
3. Verify attachment exists via MCP: `zotero_get_item_children`

### 4. Verify

After manual adds, confirm via MCP:
- `zotero_search_items` — find by title
- `zotero_get_item_metadata` — check fields are complete
- `zotero_get_item_children` — confirm PDF attached

### 5. Clean up

If duplicates were created (common with `saveItems` retries):
- Run `collection_dedup.js` via Zotero JS console
- It keeps the copy with the most attachments, trashes the rest

## In Reports (bookdown)

### Bibliography generation

```yaml
# index.Rmd — dynamic bib from Zotero via Better BibTeX
bibliography: "`r rbbt::bbt_write_bib('references.bib', overwrite = TRUE)`"
```

`rbbt` pulls from BBT, which syncs with Zotero. Edit references in Zotero → rebuild report → bibliography updates.

**Library targeting:** rbbt must know which Zotero library to search. This is set globally in `~/.Rprofile`:

```r
# default library — NewGraphEnvironment group (libraryID 9, group 4733734)
options(rbbt.default.library_id = 9)
```

Without this option, rbbt searches only the personal library (libraryID 1) and won't find group library references. The library IDs map to Zotero's internal numbering — use `/zotero-lookup` with `SELECT DISTINCT libraryID FROM citationkey` against the BBT database to discover available libraries.

### Citation syntax

- `[@key2020]` — parenthetical: (Author 2020)
- `@key2020` — narrative: Author (2020)
- `[@key1; @key2]` — multiple
- `nocite:` in YAML — include uncited references

### Cite primary sources

When a review paper references an older study, trace back to the original and cite it. Don't attribute findings to the review when the original exists. (See LLM Agent Conventions in `newgraph.md`.)

**When the original is unavailable** (paywalled, out of print, can't locate): use secondary citation format in the prose and include bib entries for both sources:

> Smith et al. (2003; as cited in Doctor 2022) found that...

Both `@smith2003` and `@doctor2022` go in the `.bib` file. The reader can then track down the original themselves. Flag incomplete metadata on the primary entry — it's better to have a partial reference than none at all.

## PDF Fallback Chain

When you need a PDF and the obvious URL doesn't work:

1. DOI resolver → publisher site (often has OA link)
2. Europe PMC (`europepmc.org/backend/ptpmcrender.fcgi?accid=PMC{ID}&blobtype=pdf`) — ncbi blocks curl
3. SciELO — needs `User-Agent: Mozilla/5.0` header
4. ResearchGate — flag to user for manual download
5. Semantic Scholar — sometimes has OA links
6. Ask user for institutional access

Always verify downloads: `file paper.pdf` should say "PDF document", not HTML.

## Searching Paper Content (ragnar)

### Setup (per project)
- `scripts/rag_build.R` — maps citation keys to Zotero PDF attachment keys, builds DuckDB
- `data/rag/` gitignored — store is local, not committed
- Dependencies: ragnar, Ollama with nomic-embed-text model
- See `/lit-search` skill for full recipe

### Query
`ragnar_store_connect()` then `ragnar_retrieve()` — returns chunks with source file attribution.

### Anti-patterns
- NEVER write abstracts manually — if CrossRef has no abstract, leave blank
- NEVER cite specific numbers without verifying from the source PDF via ragnar search
- NEVER paraphrase equations — copy exact notation and cite page/section


# SRED Conventions

How SR&ED tracking integrates with New Graph Environment's development workflows.

## The Claim: One Project

All SRED-eligible work across NGE falls under a **single continuous project**:

> **Dynamic GIS-based Data Processing and Reporting Framework**

- **Field:** Software Engineering (2.02.09)
- **Start date:** May 2022
- **Fiscal year:** May 1 – April 30
- **Consultant:** Boast Capital (prepares final technical report)

**Do not fragment work into separate claims.** Each fiscal year's work is structured as iterations within this one project. Internal tracking (experiment numbers in `sred-2025-2026`) maps to iterations — Boast assembles the final narrative.

## Tagging Work for SRED

### Commits

Use `Relates to NewGraphEnvironment/sred-2025-2026#N` in commit messages when work is SRED-eligible.

### Time entries (rolex)

Tag hours with `sred_ref` field linking to the relevant `sred-2025-2026` issue number.

### GitHub issues

Link SRED-eligible issues to the tracking repo: `Relates to NewGraphEnvironment/sred-2025-2026#N`

## What Qualifies as SRED

**Eligible (systematic investigation to overcome technological uncertainty):**
- Building tools/functions that don't exist in standard practice
- Prototyping new integrations between systems (GIS ↔ reporting ↔ field collection)
- Testing whether an approach works and documenting why it did/didn't
- Iterating on failed approaches with new hypotheses

**Not eligible:**
- Standard configuration of known tools
- Routine bug fixes in working systems
- Writing reports using the framework (that's service delivery)

**The test:** "Did we try something we weren't sure would work, and did we learn something from the attempt?" If yes, it's likely eligible.

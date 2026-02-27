# Findings: GitHub Actions Build Research

## Current Build Process Analysis

### HTML Build (scripts/run.R)
```r
bookdown::render_book("index.Rmd")
```
- Straightforward, should work in GA with r-lib/actions

### PDF Build (scripts/run.R)
```r
# 1. Render to pagedown HTML
bookdown::render_book("index.Rmd",
                      output_format = 'pagedown::html_paged',
                      params = list(update_bib = update_bib, gitbook_on = FALSE))

# 2. Convert to PDF via Chrome
pagedown::chrome_print(paste0(filename_html, '.html'),
                       output = paste0('docs/', filename_html, '.pdf'),
                       timeout = 180)

# 3. Compress with ghostscript
tools::compactPDF(paste0("docs/", filename_html, ".pdf"),
                  gs_quality = 'screen',
                  gs_cmd = "opt/homebrew/bin/gs")  # macOS path
```

**GA Challenges:**
- Needs Chrome/Chromium installed
- Needs ghostscript installed
- Path differences (macOS vs Ubuntu runner)

## Reference Implementation: nrp-nutrient-loading-2025

**Directory structure:**
```
docs/
  index.html          ← Dummy public page
  <password-dir>/     ← Actual report (obscured URL)
    index.html
    background.html
    ...
```

**Key insight:** Password protection = obscure subdirectory name. No actual auth layer.

## GA Workflow Research

### r-lib/actions Standard Setup
```yaml
- uses: r-lib/actions/setup-r@v2
- uses: r-lib/actions/setup-pandoc@v2
- uses: r-lib/actions/setup-r-dependencies@v2
```

### Chrome in GA Runners
Ubuntu runners include Chrome. For pagedown:
```yaml
- name: Install Chrome
  run: |
    sudo apt-get install -y chromium-browser
    # or use pre-installed google-chrome
```

### Ghostscript in GA
```yaml
- name: Install Ghostscript
  run: sudo apt-get install -y ghostscript
```

## Parameter Access Strategy

**Option 1:** Read params from index.Rmd in R, pass to shell
```r
# In R script
params <- rmarkdown::yaml_front_matter('index.Rmd')$params
cat(params$password_dir, file = 'password_dir.txt')
```

**Option 2:** Duplicate config in workflow env vars
```yaml
env:
  PASSWORD_PROTECTED: true
  PASSWORD_DIR: 'report_access_2025'
```
Downside: Config in two places

**Option 3:** Config file (e.g., `_config.yml`)
Single source of truth, read by both R and workflow.

**Recommendation:** Option 1 (read from index.Rmd) - keeps params as single source of truth

## Dependency Management Discovery

**Current state:**
- `DESCRIPTION` only lists bookdown
- `scripts/packages.R` has outdated package list
- r-lib/actions reads DESCRIPTION → build would fail

**packages.R includes:**
- CRAN: tidyverse, knitr, bookdown, rmarkdown, pagedown, readwritesqlite, RPostgres, sf
- GitHub: newgraphenvironment/fpr, haozhu233/kableExtra@a9c509a

**System deps needed:**
- sf → GDAL, GEOS, PROJ
- RPostgres → PostgreSQL client libs

**Decision:** Use renv instead of manual DESCRIPTION maintenance
- Created #76 for renv evaluation
- #75 blocked until dependency management resolved
- renv provides lockfile for reproducibility (critical for 5-6 year old reports)

## renv Setup Findings

**Initialization:**
```r
options(renv.config.pak.enabled = TRUE)  # Use pak for faster installs
renv::init(bare = TRUE)                   # Start clean
renv::settings$snapshot.type("implicit")  # Capture packages used in project
```

**Minimal package set for mybookdown-template:**
- Core: bookdown, knitr, rmarkdown, pagedown
- Interactive: DT, leaflet, leaflet.extras, htmlwidgets
- Data: tidyverse, glue
- NewGraph: fpr, staticimports
- Utils: desc, devtools

**Removed (not actually used):**
- readwritesqlite
- RPostgres
- sf (installed as dependency, not direct)
- kableExtra fork (fpr::fpr_kable used instead)

**renv.lock stats:**
- 7244 lines
- 150+ packages with exact versions
- Includes GitHub packages (fpr, staticimports, rbbt)

**GA Workflow with renv:**
- Cache `~/.local/share/renv` and `renv/library`
- Key on `hashFiles('renv.lock')`
- System deps needed: gdal, geos, proj, magick, etc.

## Open Questions

- [ ] Does pagedown::chrome_print work reliably on Ubuntu runners?
- [ ] Performance: How long does full build take in GA?
- [x] Caching: Can we cache R packages effectively? → Yes, renv + actions/cache
- [x] How to manage dependencies? → renv (#76)

# Task Plan: GitHub Actions Build with Password-Protected Deployment

**Issue:** #75 - Move to GitHub Actions builds with password-protected deployment
**Branch:** `75-github-actions-build`
**SRED Link:** https://github.com/NewGraphEnvironment/sred-2025-2026/issues/3

## Goal

Replace local builds + committing `docs/` with GitHub Actions builds that support both public and password-protected deployment modes via configuration parameter.

## Success Criteria

- [ ] GA workflow builds bookdown HTML successfully
- [ ] Config param controls public vs password-protected mode
- [ ] Password-protected mode deploys to `docs/<password-dir>/`
- [ ] Public mode deploys to `docs/` with standard structure
- [ ] PDF build works in GA (or clear decision to exclude)
- [ ] Template is testable in mybookdown-template itself
- [ ] Downstream repos can adopt the pattern

## Milestones

### Phase 1: Add Configuration Parameters
- [x] Add `password_protected` param to index.Rmd
- [x] Add `password_dir` param to index.Rmd
- [ ] Document params usage

### Phase 2: Create GitHub Actions Workflow
- [x] Create `.github/workflows/bookdown-build.yml`
- [x] Set up R environment (r-lib/actions)
- [x] Conditional build logic based on params
- [x] Deploy to GitHub Pages
- [x] Add renv support for reproducible dependencies
- [ ] Test workflow runs successfully

### Phase 2.5: renv Setup (Added)
- [x] Initialize renv with pak backend
- [x] Install minimal package set for template
- [x] Create renv.lock (150+ packages)
- [x] Clean up scripts/packages.R
- [x] Remove unused packages (readwritesqlite, RPostgres, sf direct, kableExtra fork)
- [x] Update .gitignore for renv
- [x] Update workflow to use renv::restore()

### Phase 3: PDF Build (Decision Required)
- [ ] Research Chrome/pagedown in GA runners
- [ ] Test PDF build in GA
- [ ] Decide: GA PDF vs local PDF vs skip PDF
- [ ] Implement chosen approach

### Phase 4: Testing & Documentation
- [ ] Test public mode with mybookdown-template
- [ ] Test password-protected mode
- [ ] Update README with new workflow
- [ ] Update CLAUDE.md with learnings

## Technical Uncertainties (SRED)

1. **PDF rendering in GA:** Can we reliably run `pagedown::chrome_print()` in GitHub Actions? What Chrome/Chromium setup is needed?

2. **Ghostscript compression:** Is `tools::compactPDF()` with ghostscript available/practical in GA runners?

3. **Parameter access in workflow:** How do we read R params from `index.Rmd` in the shell-level workflow file?

4. **Dual-mode deployment:** Best pattern for single workflow supporting both public and password-protected modes?

## Dependencies

- Existing nrp-nutrient-loading-2025 pattern (reference implementation)
- r-lib/actions for R setup
- GitHub Pages configuration
- **#76 (renv)** - ✅ Done
- **fpr#129** - BLOCKER: Global variable dependencies must be fixed before GA builds work

## Out of Scope

- Migrating existing downstream repos (separate effort)
- Changing password protection mechanism itself
- PDF storage alternatives (S3, releases) - defer unless GA PDF fails

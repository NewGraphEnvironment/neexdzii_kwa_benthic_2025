# Progress Log: Issue #75

## 2026-02-03 - Session Start

### Completed
- [x] Created issue #75 documenting the goal and approach
- [x] Added comment clarifying two deployment patterns (public vs password-protected)
- [x] Decided on config parameter approach (Option A)
- [x] Created branch `75-github-actions-build`
- [x] Initialized planning directory structure
- [x] Created PWF files (task_plan.md, findings.md, progress.md)

### Commits
- `e27e9cd` - Initialize planning directory structure for SRED evidence tracking
- `599da4b` - Add PWF files for issue #75 planning
- `7f07f4c` - Add GitHub Actions workflow and deployment params
- `6a5bb57` - Update planning: #76 renv dependency identified
- `1f23b10` - Add renv for reproducible dependency management
- `d3d11b6` - Update GA workflow to use renv for dependencies

### Current Focus
- Test workflow in GA

### Blockers
None currently.

### Next Steps
1. Push branch and create PR to test workflow
2. Verify renv::restore() works in GA
3. Test public mode build
4. Test password-protected mode
5. Address PDF build (Phase 3)

### Key Accomplishments This Session
- Identified package fragmentation across templates
- Set up renv with pak backend
- Cleaned up packages.R (removed 4 unused packages)
- Created renv.lock with 150+ dependencies
- Updated workflow to use renv caching
- Added system dependencies for sf, magick, rgl
- Created scripts/setup_docs.R for build automation
- Tested password-protected build locally
- **Identified blocker:** fpr#129 - global variable dependencies prevent GA builds

### Blocker
fpr functions use global variables as default args (e.g., `font = font_set`).
Works in RStudio, fails in scripted CI contexts.
Created fpr#129 to fix with getOption() pattern.

---

## Session Notes

### Password Protection Pattern (from nrp-nutrient-loading-2025)
- `docs/index.html` = public dummy page
- `docs/<password-dir>/` = actual report
- "Password" is knowing the subdirectory URL
- Simple, no auth infrastructure needed

### Key Decision
Using config parameter in `index.Rmd` params to control deployment mode. Single template supports both public and password-protected deployments.

---

## 2026-02-04 - Session Complete

### Final Accomplishments
- [x] GA workflow builds and deploys successfully
- [x] RSPM binaries enabled (10x faster builds: 35min → 4min)
- [x] Password-protected deployment working
- [x] docs/ no longer tracked in git
- [x] README and CLAUDE.md updated

### Package Downgrades for RSPM Compatibility
Downgraded to match RSPM available binaries:
- dplyr: 1.2.0 → 1.1.4
- ggplot2: 4.0.2 → 4.0.1
- cpp11: 0.5.3 → 0.5.2
- pkgload: 1.5.0 → 1.4.1

Track upgrades: #78

### Issues Created
- #78 - Track RSPM package upgrades when available
- NewGraphEnvironment/ngr#31 - ngr_rspm_* helper functions

### Build Times
| Before (CRAN source) | After (RSPM binaries) |
|---------------------|----------------------|
| 35+ min | 3-4 min |

### Status
**Issue #75 CLOSED** - GitHub Actions builds working with password-protected deployment.

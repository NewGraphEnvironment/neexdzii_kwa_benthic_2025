# Exec Summary Restructure, Adaptive Monitoring, Password Removal

**Branch:** `16-exec-summary-and-monitoring`
**Issues:** #16, #17, #18 (Phase 1); #19 (Phase 2, PWF-planned)
**Goal:** Restructure exec summary to be headline-first with McQuarrie caveat; reframe BUL-06 as staged Phase 1 test of upstream-mainstem condition; remove security-through-obscurity password gating. Standalone exec summary PDF (#19) planned and scoped here, implemented after Phase 1 lands.

## Phase 1 — Content + flag flip (this branch)

### Milestone 1: Password removal (#18)
- [ ] Flip `password_protected: TRUE` → `FALSE` in `index.Rmd`
- [ ] Verify no other files reference the password_dir hash beyond the `params` entry
- [ ] `setup_docs.R` logic unchanged (boolean gates everything)

### Milestone 2: Exec summary restructure (#16)
- [ ] Draft restructured `0050-executive-summary.Rmd`:
  - Opening paragraph (why bugs + who/what/where) — largely unchanged
  - Lede paragraph: headline gradient finding, WWTP named as plausible driver at BUL-01
  - BUL-05 reference-baseline paragraph with McQuarrie caveat and pointer to BUL-06 as test
  - Temporal paragraph leading with robust directional shift; seasonal variability as reason for continued consistent-timing monitoring
  - Closing paragraph: expansion recommendation with brief hint at scope
- [ ] Keep `<br>` spacers for gitbook rendering; preserve `\@ref(recommendations)` cross-ref
- [ ] Word count ~400 words (no expansion)

### Milestone 3: Adaptive monitoring design (#17)
- [ ] Update BUL-06 rationale in `data/raw/sites_monitoring.csv` to capture dual purpose (Richfield concentrate shed + Phase 1 test of McQuarrie-dilution hypothesis)
- [ ] Discussion `0600-discussion.Rmd`:
  - Replace vague "additional sampling above the McQuarrie confluence" with staged Phase 1/Phase 2 decision rule
  - Acknowledge Phase 1's interpretive limits (neither outcome fully disambiguates; "dirty" is the actionable trigger)
  - Short mention of Mitchell 1997 (McQuarrie as "highly or severely degraded") vs Westcott 2022 (cold-water thermal influence) — tension motivates Phase 2 tributary test

### Milestone 4: Consistency QA
- [ ] Cross-check site numbers, positions, rationales across:
  - `data/raw/sites_monitoring.csv` (source of truth)
  - `0050-executive-summary.Rmd` (site descriptions)
  - `0300-methods.Rmd` (site descriptions)
  - `0600-discussion.Rmd` (site-by-site interpretation)
  - Any proposed-sites tables rendered from the CSV
- [ ] Cross-check metrics cited in exec summary vs results chapters:
  - BUL-01: 24% midges, 20% Hydropsychidae, HBI 4.14
  - BUL-05: 45 taxa, 84% EPT, HBI 2.58, *Lepidostoma* 42%
  - All PERMANOVA / stat claims
- [ ] McQuarrie framing consistent: exec summary caveat ↔ Discussion staged design ↔ sites_monitoring.csv rationale

### Milestone 5: Version bump + build (first round) ✅
- [x] Bump version (0.2.1 → 0.3.0)
- [x] NEWS.md entry
- [x] Build gitbook locally
- [x] User reviewed build — surfaced follow-up items (see Milestone 6+)

### Milestone 6: Widen BUL-01 driver attribution (in #16/#17 scope)

User raised: attributing BUL-01 signal to WWTP alone narrows the causal story and misses the ag/rangeland education opportunity. Fold into current branch:

- [ ] Exec summary — widen BUL-01 attribution from just-WWTP to: agricultural + cattle rangeland through the valley, Knockholt Landfill, and the Houston WWTP (proximate driver for incremental BUL-04 → BUL-01 step-change)
- [ ] Discussion (`0600-discussion.Rmd:57` "Point-source influence" bullet) — similar widening; acknowledge BUL-01 is an integrator, not a point-source attribution

### Milestone 7: HBI ranges + de-emphasize category labels (NEW ISSUE A, in scope for this branch)

User raised: BUL-04 HBI range 2.81–4.57 spans three interpretation categories (Excellent / Very good / Good); reporting mean alone misleads. Also we're citing Hilsenhoff 1987 as secondary via Barbour 1999, and the primary is not locatable (user tried hard). De-emphasize category labels and lean on multi-metric convergence.

- [ ] Create Issue A: "HBI: report range alongside mean; de-emphasize category labels pending primary source" (note unsuccessful attempts to obtain Hilsenhoff 1987)
- [ ] Edits in this branch:
  - Results — report HBI as `mean (min–max)` throughout
  - Exec summary — lead BUL-01 with compositional shift (EPT, Chironomidae, *Hydropsyche*), cite HBI as supporting not headline
  - Discussion — report BUL-04 range explicitly and note within-site variability is part of the story
  - Exec summary and Discussion — use full category name "Very good — possible slight organic pollution" rather than truncating to "possible slight organic pollution"

### Milestone 8: Cross-reference + project-motivation framing (NEW ISSUE B, in scope for this branch)

User raised: this project was not assigned by the client; it was initiated because benthic community data were identified as a limiting gap during restoration planning research. Intro only briefly mentions companion report; motivation is missing.

- [ ] Create Issue B: "Surface project motivation: benthic gap identified during restoration planning"
- [ ] Edits in this branch:
  - Intro — one honest sentence on origin of the work
  - Exec summary — optional brief nod

### Milestone 9: Marine-derived nutrients context (NEW ISSUE C, fold into #17 scope this branch)

User raised: historical salmon returns delivered marine-derived nutrients (MDN); declining salmon means BUL-05's "reference" baseline is lower than historical. "A bit of nutrient enrichment is not necessarily bad on its own" — and anthropogenic enrichment at BUL-01 is partly replacing a lost natural flow but differs in source, form, and co-contaminants.

- [ ] Verify Cederholm et al. 1999 (*Fisheries* 24(10), "Pacific salmon carcasses") and/or Naiman et al. 2002 (*Ecosystems* 5(4)) are in Zotero NewGraphEnvironment library; add if missing
- [ ] Discussion — one short paragraph between the "Point-source influence" bullet and the "Upstream reaches" caveat, acknowledging MDN historical role, salmon decline, and the biogeochemical difference between MDN and anthropogenic enrichment
- [ ] Exec summary — one contextualizing sentence
- [ ] Create Issue C for audit trail; fold implementation into this branch

### Milestone 10: Version re-bump + rebuild after Milestones 6–9 land

- [ ] Update NEWS.md entry with widened attribution + MDN context + HBI ranges + project-origin framing
- [ ] Rebuild gitbook
- [ ] User reviews before PR

### Milestone 11: Commit, push, PR

- [ ] Atomic commits per concern (password, exec summary, monitoring, HBI, MDN, project-motivation — or grouped sensibly)
- [ ] Push branch
- [ ] Open PR with SRED cross-link in PR body (`Relates to NewGraphEnvironment/sred-2025-2026#N`) per workflow preference — not in issues
- [ ] PR closes #16, #17, #18, Issue A, Issue B, Issue C via commit messages

## Phase 2 — Standalone exec summary PDF (#19, PWF-planned)

Separate planning pass after Phase 1 lands. Key questions captured in `findings.md`:
- Content source (child chunk of `0050-executive-summary.Rmd` vs duplicate)
- Pagedown CI integration (Chromium on runner)
- CSS asset porting from `restoration_wedzin_kwa_2024`
- Credit block adaptation (Wet'suwet'en Treaty Society, NGE — not SERN)
- Link from gitbook to PDF

## Out of scope

- Field data entry / photo appendix work — tracked in existing issues #7, #10, #11
- CABIN submission + RCA — tracked in #8
- Single-source-of-truth refactor for site descriptions — tracked in #11

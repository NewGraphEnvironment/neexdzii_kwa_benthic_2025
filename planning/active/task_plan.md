# Report Prose and Content Feedback — Round 2

**Goal:** Address user feedback on report prose, content gaps, and recommendations.
**Status:** Capturing feedback — not yet started.

## Completed (this session, prior to this plan)

- [x] Ordination chapter prose pass: merged island paragraphs, referenced all figs/tables, plain language
- [x] Fixed Clarke & Warwick citation (moved from R string to markdown for rbbt detection)
- [x] Added cross-refs to 0400, 0450, 0600
- [x] Clean build, no warnings

---

## Phase 1: Content additions and edits

### 1a. Executive summary — "first" framing
- Already well-covered in 0050, 0200, 0600 — no action needed

### 1b. Point sources — add Richfield legacy site + mines
- `0200-background.Rmd` line ~21: "Potential point sources..." paragraph
- Add Richfield staging yard / legacy contaminated site (search restoration_wedzin_kwa_2024 for details)
- Add mines — note they are not on the mainstem
- **Action:** Search restoration_wedzin_kwa_2024 repo for "Richfield", "staging", "legacy"

### 1c. Field sampling attribution — DONE
- Added Al Irvine RPBio + Tieasha Pierre, dates Sep 28 – Oct 3, 2025

### 1d. Water quality — restate Remington & Donas sources — DONE
- Added: glacial-fluvial/lacustrine soils, agriculture, septic, livestock

### 1e. Community Composition intro — DONE
- Added plain language paragraph: what bugs tell us about stream health

### 1f. Temporal comparison — explain phenology — DONE
- Explained: later season = larger larvae, more mature communities, easier ID, more representative

### 1g. Ordination chapter intro — DONE
- Added: why multivariate analysis matters, what it shows that single metrics can't

### 1h. Discussion intro — DONE
- Added framing paragraph before ## Site Gradient

---

## Phase 2: Discussion and Recommendations rework

### 2a. BUL-05 uncertainty — McQuarrie Creek influence
- BUL-05 is just below McQuarrie confluence — a cold-water, less-developed tributary
- Question: does McQuarrie's input create locally excellent conditions not representative of upstream mainstem?
- **Action:** Find hydrometric data for McQuarrie Creek + Bulkley at Houston (ECCC stations)
- Estimate % freshwater contribution from McQuarrie
- Add uncertainty caveat to discussion + recommendation for upstream sampling

### 2b. Remove "Incorporate field habitat data" recommendation
- This is about to happen — don't recommend what we're doing
- Create GitHub issue instead for how habitat data will interleave with existing analysis

### 2c. CABIN RCA — make an issue, not a recommendation
- Whether we recommend running RCA depends on email response Monday (contact ECCC)
- For now: create issue, remove from recommendations or soften to conditional

### 2d. Water quality coordination — plainer language
- "Concurrent benthic and water quality sampling would enable direct correlation..." — too jargony
- Say what should actually happen: collect water samples at the same time as bug samples so we can directly link nutrient levels to community health

### 2e. Extend sampling program — new recommendation
- Buck Creek sites including near the mine — understand aquatic health there
- Upstream Bulkley mainstem reaches beyond BUL-05
- Maxhamish (Maxxam?) Creek
- Key tributaries like Richfield Creek — historic chinook use, restoration could use guidance/context
- Frame as expanding the monitoring network to capture the full watershed gradient

---

## Phase 3: Issues to create

- [ ] Habitat data integration — how envfit/indicspecies interleaves with current report structure
- [ ] CABIN RCA assessment — conditional on ECCC contact response
- [ ] Richfield Creek / expanded monitoring network — future sampling design

---

## Research needed

| Topic | Source | Status |
|-------|--------|--------|
| Richfield legacy site details | restoration_wedzin_kwa_2024 repo | pending |
| McQuarrie Creek hydrometric station | ECCC, fwapg | pending |
| Bulkley River flow at Houston (08EE003) | ECCC | have station ID |
| McQuarrie watershed area vs Bulkley | FWA/fwapg | pending |
| Sampling dates (Oct 2025) | benthic_counts_tidy.csv | **done** — Sep 28, Oct 2–3 |
| Maxxam Creek — correct spelling | restoration_wedzin_kwa_2024 | pending |

# Findings — Exec Summary, Adaptive Monitoring, Password Removal

## Password protection (#18)

Security-through-obscurity, not real auth:
- `password_protected: TRUE` + `password_dir: '68d57a8c…'` in `index.Rmd` params
- `scripts/setup_docs.R` renders bookdown to `docs/<hash>/` when flag true, else `docs/` root
- `password_protect/index.html` is a decoy landing page copied to `docs/index.html`
- Anyone with the hash URL gets the report — no password ever asked

**Safe to flip:**
- `docs/` is gitignored (verified — zero files tracked under `docs/`)
- Workflow uses `actions/deploy-pages@v4` (artifact-based, not `gh-pages` branch)
- Fresh checkout each run → old hash folder never lands on runner
- `deploy-pages` replaces previous artifact entirely → old hash URL dies on next deploy

Infrastructure stays in place (reusable pattern for other projects). Only the boolean flips.

## McQuarrie Creek ambiguity (#16, #17)

**In-report state (pre-change):**
- Methods (`0300-methods.Rmd:31`): McQuarrie as "recognized cold-water tributary" citing Westcott 2022 paired temperature loggers
- Discussion (`0600-discussion.Rmd:58`): caveat already present — "The cold, clean input from McQuarrie may create locally favourable conditions at BUL-05 that are not representative of the entire upstream mainstem. Additional sampling above the McQuarrie confluence would clarify…"
- Background (`0200-background.Rmd:21`): Mitchell 1997 lists McQuarrie alongside Richfield and Byman Creeks as "highly or severely degraded" from agricultural/municipal/transportation impacts
- Exec summary: silent on the caveat — BUL-05 framed confidently as reference

**Westcott vs Mitchell:**
Not necessarily contradictory — a creek can be thermally beneficial (cold input) AND nutrient-enriched (from agriculture). But the report doesn't surface this tension, which is what motivates a Phase 2 tributary test if Phase 1 shows BUL-06 dirty.

## BUL-06 as staged Phase 1 test (#17)

Site positions from `data/raw/sites_monitoring.csv` (DRM = distance from mouth):

| Site | DRM (m) | Status | Current rationale |
|------|---------|--------|-------------------|
| BUL-01 | 169,137 | Existing | Urban/nutrient near Houston |
| BUL-04 | 188,491 | Existing | Mid-reach, Knockholt Landfill |
| BUL-05 | 206,127 | Existing | Below McQuarrie confluence |
| **BUL-06** | **217,534** | **Proposed** | **Downstream of Richfield concentrate shed** |

BUL-06 sits ~11 km upstream of BUL-05, above McQuarrie confluence. Its position happens to test the McQuarrie-dilution hypothesis as a side benefit — but the rationale doesn't say so.

**Phase 1 decision rule:**
- BUL-06 clean → upstream mainstem genuinely clean; BUL-05 reference interpretation strengthens; current network sufficient
- BUL-06 dirty → cannot distinguish McQuarrie dilution from natural in-stream recovery between BUL-06 and BUL-05; trigger Phase 2 (add site immediately above McQuarrie + McQuarrie tributary site)

**Interpretive limits:**
Neither Phase 1 outcome fully disambiguates — BUL-06 clean could still hide downstream re-enrichment + McQuarrie cleanup; BUL-06 dirty could still resolve itself via in-stream processes. But "dirty" is the outcome that makes further investigation actionable and cost-justified.

## Exec summary key metrics (for consistency QA)

From current exec summary and results chapters — values to preserve in restructured version:

- **BUL-01:** 24% midges (Chironomidae), 20% net-spinning caddisflies (Hydropsychidae), HBI 4.14
- **BUL-04:** transitional zone (individual samples range from near-reference to moderately impaired)
- **BUL-05:** 45 taxa, 84% EPT, *Lepidostoma* 42% dominance, HBI 2.58
- **Temporal at BUL-01:** 2004, 2018, 2025 samples show directional shift — fewer mayflies, more midges/Hydropsychidae over time; sampling season varied Aug–Oct across years
- **PERMANOVA:** confirms three sites support genuinely different communities

All these should be verified against the results chapters during QA.

## Standalone exec summary PDF (#19) — reference

`restoration_wedzin_kwa_2024/_executive_summary_pdf.Rmd`:
- Leading underscore so bookdown doesn't auto-include it
- `output: pagedown::html_paged` + CSS: `default-fonts`, `default-page`, `default`, `style-pagedown.css`
- Version via `desc::desc_get_version()`
- Credit block (SERN-specific; will need Wet'suwet'en/NGE adaptation for this report)
- Links: full report, source code, changelog, latest PDF
- Served at `docs/executive_summary.pdf`

**Deploy mechanism divergence:** RWK2024 builds locally/Travis-style (`_build.sh`, `_deploy.sh`); this repo uses GitHub Actions. Phase 2 planning (`#19`) must figure out how to add a pagedown render step to `.github/workflows/bookdown-build.yml` — Chromium availability on runner is likely the main unknown.

**Dependency:** #19 should land after #16 restructure so the standalone PDF uses the new exec summary content (not the old version).

## Additional threads surfaced during first-round review (2026-04-22)

### BUL-01 driver attribution is narrower than the watershed reality

Flow: BUL-05 → BUL-04 → BUL-01. Upstream of BUL-01 there is:
- McQuarrie Creek (ag/municipal impacts per Mitchell 1997)
- Agricultural valley (Highway 16 corridor, noted in `0100-intro.Rmd:10`)
- Cattle rangeland (Remington 2000 names "nitrogen loading linked to agriculture, septic systems, and livestock" in `0200-background.Rmd:17`)
- Knockholt Landfill (between BUL-04 and BUL-01, listed as point source in `0200-background.Rmd:21`)
- Houston urban + WWTP outfall (500 m upstream of BUL-01)

The incremental BUL-04 → BUL-01 step-change is dominantly Houston + WWTP. But writing "WWTP as the plausible driver" at BUL-01 narrows the causal story. Honest framing: BUL-01 integrates the whole upstream watershed; WWTP is the proximate incremental driver.

Forestry *not* included in the BUL-01 attribution: its impacts are primarily sediment, temperature, and hydrograph — not the nutrient/organic signal HBI and compositional metrics detect. Forestry belongs in the broader monitoring design (MAX-01) but not the BUL-01 attribution.

### HBI — the mean hides the range at BUL-04

From `data/processed/metrics_long.csv`:

| Site | Replicates | Mean | Categories spanned |
|------|------------|------|--------------------|
| BUL-01 | 3.91, 4.19, 4.31 | 4.14 | Very good only |
| **BUL-04** | **2.81, 3.14, 4.57** | **3.51** | **Excellent → Very good → Good** |
| BUL-05 | 2.40, 2.61, 2.72 | 2.58 | Excellent only |

Reporting BUL-04 mean (3.51) as a single category conceals that replicates span three categories — which is itself a finding (transitional zone). Report `mean (min–max)` throughout.

### Hilsenhoff 1987 primary source — unobtainable

- Cited secondary via Barbour 1999 (`0400-results.Rmd:231`: "Hilsenhoff (1987; as cited in @barbour_etal1999Rapidbioassessment)")
- Hilsenhoff 1987, *Great Lakes Entomologist* 20(1):31–39 — not in Zotero, user tried hard to obtain
- Per references convention: secondary citation is legitimate if flagged; don't pretend to verify at source
- Shift weight in prose from HBI category labels to multi-metric convergent story

### Multi-metric convergence — the real story is not HBI-anchored

All metrics independently point the same direction (BUL-01 enriched → BUL-05 reference):

| Metric | BUL-01 | BUL-05 |
|--------|--------|--------|
| % EPT | 63% | 84% |
| % Chironomidae | 24% | 3% |
| % Oligochaeta | 7% | <1% |
| *Hydropsyche* dominance | 20% | low |
| % Shredders | 2% | 42% |
| % Collector-filterers | 31% | lower |
| Taxonomic richness | 37 | 45 |
| EPT richness | 17 | 24 |
| HBI mean | 4.14 | 2.58 |

External validation:
- Total phosphorus (EMS historical) elevated in BUL-01 reach
- Periphyton biomass 145 mg/m² chl-a near Houston (Remington 2000)
- PERMANOVA confirms statistical separation
- NMDS ordination visual separation

Narrative: HBI is one line of evidence among many — not the anchor.

### Project motivation — genesis not documented

This project was not assigned by the client. It was initiated by NGE because benthic community data were identified as a limiting information gap during restoration planning research (`restoration_wedzin_kwa_2024`). `0100-intro.Rmd:18` mentions companion relationship in one sentence but does not explain why this standalone benthic assessment exists independently of an assigned client scope.

Honest framing: one sentence in intro (optionally echoed in exec summary). No over-explanation.

### Marine-derived nutrients — missing ecological context

Pacific salmon returning to spawn and die historically delivered significant ocean-derived N and P to Skeena tributaries (canonical: Cederholm et al. 1999, Naiman et al. 2002). Upper Bulkley chinook and sockeye populations have declined substantially. BUL-05's "excellent" condition reflects a lower nutrient baseline than existed when salmon carcasses were a major annual input.

Implications for report framing:
- "Reference" at BUL-05 is valid for current condition but lower than historical baseline
- BUL-01's mild enrichment is not simply additive to a pristine reference — partly *replacing* a natural nutrient flow that has diminished
- BUT: source and form matter. MDN is labile, pulsed with the fall run, coupled to organic matter and aquatic-terrestrial linkages via scavengers. WWTP/ag N and P is chronic, dominated by different N species (ammonia, nitrate), and carries co-contaminants (pharmaceuticals, pesticides, pathogens). Not a simple substitution.
- Existing Discussion at `0600-discussion.Rmd:57` already uses "nutrient subsidy" phrase — natural hook for MDN context.

Existing in Zotero bib: Gottesfeld & Rabnett 2007/2008 (historical Skeena salmon). Need to check / add: Cederholm et al. 1999 (*Fisheries* 24(10)) as the canonical MDN citation.

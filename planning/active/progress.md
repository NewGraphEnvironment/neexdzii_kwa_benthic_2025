# Progress — Exec Summary, Adaptive Monitoring, Password Removal

## 2026-04-22

### Session start
- Previous `planning/active/` archived to `planning/archive/2026-03-report-prose-round-2/` (work from March largely shipped)
- Branch `16-exec-summary-and-monitoring` created from clean main (after committing pending CABIN habitat.csv + pebble work in `a3811a4`)
- Issues #16, #17, #18, #19 created as self-contained prompts
- Fresh PWF set up (task_plan.md, findings.md, progress.md)

### Progress
- [x] Milestone 1: flipped `password_protected: FALSE` (#18)
- [x] Milestone 2: restructured `0050-executive-summary.Rmd` (#16)
  - Headline gradient paragraph with WWTP named as plausible driver
  - BUL-05 reference-baseline paragraph with McQuarrie caveat + BUL-06 Phase 1 test pointer
  - Temporal paragraph lead-with-robust reframe
  - Closing paragraph with specific expansion scope
  - Fixed precision: *Hydropsyche* 20% (genus) not Hydropsychidae 20% (family is 27%)
- [x] Milestone 3 (#17):
  - BUL-06 rationale in `sites_monitoring.csv` now captures dual purpose (Richfield concentrate shed + Phase 1 McQuarrie-dilution test)
  - Discussion BUL-05 caveat rewritten with Westcott 2022 vs Mitchell 1997 tension surfaced and staged Phase 1/Phase 2 decision rule
- [x] Milestone 4: consistency QA
  - Metrics cross-checked (BUL-01 Chironomidae 24%, Hydropsyche 20%; BUL-05 45 taxa, 84% EPT, Lepidostoma 42%; HBI 4.14 / 2.58) — match Results 0400
  - Temporal claim verified against Discussion 0600:41-49 (2004/2018/2025 timing, Aug–Oct)
  - Expansion scope (Buck, Maxan, upstream mainstem above McQuarrie) verified against sites_monitoring.csv
  - Westcott 2022 + Mitchell 1997 both pre-exist in bibliography (methods + background)
- [x] Milestone 5 — version + NEWS
  - Bumped `DESCRIPTION` 0.2.1 → 0.3.0
  - Added NEWS entry (client-facing wording)

### First-round build complete (2026-04-22)
- Gitbook built successfully (173 chunks, 21 HTML pages in `docs/`)
- User reviewed — several follow-up items surfaced; all captured in task_plan.md Milestones 6–11 and findings.md "Additional threads"

### Follow-up queue

- [x] File new issues (#20, #21, #22) for audit trail
- [x] Issues #16-21 edited to remove client-damaging/self-justifying language; memory saved; soul comms thread opened
- [x] Milestone 6 — BUL-01 attribution widened in exec summary + Discussion (17 line-new 'Cumulative upstream pressure' bullet; 'BUL-01 integrates' paragraph in gradient section)
- [x] Milestone 7 — HBI as mean (range) in Results/Exec/Discussion; full "Very good — possible slight" label; BUL-04 range spans three categories acknowledged
- [x] Milestone 8 — one sentence in Intro + one in Exec summary linking to restoration planning data-gap origin
- [x] Milestone 9 — MDN context paragraph added to Discussion (gottesfeld_rabnett2008SkeenaFish cited; Cederholm 1999 and Naiman 2002 flagged as desired additions but not in Zotero yet); one sentence in Exec summary
- [x] NEWS.md updated with M6–M9 additions
- [ ] Rebuild gitbook for second user review
- [ ] Commit per concern, push, open PR with SRED xref on PR body

### Outstanding / deferred

- **Cederholm 1999 / Naiman 2002 in Zotero** — referenced in soul/comms thread and in findings.md; MDN paragraph cites Gottesfeld 2008 for salmon historical context. Primary MDN mechanism citation is a gap; can upgrade when references land in Zotero.
- **Issue #19** — standalone exec summary PDF (Phase 2, needs own PWF pass after this lands)
- **soul comms thread** — `soul/comms/neexdzii_kwa_benthic_2025/20260422_client_visible_tone_convention.md` status `open` — awaiting soul-Claude response

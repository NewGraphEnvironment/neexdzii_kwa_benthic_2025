## Outcome

Shipped as v0.3.2 (commit 214896b, tag v0.3.2, 2026-04-23).

Closed #19. Standalone Executive Summary PDF now served at https://www.newgraphenvironment.com/neexdzii_kwa_benthic_2025/executive_summary.pdf and linked from the gitbook exec summary chapter.

## Design decisions that survived

- **Local build + commit + Actions-copy** (not Actions-native rendering). Avoids the Chromium-on-Actions rabbit hole. Release-time step: `Rscript scripts/build_exec_pdf.R` → commit PDF → push. Same mental model as NEWS.md or the version bump.
- **Child-include of `0050-executive-summary.Rmd`** with a preprocessing step to rewrite `\@ref(recommendations)` (which only resolves in full-book context) into an absolute URL to the deployed report.
- **Inline URL link instead of `[@...]` citation** in the exec summary chapter (for `@irvine_schick2026NeexdziiKwah` — the companion report). Eliminates the need for a References section in a short standalone document. Intro keeps both the inline link and the citation form.
- **Standardized link label** — "Executive Summary (PDF)" in both gitbook and PDF footer.
- **Dropped References section from the standalone PDF** — no `citeproc`, no `bibliography`, no `# References {-}`. Short exec summary doesn't warrant it.

## Gotchas discovered

- `_output.yml`'s `pagedown::html_paged:` stanza leaks defaults (`front_cover`, `toc`) into the standalone render unless overridden in the Rmd's own YAML. First build shipped with an NGE logo cover page and a TOC before this was caught.
- Bookdown's `\@ref(anchor)` cross-references don't resolve in standalone pagedown renders — preprocessing in `build_exec_pdf.R` handles this.
- pagedown's `self_contained: true` embeds images as base64, which made auditing image content via the HTML intermediate indirect — had to `pdfimages -all` the rendered PDF to find the stray NGE logo.

## Phase B — mybookdown-template port

Captured in an inline comment on [NewGraphEnvironment/mybookdown-template#90](https://github.com/NewGraphEnvironment/mybookdown-template/issues/90) with concrete file references and the gotchas above. Urgency: several fish passage reports due within ~2 weeks will want this pattern out of the box.

## Phase C — fish_passage_template_reporting port

Downstream of Phase B. That template builds locally (no Actions workflow), so the "CI copy" step from Phase A isn't needed there.

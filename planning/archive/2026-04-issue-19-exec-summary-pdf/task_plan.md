# Standalone Executive Summary PDF (Issue #19)

**Goal:** Produce a standalone executive summary PDF for this report matching the pattern established in `restoration_wedzin_kwa_2024`, integrated into the GitHub Actions CI/deploy pipeline, with portability to `mybookdown-template` (and later `fish_passage_template_reporting`) as a first-class design constraint.

**Status:** Pass 1 (research + design) — no code edits in this repo until research questions resolved and design is scoped.

## Propagation order (agreed with user, 2026-04-23)

1. **Phase A — this repo.** Implement, CI-integrate, deploy, iterate to robust.
2. **Phase B — mybookdown-template.** Port the proven pattern so new bookdown repos inherit it.
3. **Phase C — fish_passage_template_reporting.** Adapt for fish-passage template (has project-specific extensions).

Template-first is the wrong order — risks embedding immature patterns.

## Pass 1 research questions (to answer before code)

Each of these needs an answer before implementation planning:

1. **RWK2024 artifact audit.**
   - Inspect `_executive_summary_pdf.Rmd` in detail — what chunks, YAML, CSS, front-matter blocks?
   - List all CSS files referenced (`default-fonts`, `default-page`, `default`, `style-pagedown.css`)
   - Identify which assets exist in RWK2024 and which are in default R packages (pagedown's shipped CSS)
   - Document RWK2024 build mechanism (Travis / `_build.sh`) vs. what CI integration we need here

2. **Pagedown + CI compatibility.**
   - Does pagedown's `html_paged` require Chromium on the runner?
   - Answer: almost certainly yes (pagedown uses `chrome_print` which drives headless Chrome). Confirm.
   - What system dependencies does ubuntu-latest need? (Likely `chromium-browser` apt package plus environment setup)
   - Is there a cleaner alternative (weasyprint, wkhtmltopdf) with fewer dependencies? Evaluate trade-offs.
   - Will the existing `r-lib/actions/setup-r` workflow step handle this, or do we need explicit Chromium install?

3. **Content source strategy.**
   - Child-include `0050-executive-summary.Rmd` via `child:` chunk (single-source, no drift) vs. duplicate content (drift risk but simpler).
   - Does pagedown's front matter tolerate a bookdown-chapter child include cleanly?
   - If child-include breaks, is there a scripted extract pattern (e.g., pandoc AST manipulation)?

4. **Credit block and logo for this report.**
   - RWK2024 credit: "Prepared for the Wet'suwet'en Treaty Office Society / Prepared by Al Irvine, R.P.Bio — New Graph Environment Ltd. / on behalf of the Society for Ecosystem Restoration in Northern British Columbia"
   - This report: mirror structure, use same SERN logo (`fig/logo_sern/SERNbc-Logo-FULL.jpg`) we just added.
   - Footer links: Full report URL, source code, changelog, latest PDF — all parameterized from `index.Rmd` params? (yes, same pattern as RWK2024)

5. **Versioning consistency.**
   - RWK2024 pulls via `desc::desc_get_version()` — does our DESCRIPTION already support this? (Yes, we've been using it in the main index.Rmd.)
   - Reproduce the same approach so the standalone PDF always matches the main report version.

6. **Discoverability — where does the PDF link from the gitbook?**
   - Options: title block; top of exec summary chapter; nav sidebar; footer.
   - RWK2024 pattern: checks.

7. **Portability hooks.**
   - What pieces are project-specific vs. reusable?
   - Reusable: CSS, Rmd scaffold, workflow render step, gitbook link pattern, versioning hook
   - Project-specific: credit block content, logo choice, title, report URL
   - Design so the reusable pieces can be cleanly copied into mybookdown-template with parameterization (YAML `params` for credit block?).

## Pass 2 (implementation in this repo, after Pass 1 design reviewed)

- [ ] Create `_executive_summary_pdf.Rmd` adapted from RWK2024
- [ ] Port CSS assets (`default-fonts.css`, `style-pagedown.css` etc.)
- [ ] Adapt credit block for this report (SERN credit mirrors what we just added to main title)
- [ ] Test local build (`rmarkdown::render()` with pagedown output)
- [ ] Verify PDF renders correctly with embedded fonts, figures, citations
- [ ] Add gitbook nav / page link to the PDF
- [ ] Version bump (patch or minor — TBD based on scope when shipping)

## Pass 3 (CI integration)

- [ ] Add pagedown render step to `.github/workflows/bookdown-build.yml`
- [ ] Install Chromium (or alternative) in workflow
- [ ] Verify artifact uploads `docs/executive_summary.pdf` alongside main gitbook
- [ ] Test deploy end-to-end

## Pass 4 (portability — mybookdown-template)

Only after Pass 3 is shipped and stable in this repo:

- [ ] Port CSS assets to `mybookdown-template/fig/` (or wherever assets live)
- [ ] Add template `_executive_summary_pdf.Rmd` with parameterized credit block
- [ ] Add documented GitHub Actions fragment for the render step
- [ ] Update `mybookdown-template/CLAUDE.md` or README
- [ ] Document in `soul/conventions/bookdown.md` so all repos' CLAUDE.md pick up the pattern via `/claude-md-init`

## Pass 5 (portability — fish_passage_template_reporting)

Only after Pass 4:

- [ ] Apply the same pattern, accounting for fish-passage-template's project-specific extensions
- [ ] Reconcile with any existing executive summary structure in fish passage reports

## Out of scope

- Field data / CABIN submission (issues #7, #8, #10, #11)
- Any changes to the six just-shipped concerns (issues #16–#22)

## Dependencies and blockers

- Pass 1 outputs gate Pass 2 (can't implement without knowing content-source and CI design)
- Pass 2 complete in local dev gates Pass 3 (CI)
- Pass 3 shipped and stable gates Pass 4 (template)
- Pass 4 stable gates Pass 5 (fish passage)

## Known uncertainties (take-with-grain-of-salt items from user)

User noted they "forget how it all works" — items to verify rather than trust:

- How RWK2024's build mechanism translates to GitHub Actions (RWK2024 uses Travis, older pattern)
- Whether pagedown renders reliably in headless CI without login-session quirks
- Whether existing `fig/logo_sern/` assets render at PDF-quality resolution (may need re-export)

## Success criteria for v1

- [ ] Standalone `docs/executive_summary.pdf` auto-builds and deploys with every push to main
- [ ] PDF matches RWK2024 format visually (SERN logo, credit block, footer links)
- [ ] PDF version string matches main report version (no drift)
- [ ] Gitbook links to the PDF prominently
- [ ] Pattern documented clearly enough that porting to mybookdown-template is a copy-paste-and-parameterize exercise, not a re-architecture

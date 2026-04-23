#!/usr/bin/env Rscript
# Build the standalone executive summary PDF via pagedown.
#
# Renders _executive_summary_pdf.Rmd (child-includes a preprocessed copy of
# 0050-executive-summary.Rmd) and writes pdf/executive_summary.pdf. The CI
# workflow copies this file into docs/ at build time so the PDF is served
# alongside the gitbook.
#
# Usage: Rscript scripts/build_exec_pdf.R
#
# Prereqs:
#   - pagedown installed (uses headless Chrome via chrome_print)
#   - references.bib up to date (run main build with update_bib=TRUE if stale)

if (!requireNamespace("pagedown", quietly = TRUE)) {
  stop("pagedown is required. Install with: pak::pak('pagedown')")
}

dir.create("pdf", showWarnings = FALSE)

# Preprocess the exec summary to resolve bookdown \@ref() cross-references
# that only work in the full-book context. Cross-refs resolve at the URL of
# the deployed report so PDF readers can still follow them.
report_url <- "https://www.newgraphenvironment.com/neexdzii_kwa_benthic_2025"
exec_lines <- readLines("0050-executive-summary.Rmd")
exec_lines <- gsub(
  "Section \\\\@ref\\(recommendations\\)",
  sprintf(
    "the [Recommendations section](%s/discussion-and-recommendations.html#recommendations) of the full report",
    report_url
  ),
  exec_lines
)
# Strip the gitbook-only PDF-download link (the PDF shouldn't link to itself)
exec_lines <- exec_lines[!grepl("executive_summary.pdf", exec_lines, fixed = TRUE)]
writeLines(exec_lines, "pdf/_exec_summary_child.Rmd")

# Render the paged HTML intermediate
html_file <- rmarkdown::render(
  input         = "_executive_summary_pdf.Rmd",
  output_format = "pagedown::html_paged",
  output_dir    = "pdf",
  output_file   = "executive_summary.html",
  quiet         = TRUE
)

# Convert paged HTML -> PDF via headless Chrome
pagedown::chrome_print(
  input  = html_file,
  output = "pdf/executive_summary.pdf",
  wait   = 2
)

# Clean intermediates; keep only the PDF
unlink("pdf/_exec_summary_child.Rmd")
unlink("pdf/executive_summary.html")

message("Wrote: pdf/executive_summary.pdf")

#!/usr/bin/env Rscript
# Setup docs directory for bookdown builds
#
# Usage: Rscript scripts/setup_docs.R <target> [output_dir]
#
# Targets:
#   clean              - Remove docs contents (keeps .nojekyll if present)
#   password           - Copy password_protect/ landing page to docs/
#   build [output_dir] - Build bookdown (reads output_dir from params if not provided)
#
# Examples:
#   Rscript scripts/setup_docs.R clean
#   Rscript scripts/setup_docs.R password
#   Rscript scripts/setup_docs.R build
#   Rscript scripts/setup_docs.R build docs/my_secret_dir

args <- commandArgs(trailingOnly = TRUE)
target <- if (length(args) >= 1) args[1] else "help"
cli_output_dir <- if (length(args) >= 2) args[2] else NULL

# Read params from index.Rmd YAML (only call when needed, not before render)
get_params <- function() {
  lines <- readLines("index.Rmd", n = 100)
  yaml_markers <- grep("^---\\s*$", lines)
  if (length(yaml_markers) < 2) stop("Could not find YAML header in index.Rmd")
  yaml_start <- yaml_markers[1] + 1
  yaml_end <- yaml_markers[2] - 1
  yaml_text <- paste(lines[yaml_start:yaml_end], collapse = "\n")
  yaml_content <- yaml::yaml.load(yaml_text)
  yaml_content$params
}

# Target: clean
docs_clean <- function() {
  message("Cleaning docs/...")
  nojekyll <- file.exists("docs/.nojekyll")
  unlink("docs", recursive = TRUE)
  dir.create("docs", showWarnings = FALSE)
  if (nojekyll) file.create("docs/.nojekyll")
  message("docs/ cleaned")
}

# Target: password
docs_password <- function() {
  if (!dir.exists("password_protect")) {
    message("No password_protect/ directory, skipping")
    return(invisible())
  }

  message("Setting up password-protected landing page...")
  dir.create("docs", showWarnings = FALSE)

  files <- list.files("password_protect", full.names = TRUE, recursive = TRUE)
  for (f in files) {
    dest <- file.path("docs", sub("^password_protect/", "", f))
    dir.create(dirname(dest), showWarnings = FALSE, recursive = TRUE)
    file.copy(f, dest, overwrite = TRUE)
  }
  message("Landing page copied to docs/")
}

# Target: build
docs_build <- function(output_dir = NULL) {
  # Determine output directory
  if (is.null(output_dir)) {
    # Read from params only if not provided via CLI
    p <- get_params()
    if (isTRUE(p$password_protected) && nchar(p$password_dir %||% "") > 0) {
      output_dir <- file.path("docs", p$password_dir)
      # Setup landing page
      docs_password()
    } else {
      output_dir <- "docs"
    }
    # Clean up before render to avoid knitr env collision
    rm(p)
  }

  message("Building bookdown to: ", output_dir)

  # Build - let bookdown read params fresh from YAML
  bookdown::render_book("index.Rmd", output_dir = output_dir)

  message("Build complete!")
}

# Dispatch
switch(target,
  "clean" = docs_clean(),
  "password" = docs_password(),
  "build" = docs_build(cli_output_dir),
  "help" = {
    message("Usage: Rscript scripts/setup_docs.R <target> [output_dir]")
    message("Targets: clean, password, build")
  },
  {
    message("Unknown target: ", target)
    quit(status = 1)
  }
)

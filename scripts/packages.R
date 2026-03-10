# install pak if you don't have it already
if (!requireNamespace("pak", quietly = TRUE)) {
  install.packages("pak")
}

# --- Packages needed for bookdown render ---
pkgs_render <- c(
  "bookdown",
  "knitr",
  "rmarkdown",
  "desc",
  "DT",
  "htmlwidgets",
  "glue",
  "fs",
  "stringr",
  "kableExtra",
  "leaflet",
  "sf"
)

# --- Packages needed for analysis scripts (not required for render) ---
pkgs_analysis <- c(
  "tidyverse",
  "readxl",
  "janitor",
  "vegan",
  "indicspecies",
  "taxize",
  "RVAideMemoire"
)

pkgs_cran <- c(pkgs_render, pkgs_analysis)

# list github packages
pkgs_gh <- character(0)

pkgs_all <- c(pkgs_cran, pkgs_gh)

# Install missing packages
for (pkg in pkgs_cran) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    pak::pkg_install(pkg, ask = FALSE)
  }
}

if(exists("params") && isTRUE(params$update_packages)){
  for (pkg in pkgs_all) {
      pak::pkg_install(pkg, ask = FALSE)
  }
}

# load all installed packages (skip missing analysis packages gracefully)
pkgs_ld <- c(pkgs_cran, basename(pkgs_gh))

lapply(pkgs_ld,
       require,
       character.only = TRUE)

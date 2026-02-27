# install pak if you don't have it already
if (!requireNamespace("pak", quietly = TRUE)) {
  install.packages("pak")
}

# list of packages to install
pkgs_cran <- c(
  "bookdown",
  "knitr",
  "rmarkdown",
  "tidyverse",
  "DT",
  "htmlwidgets",
  "glue",
  "desc",
  "devtools"
)

# loop through the list of packages and install them
for (pkg in pkgs_cran) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    pak::pkg_install(pkg, ask = FALSE)
  }
}

# list github packages
pkgs_gh <- character(0)

pkgs_all <- c(pkgs_cran,
              pkgs_gh)

if(exists("params") && isTRUE(params$update_packages)){
  for (pkg in pkgs_all) {
      pak::pkg_install(pkg, ask = FALSE)
  }
}

# load all the packages
pkgs_ld <- c(pkgs_cran,
             basename(pkgs_gh))

lapply(pkgs_ld,
       require,
       character.only = TRUE)

# Shared paths and parameters for benthic analysis
# Sourced from index.Rmd after packages.R, functions.R, staticimports.R

# ---- Paths ----
path_data_raw <- "data/raw"
path_data_processed <- "data/processed"

# ---- Create directories ----
fs::dir_create(path_data_raw)
fs::dir_create(path_data_processed)

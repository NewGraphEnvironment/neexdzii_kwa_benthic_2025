# Download and extract CABIN open data for the Bulkley watershed
#
# Source: ECCC Open Data Portal — Pacific Drainage Area (MDA 08)
# https://open.canada.ca/data/en/dataset/13564ca4-e330-40a5-9521-bfb1be767147
#
# Output: data/raw/cabin_study_mda08.csv     — study/site metadata (all Pacific)
#         data/raw/cabin_benthic_mda08.csv   — benthic invertebrate data (all Pacific)
#         data/processed/cabin_opendata_sites_bulkley.csv — BUL sites with coords
#         data/processed/cabin_opendata_benthic_bul01.csv — BUL01 benthic records

# STEP 1 - Setup ---------------------------------------------------------------

library(tidyverse)

raw_dir <- "data/raw"
out_dir <- "data/processed"
fs::dir_create(raw_dir)
fs::dir_create(out_dir)

base_url <- "https://cabin-rcba.ec.gc.ca/Cabin/opendata"

# STEP 2 - Download Pacific MDA 08 CSVs ---------------------------------------

study_file  <- file.path(raw_dir, "cabin_study_mda08.csv")
benthic_file <- file.path(raw_dir, "cabin_benthic_mda08.csv")

if (!file.exists(study_file)) {
  download.file(
    paste0(base_url, "/cabin_study_data_mda08_1987-present.csv"),
    study_file, mode = "wb"
  )
  cat("Downloaded", study_file, "\n")
} else {
  cat("Using cached", study_file, "\n")
}

if (!file.exists(benthic_file)) {
  download.file(
    paste0(base_url, "/cabin_benthic_data_mda08_1987-present.csv"),
    benthic_file, mode = "wb"
  )
  cat("Downloaded", benthic_file, "\n")
} else {
  cat("Using cached", benthic_file, "\n")
}

# STEP 3 - Read study data (UTF-16LE encoded) ---------------------------------

study <- read_csv(study_file, show_col_types = FALSE,
                  locale = locale(encoding = "UTF-16LE"))

# Clean bilingual column names — keep English only
names(study) <- str_remove(names(study), "/.*$")

cat("Study data:", nrow(study), "rows,", n_distinct(study$Site), "unique site codes\n")

# STEP 4 - Filter Bulkley basin sites -----------------------------------------

# BUL site codes are shared across studies (e.g. BUL01 = Little Joe Ck in Bulkley
# AND North Galbraith Creek in Bull River/Kootenays). Filter by study.
bulkley_study <- "BC MOE-FSP Skeena Region"

bulkley_sites <- study |>
  filter(
    str_detect(Site, "^BUL"),
    Study == bulkley_study
  ) |>
  distinct(Site, SiteName, LocalBasinName, Latitude, Longitude, StreamOrder,
           AlternateSiteCode) |>
  arrange(Site)

cat("\nBulkley CABIN sites:", nrow(bulkley_sites), "\n")
print(bulkley_sites, n = 60)

# Visit history per site
visit_summary <- study |>
  filter(str_detect(Site, "^BUL"), Study == bulkley_study) |>
  group_by(Site, SiteName) |>
  summarise(
    n_visits = n(),
    years = paste(sort(unique(Year)), collapse = ", "),
    .groups = "drop"
  ) |>
  arrange(Site)

cat("\nVisit history:\n")
print(visit_summary, n = 60)

write_csv(bulkley_sites, file.path(out_dir, "cabin_opendata_sites_bulkley.csv"))
cat("\nWrote", file.path(out_dir, "cabin_opendata_sites_bulkley.csv"), "\n")

# STEP 5 - Read and filter benthic data for BUL01 -----------------------------

benthic <- read_csv(benthic_file, show_col_types = FALSE,
                    locale = locale(encoding = "UTF-16LE"))

names(benthic) <- str_remove(names(benthic), "/.*$")

cat("\nBenthic data:", nrow(benthic), "rows\n")
cat("Columns:", paste(names(benthic), collapse = ", "), "\n")

# Get SiteVisitIDs for BUL01 in Bulkley study
bul01_visits <- study |>
  filter(Site == "BUL01", Study == bulkley_study) |>
  pull(SiteVisitID)

bul01_benthic <- benthic |>
  filter(SiteVisitID %in% bul01_visits)

cat("\nBUL01 benthic records:", nrow(bul01_benthic), "\n")
cat("BUL01 visit IDs:", paste(sort(bul01_visits), collapse = ", "), "\n")

if (nrow(bul01_benthic) > 0) {
  cat("Years:", paste(sort(unique(
    study |> filter(SiteVisitID %in% bul01_visits) |> pull(Year)
  )), collapse = ", "), "\n")
  cat("Unique taxa:", n_distinct(paste(bul01_benthic$Genus, bul01_benthic$Species)), "\n")
}

write_csv(bul01_benthic, file.path(out_dir, "cabin_opendata_benthic_bul01.csv"))
cat("Wrote", file.path(out_dir, "cabin_opendata_benthic_bul01.csv"), "\n")

# STEP 6 - Verification -------------------------------------------------------

cat("\n=== Summary ===\n")
cat("Bulkley CABIN sites:", nrow(bulkley_sites), "\n")
cat("BUL01 (Little Joe Ck): ", length(bul01_visits), "visits,",
    nrow(bul01_benthic), "benthic records\n")
cat("Our site BUL-01 should use CABIN site code: BUL01\n")
cat("NOTE: BUL04 and BUL05 are new sites — no existing CABIN data\n")
cat("\nDone.\n")

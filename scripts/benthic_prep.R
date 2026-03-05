# Parse Cordillera "Subsample - Flat" into CABIN upload format and analysis CSVs
#
# Input:  data/raw/Project_Neexdzi_Kwah_Benthic_Invertebrates.xlsx
# Output: data/processed/benthic_counts_tidy.csv   — long-format tidy counts
#         data/processed/benthic_species_matrix.csv — wide (samples × taxa) for vegan
#         data/processed/cabin_taxonomy.csv         — CABIN Taxonomy sheet format
#         data/processed/cabin_visits.csv           — CABIN Visits sheet format
#         data/processed/cabin_sites.csv            — CABIN Sites sheet format
#
# Reference: data/templates/templateGuide.xls for CABIN field definitions
# Reference: Sheep/R/01b_load_invert.R for Cordillera parsing patterns

# STEP 1 - Load packages and read data ----------------------------------------

library(tidyverse)
library(readxl)

raw_path <- "data/raw/Project_Neexdzi_Kwah_Benthic_Invertebrates.xlsx"
out_dir  <- "data/processed"
fs::dir_create(out_dir)

flat <- read_excel(raw_path, sheet = "Subsample - Flat", skip = 6)

cat("Raw dims:", nrow(flat), "x", ncol(flat), "\n")

# STEP 2 - Clean and filter ---------------------------------------------------

# Drop footer rows (NA Sample = blank rows + ND legend text)
flat <- flat |> filter(!is.na(Sample))

cat("After dropping NA Sample rows:", nrow(flat), "rows\n")

# STEP 3 - Parse site, replicate, and date ------------------------------------

flat <- flat |>
  mutate(
    # "BUL 01 A" → site = "BUL-01", replicate = "A"
    site = str_replace(str_extract(Sample, "BUL \\d+"), " ", "-"),
    replicate = str_extract(Sample, "[A-C]$"),
    rep_num = match(replicate, LETTERS),
    # "3-Oct-25" → 2025-10-03 (two-digit year)
    date_parsed = dmy(Date)
  )

cat("\nSite/replicate parsing:\n")
flat |> distinct(Sample, site, replicate, rep_num, date_parsed) |> print(n = 20)

# Verify dates look right
stopifnot(all(!is.na(flat$date_parsed)))
stopifnot(all(year(flat$date_parsed) == 2025))

# STEP 4 - Build sample_id and verify counts ----------------------------------

flat <- flat |>
  mutate(sample_id = paste(site, replicate, sep = "-"))

cat("\nTaxa per sample:\n")
flat |> count(sample_id) |> print(n = 20)

cat("\nTotal count per sample:\n")
flat |> group_by(sample_id) |> summarise(total = sum(Count)) |> print(n = 20)

# STEP 5 - Build tidy counts --------------------------------------------------

# Keep taxonomy hierarchy + FFG + count data
counts_tidy <- flat |>
  select(
    site, replicate, sample_id,
    date = date_parsed,
    phylum = Phylum,
    sub_phylum = `Sub Phylum`,
    class = Class,
    order = Order,
    family = Family,
    subfamily = Subfamily,
    tribe = Tribe,
    taxon = Name,
    taxonomy = Taxonomy,
    itis_code = `ITIS Code`,
    voltinism = Voltinism,
    ffg = `Functional Feeding\r\nGroup`,
    maturity = Maturity,
    nd = ND,
    count = Count,
    pct_sampled = `Percent Sampled`,
    rep_num
  )

cat("\nTidy counts:", nrow(counts_tidy), "rows\n")

write_csv(counts_tidy, file.path(out_dir, "benthic_counts_tidy.csv"))
cat("Wrote", file.path(out_dir, "benthic_counts_tidy.csv"), "\n")

# STEP 6 - Build species matrix (wide format for vegan) -----------------------

# Use taxon (Name) as the species identifier — this is the finest resolution
# Aggregate counts where same taxon appears multiple times per sample
# (e.g. different maturity stages of same taxon)
species_matrix <- counts_tidy |>
  group_by(sample_id, taxon) |>
  summarise(count = sum(count), .groups = "drop") |>
  pivot_wider(
    names_from = taxon,
    values_from = count,
    values_fill = 0
  )

cat("\nSpecies matrix:", nrow(species_matrix), "samples x",
    ncol(species_matrix) - 1, "taxa\n")

write_csv(species_matrix, file.path(out_dir, "benthic_species_matrix.csv"))
cat("Wrote", file.path(out_dir, "benthic_species_matrix.csv"), "\n")

# STEP 7 - CABIN Taxonomy sheet -----------------------------------------------

# Sub Sample / Total Sample from Percent Sampled
# Marchant Box has 20 cells; 5% = 1 cell, 7% ≈ 1.4 cells
# CABIN wants integer counts: sub_sample = cells picked, total_sample = 20
# For 5%: 1 of 20; for 7%: round(0.07 * 20) = 1.4 → use 1 (conservative)
# Actually: percent_sampled is % of total sample sorted, not cells.
# sub_sample = number of cells picked; total_sample = total cells in Marchant Box

cabin_taxonomy <- counts_tidy |>
  mutate(
    site_code = site,
    sample_number = 1L,
    site_visit_date = format(date, "%Y-%m-%d"),
    sub_sample = round(pct_sampled / 100 * 20),
    total_sample = 20L,
    repetition = as.integer(rep_num),
    itis = itis_code,
    note = case_when(
      !is.na(nd) & !is.na(maturity) ~ paste0(nd, "; ", maturity),
      !is.na(nd) ~ nd,
      !is.na(maturity) & maturity != "None" ~ maturity,
      TRUE ~ NA_character_
    )
  ) |>
  select(
    `Site Code` = site_code,
    `Sample Number` = sample_number,
    `Site Visit Date` = site_visit_date,
    `Sub Sample` = sub_sample,
    `Total Sample` = total_sample,
    Repetition = repetition,
    ITIS = itis,
    Count = count,
    Note = note
  )

cat("\nCABIN Taxonomy:", nrow(cabin_taxonomy), "rows\n")
cat("ITIS NA count:", sum(is.na(cabin_taxonomy$ITIS)), "(taxa without ITIS codes)\n")
cat("Non-numeric ITIS:", sum(grepl("[^0-9]", cabin_taxonomy$ITIS[!is.na(cabin_taxonomy$ITIS)])),
    "rows\n")

write_csv(cabin_taxonomy, file.path(out_dir, "cabin_taxonomy.csv"))
cat("Wrote", file.path(out_dir, "cabin_taxonomy.csv"), "\n")

# STEP 8 - CABIN Visits sheet -------------------------------------------------

# Site visit metadata — one row per site
cabin_visits <- counts_tidy |>
  distinct(site, date) |>
  mutate(
    `Site Code` = site,
    `Site Visit Date` = format(date, "%Y-%m-%d"),
    Season = "Fall",
    Protocol = "CABIN - Wadeable Streams",
    `Mesh Size` = 400L,
    `Kick Time` = 3L,
    `Site Description` = NA_character_,
    `Crew Members` = NA_character_,
    `Sampling Device` = "Kick Net",
    `Latitude Degree` = NA_real_,
    `Latitude Minute` = NA_real_,
    `Latitude Second` = NA_real_,
    `Longitude Degree` = NA_real_,
    `Longitude Minute` = NA_real_,
    `Longitude Second` = NA_real_,
    `Elevation (MASL)` = NA_real_,
    `GPS Datum` = "GRS80 (NAD83, WGS84)",
    `Number Of Reps` = 3L
  ) |>
  select(-site, -date)

cat("\nCABIN Visits:", nrow(cabin_visits), "rows\n")
cat("NOTE: Latitude/Longitude fields need to be filled from field sheets\n")

write_csv(cabin_visits, file.path(out_dir, "cabin_visits.csv"))
cat("Wrote", file.path(out_dir, "cabin_visits.csv"), "\n")

# STEP 9 - CABIN Sites sheet --------------------------------------------------

cabin_sites <- tibble(
  `Site Code` = c("BUL-01", "BUL-04", "BUL-05"),
  `Political Boundary` = "British Columbia",
  `Basin Name` = "Skeena",
  `Lake/River Name` = "Neexdzii Kwa (Upper Bulkley River)",
  `Stream Order` = NA_integer_
)

write_csv(cabin_sites, file.path(out_dir, "cabin_sites.csv"))
cat("Wrote", file.path(out_dir, "cabin_sites.csv"), "\n")

# STEP 10 - Verification ------------------------------------------------------

cat("\n=== Verification ===\n")
cat("Tidy counts:", nrow(counts_tidy), "rows,",
    n_distinct(counts_tidy$taxon), "unique taxa,",
    n_distinct(counts_tidy$sample_id), "samples\n")
cat("Species matrix:", nrow(species_matrix), "x", ncol(species_matrix) - 1, "\n")
cat("CABIN taxonomy:", nrow(cabin_taxonomy), "rows\n")
cat("CABIN visits:", nrow(cabin_visits), "sites\n")

# Cross-check: total counts should match between tidy and matrix
tidy_totals <- counts_tidy |>
  group_by(sample_id) |> summarise(tidy = sum(count)) |> arrange(sample_id)
matrix_totals <- species_matrix |>
  mutate(matrix = rowSums(across(-sample_id))) |>
  select(sample_id, matrix) |> arrange(sample_id)
check <- left_join(tidy_totals, matrix_totals, by = "sample_id")
if (all(check$tidy == check$matrix)) {
  cat("PASS: Tidy and matrix totals match\n")
} else {
  cat("FAIL: Tidy and matrix totals differ!\n")
  print(check)
}

cat("\nDone.\n")

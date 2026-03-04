# ems_prep.R
#
# Query BC EMS data for water quality stations within the Neexdzii Kwa watershed.
# Uses a spatial query of the BC Data Catalogue EMS monitoring locations layer
# intersected with the watershed boundary, then pulls results from the rems
# historic database.
#
# Prerequisites:
#   - rems package: pak::pak("bcgov/rems")
#   - bcdata package: pak::pak("bcgov/bcdata")
#   - Historic data downloaded: rems::download_historic_data()
#   - Watershed boundary cached: data/spatial/neexdzii_kwa.rds
#     (run scripts/data_map-study-area.R first)
#
# Outputs:
#   - data/processed/ems_stations.csv     (station metadata from BC Data Catalogue)
#   - data/processed/ems_raw.csv          (all records, all stations)
#   - data/processed/ems_nutrients.csv    (nutrients subset, tidy)
#   - data/processed/ems_general.csv      (general WQ subset, tidy)
#
# Usage: Rscript scripts/ems_prep.R

# STEP 1 - Load packages --------------------------------------------------------

library(dplyr)
library(tidyr)
library(readr)
library(lubridate)
library(sf)
library(bcdata)
library(rems)
library(janitor)

sf_use_s2(FALSE)

cat("=== Neexdzii Kwa EMS Prep (Spatial Query) ===\n\n")

out <- "data/processed"
dir.create(out, showWarnings = FALSE, recursive = TRUE)

# STEP 2 - Load watershed AOI and query BC Data Catalogue -----------------------

cat("Step 2: Spatial query of EMS monitoring locations...\n")

neexdzii <- readRDS("data/spatial/neexdzii_kwa.rds")

# Buffer the watershed by 1 km to catch stations on the boundary or
# on tributaries just outside the simplified polygon
aoi_3005 <- neexdzii |>
  st_transform(3005) |>
  st_buffer(1000)

# Query BC Data Catalogue — BBOX then local clip
# (INTERSECTS fails on this polygon; BBOX + st_intersection is equivalent)
ems_bbox <- bcdc_query_geodata("634ee4e0-c8f7-4971-b4de-12901b0b4be6") |>
  filter(BBOX(aoi_3005)) |>
  collect()

cat("BBOX query returned", nrow(ems_bbox), "stations\n")

# Clip to actual buffered watershed boundary
ems_bcdc <- ems_bbox[st_transform(aoi_3005, st_crs(ems_bbox)), ]

cat("Within buffered AOI:", nrow(ems_bcdc), "EMS stations\n")

# STEP 3 - Characterize stations from catalogue metadata -------------------------

cat("\nStep 3: Station characterization from catalogue...\n")

ems_catalogue <- ems_bcdc |>
  st_drop_geometry() |>
  transmute(
    ems_id = MONITORING_LOCATION_ID,
    monitoring_location = MONITORING_LOCATION_NAME,
    location_type = LOCATION_TYPE_CD,
    location_purpose = LOCATION_PURPOSE_CD,
    lat = LATITUDE,
    lon = -abs(LONGITUDE),  # BC Data Catalogue stores as positive; negate for WGS84
    n_samples_catalogue = SAMPLE_COUNT,
    n_results_catalogue = RESULT_COUNT,
    first_sample = FIRST_SAMPLE_DATE,
    last_sample = LAST_SAMPLE_DATE
  ) |>
  arrange(location_type, desc(n_results_catalogue))

cat("\nStations by type:\n")
ems_catalogue |> count(location_type) |> print()

cat("\nAll", nrow(ems_catalogue), "stations:\n")
print(ems_catalogue |> select(ems_id, monitoring_location, location_type,
                               n_results_catalogue, first_sample, last_sample),
      n = 80, width = 200)

# STEP 4 - Query EMS historic database for all stations -------------------------

cat("\nStep 4: Connecting to EMS historic database...\n")

ems_ids <- ems_catalogue$ems_id

conn <- connect_historic_db()
ems_tbl <- attach_historic_data(conn)

ems_raw <- ems_tbl |>
  filter(EMS_ID %in% ems_ids) |>
  collect() |>
  clean_names()

disconnect_historic_db(conn)

cat("Raw EMS records retrieved:", nrow(ems_raw), "\n")

# STEP 5 - Build station summary from actual data -------------------------------

cat("\nStep 5: Building station summary from rems data...\n")

ems_stations <- ems_raw |>
  group_by(ems_id, monitoring_location) |>
  summarise(
    n_records = n(),
    min_date = as.Date(min(collection_start, na.rm = TRUE)),
    max_date = as.Date(max(collection_start, na.rm = TRUE)),
    n_params = n_distinct(parameter),
    n_dates = n_distinct(as.Date(collection_start)),
    .groups = "drop"
  ) |>
  left_join(
    ems_catalogue |> select(ems_id, location_type, lat, lon),
    by = "ems_id"
  ) |>
  arrange(location_type, desc(n_records))

cat("\nStation overview:\n")
print(ems_stations, n = 60, width = 200)

# STEP 6 - Extract nutrients ----------------------------------------------------

cat("\nStep 6: Extracting nutrient parameters...\n")

nutrient_params <- c(
  "Phosphorus Total",
  "Phosphorus Total Dissolved",
  "Phosphorus Ort.Dis-P",
  "Phosphorus Ortho",
  "Nitrogen Ammonia Dissolved",
  "Nitrate(NO3) + Nitrite(NO2) Dissolved",
  "Nitrogen - Nitrite Dissolved (NO2)",
  "Nitrate (NO3) Dissolved",
  "Nitrogen Kjel.Tot(N)",
  "Nitrogen Total"
)

# Abbreviation map
param_map <- c(
  "Phosphorus Total"                      = "tp",
  "Phosphorus Total Dissolved"            = "tdp",
  "Phosphorus Ort.Dis-P"                  = "srp",
  "Phosphorus Ortho"                      = "srp",
  "Nitrogen Ammonia Dissolved"            = "nh3",
  "Nitrate(NO3) + Nitrite(NO2) Dissolved" = "no3no2",
  "Nitrogen - Nitrite Dissolved (NO2)"    = "no2",
  "Nitrate (NO3) Dissolved"               = "no3",
  "Nitrogen Kjel.Tot(N)"                  = "tkn",
  "Nitrogen Total"                        = "tn"
)

ems_nutrients <- ems_raw |>
  filter(parameter %in% nutrient_params) |>
  mutate(
    date = as_date(collection_start),
    year = year(date),
    month = month(date),
    param_abb = param_map[parameter],
    below_detect = !is.na(result_letter) & result_letter == "<"
  ) |>
  select(
    ems_id, monitoring_location,
    date, year, month,
    parameter, param_abb, result, unit,
    method_detection_limit, result_letter, below_detect,
    latitude, longitude
  )

cat("Nutrient records:", nrow(ems_nutrients), "\n")

# Stations with nutrients
cat("\nStations with nutrient data:\n")
ems_nutrients |>
  group_by(ems_id, monitoring_location) |>
  summarise(n = n(), params = paste(sort(unique(param_abb)), collapse = ", "),
            date_range = paste(min(date), "to", max(date)),
            .groups = "drop") |>
  print(n = 60, width = 200)

# STEP 7 - Extract general WQ params --------------------------------------------

cat("\nStep 7: Extracting general WQ parameters...\n")

general_params <- c(
  "pH", "Temperature", "Oxygen Dissolved",
  "Specific Conductance", "Turbidity",
  "Residue: Non-filterable (TSS)"
)

ems_general <- ems_raw |>
  filter(parameter %in% general_params) |>
  mutate(
    date = as_date(collection_start),
    year = year(date),
    month = month(date)
  ) |>
  select(
    ems_id, monitoring_location,
    date, year, month,
    parameter, result, unit,
    method_detection_limit, result_letter
  )

cat("General WQ records:", nrow(ems_general), "\n")

# STEP 8 - Save outputs ---------------------------------------------------------

cat("\nStep 8: Saving outputs...\n")

write_csv(ems_catalogue, file.path(out, "ems_catalogue.csv"))
cat("Saved:", nrow(ems_catalogue), "catalogue stations to", file.path(out, "ems_catalogue.csv"), "\n")

write_csv(ems_stations, file.path(out, "ems_stations.csv"))
cat("Saved:", nrow(ems_stations), "stations with data to", file.path(out, "ems_stations.csv"), "\n")

write_csv(ems_raw, file.path(out, "ems_raw.csv"))
cat("Saved:", nrow(ems_raw), "records to", file.path(out, "ems_raw.csv"), "\n")

write_csv(ems_nutrients, file.path(out, "ems_nutrients.csv"))
cat("Saved:", nrow(ems_nutrients), "records to", file.path(out, "ems_nutrients.csv"), "\n")

write_csv(ems_general, file.path(out, "ems_general.csv"))
cat("Saved:", nrow(ems_general), "records to", file.path(out, "ems_general.csv"), "\n")

# === VERIFICATION ===
cat("\n=== VERIFICATION ===\n")
cat("AOI: Neexdzii Kwa watershed + 1 km buffer\n")
cat("Stations in AOI (BC Data Catalogue):", nrow(ems_catalogue), "\n")
cat("Stations with rems data:", nrow(ems_stations), "\n")
cat("Total raw records:", nrow(ems_raw), "\n")
cat("Nutrient records:", nrow(ems_nutrients), "\n")
cat("General WQ records:", nrow(ems_general), "\n")
cat("Date range:", as.character(min(as.Date(ems_raw$collection_start, na.rm = TRUE))),
    "to", as.character(max(as.Date(ems_raw$collection_start, na.rm = TRUE))), "\n")
cat("\nOutputs in", out, "\n")

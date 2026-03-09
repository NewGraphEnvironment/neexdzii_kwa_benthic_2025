# prep_cabin-upload.R
#
# Transcribes field data sheet values (from data/photos/cards/) into CSVs
# matching the CABIN upload template structure (one file per sheet, all sites
# identified by Site Code column).
#
# Output: data/processed/cabin/{sites,visits,habitat,chemistry}.csv
# These map 1:1 to sheets in the CABIN .xls upload template.
#
# Field sheets were photographed as IMG_1394-IMG_1408.
# Data transcribed by reading photos with Claude Code — QA tracked in Issue #10.
#
# Usage: Rscript scripts/prep_cabin-upload.R

library(dplyr)
library(readr)
library(tibble)
library(tidyr)

out_dir <- "data/processed/cabin"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# =============================================================================
# STEP 1 — Sites sheet -------------------------------------------------------
# =============================================================================

sites <- tribble(
  ~`Site Code`, ~`Political Boundary`, ~`Basin Name`, ~`Lake/River Name`, ~`Stream Order`,
  "BUL-05",     "British Columbia",     "Bulkley",     "Bulkley River",    6,
  "BUL-04",     "British Columbia",     "Bulkley",     "Bulkley River",    6,
  "BUL-01",     "British Columbia",     "Bulkley",     "Bulkley River",    6
)

write_csv(sites, file.path(out_dir, "sites.csv"))
cat("Wrote sites.csv\n")

# =============================================================================
# STEP 2 — Visits sheet ------------------------------------------------------
# =============================================================================

# Coordinates from field notes and sites_benthic.csv:
# BUL-05: WP235, UTM 9N 0664158 6043496
# BUL-04: from sites_benthic.csv
# BUL-01: UTM 9U 0648314 6030170

dd_to_dms <- function(dd) {
  dd <- abs(dd)
  d <- floor(dd)
  m <- floor((dd - d) * 60)
  s <- round(((dd - d) * 60 - m) * 60, 2)
  list(deg = d, min = m, sec = s)
}

visits <- tribble(
  ~`Site Code`, ~`Site Visit Date`, ~lat_dd, ~lon_dd, ~elev, ~description,
  "BUL-05", "2025-09-28", 54.513, -126.463, 634,
    "Just downstream of McQuarrie Creek confluence. Riffle habitat in straight run.",
  "BUL-04", "2025-10-02", 54.440, -126.527, NA,
    "Mid-reach site downstream of Knockholt Bridge on McKilligan Road leading to the Knockholt Landfill.",
  "BUL-01", "2025-10-03", 54.393, -126.670, 580,
    "Adjacent to rest stop just upstream of North Road overpass (Northwood Picnic Site)."
) |>
  rowwise() |>
  mutate(
    lat_dms = list(dd_to_dms(lat_dd)),
    lon_dms = list(dd_to_dms(lon_dd))
  ) |>
  ungroup() |>
  transmute(
    `Site Code`,
    `Site Visit Date`,
    Season = "Fall",
    Protocol = "CABIN - Wadeable Streams",
    `Mesh Size` = 400,
    `Kick Time` = 3,
    `Site Description` = description,
    `Crew Members` = "Al Irvine, Tieasha Pierre",
    `Sampling Device` = "Kick Net",
    `Latitude Degree`  = sapply(lat_dms, \(x) x$deg),
    `Latitude Minute`  = sapply(lat_dms, \(x) x$min),
    `Latitude Second`  = sapply(lat_dms, \(x) x$sec),
    `Longitude Degree`  = sapply(lon_dms, \(x) x$deg),
    `Longitude Minute`  = sapply(lon_dms, \(x) x$min),
    `Longitude Second`  = sapply(lon_dms, \(x) x$sec),
    `Elevation (MASL)` = elev,
    `GPS Datum` = "NAD83/WGS84",
    `Number Of Reps` = 3
  )

write_csv(visits, file.path(out_dir, "visits.csv"))
cat("Wrote visits.csv\n")

# =============================================================================
# STEP 3 — Chemistry sheet ---------------------------------------------------
# =============================================================================

chemistry <- tribble(
  ~`Site Code`, ~`Site Visit Date`, ~param, ~unit, ~value,
  # BUL-05 (IMG_1396)
  "BUL-05", "2025-09-28", "General-AirTemperature",   "Degrees C", 6,
  "BUL-05", "2025-09-28", "General-WaterTemperature", "Degrees C", 5.4,
  "BUL-05", "2025-09-28", "General-pH",               "pH",        7.02,
  "BUL-05", "2025-09-28", "General-Conductivity",     "uS/cm",     270.1,
  "BUL-05", "2025-09-28", "General-Turbidity",        "NTU",       0.2,
  # BUL-04 (IMG_1401)
  "BUL-04", "2025-10-02", "General-AirTemperature",   "Degrees C", 8,
  "BUL-04", "2025-10-02", "General-WaterTemperature", "Degrees C", 7.11,
  "BUL-04", "2025-10-02", "General-pH",               "pH",        7.21,
  "BUL-04", "2025-10-02", "General-Turbidity",        "NTU",       1.21,
  # BUL-01 (IMG_1406)
  "BUL-01", "2025-10-03", "General-AirTemperature",   "Degrees C", 7,
  "BUL-01", "2025-10-03", "General-WaterTemperature", "Degrees C", 7.7,
  "BUL-01", "2025-10-03", "General-pH",               "pH",        7.5,
  "BUL-01", "2025-10-03", "General-Conductivity",     "uS/cm",     241,
  "BUL-01", "2025-10-03", "General-Turbidity",        "NTU",       1.46
) |>
  transmute(
    `Site Code`,
    `Sample Number` = 1,
    `Site Visit Date`,
    `Chemistry Type` = "Water Chemistry",
    Parameter = param,
    Unit = unit,
    MDL = NA_real_,
    Value = value
  )

write_csv(chemistry, file.path(out_dir, "chemistry.csv"))
cat("Wrote chemistry.csv\n")

# =============================================================================
# STEP 4 — Habitat sheet (channel + transects + pebble counts) ---------------
# =============================================================================
# All habitat data goes in one sheet, all sites, vertical format.
# CABIN Habitat columns: Site Code, Sample Number, Site Visit Date,
#   Habitat Type, Parameter, Unit, Value

# --- 4a. Channel-level parameters -------------------------------------------

channel <- tribble(
  ~`Site Code`, ~`Site Visit Date`, ~type, ~param, ~unit, ~value,

  # BUL-05 (IMG_1394-1396)
  "BUL-05", "2025-09-28", "Channel", "Width-Bankfull",             "m",          "48.0",
  "BUL-05", "2025-09-28", "Channel", "Width-Wetted",               "m",          "6.0",
  "BUL-05", "2025-09-28", "Channel", "Depth-BankfullMinusWetted",  "cm",         "150",
  "BUL-05", "2025-09-28", "Channel", "Slope",                      "m/m",        "0.002",
  "BUL-05", "2025-09-28", "Channel", "Velocity-Avg",               "m/s",        "0.54",
  "BUL-05", "2025-09-28", "Channel", "Reach-%CanopyCoverage",      "Percentage", "1-25",
  "BUL-05", "2025-09-28", "Channel", "Macrophyte",                 "Percentage", "0",
  "BUL-05", "2025-09-28", "Channel", "Reach-Riffles",              "Binary",     "Y",
  "BUL-05", "2025-09-28", "Channel", "Reach-StraightRun",          "Binary",     "Y",
  "BUL-05", "2025-09-28", "Channel", "Veg-Shrubs",                 "Binary",     "Y",
  "BUL-05", "2025-09-28", "Channel", "Veg-Deciduous",              "Binary",     "Y",
  "BUL-05", "2025-09-28", "Channel", "Veg-Coniferous",             "Binary",     "Y",
  "BUL-05", "2025-09-28", "Channel", "Reach-DomStreamsideVeg",     "Category",   "Deciduous Trees",

  # BUL-04 (IMG_1400-1401)
  "BUL-04", "2025-10-02", "Channel", "Width-Bankfull",             "m",          "110",
  "BUL-04", "2025-10-02", "Channel", "Width-Wetted",               "m",          "28",
  "BUL-04", "2025-10-02", "Channel", "Slope",                      "m/m",        "0.0034",
  "BUL-04", "2025-10-02", "Channel", "Velocity-Avg",               "m/s",        "0.54",
  "BUL-04", "2025-10-02", "Channel", "Reach-%CanopyCoverage",      "Percentage", "26-50",
  "BUL-04", "2025-10-02", "Channel", "Macrophyte",                 "Percentage", "76-100",
  "BUL-04", "2025-10-02", "Channel", "Reach-Riffles",              "Binary",     "Y",
  "BUL-04", "2025-10-02", "Channel", "Reach-Pools",                "Binary",     "Y",
  "BUL-04", "2025-10-02", "Channel", "Veg-GrassesFerns",           "Binary",     "Y",
  "BUL-04", "2025-10-02", "Channel", "Veg-Shrubs",                 "Binary",     "Y",
  "BUL-04", "2025-10-02", "Channel", "Veg-Coniferous",             "Binary",     "Y",
  "BUL-04", "2025-10-02", "Channel", "Reach-DomStreamsideVeg",     "Category",   "Coniferous Trees",

  # BUL-01 (IMG_1404-1406)
  "BUL-01", "2025-10-03", "Channel", "Width-Bankfull",             "m",          "46",
  "BUL-01", "2025-10-03", "Channel", "Width-Wetted",               "m",          "14.4",
  "BUL-01", "2025-10-03", "Channel", "Slope",                      "m/m",        "0.00105",
  "BUL-01", "2025-10-03", "Channel", "Velocity-Avg",               "m/s",        "0.32",
  "BUL-01", "2025-10-03", "Channel", "Reach-%CanopyCoverage",      "Percentage", "0",
  "BUL-01", "2025-10-03", "Channel", "Macrophyte",                 "Percentage", "76-100",
  "BUL-01", "2025-10-03", "Channel", "Reach-Riffles",              "Binary",     "Y",
  "BUL-01", "2025-10-03", "Channel", "Reach-Pools",                "Binary",     "Y",
  "BUL-01", "2025-10-03", "Channel", "Reach-StraightRun",          "Binary",     "Y",
  "BUL-01", "2025-10-03", "Channel", "Veg-GrassesFerns",           "Binary",     "Y",
  "BUL-01", "2025-10-03", "Channel", "Veg-Shrubs",                 "Binary",     "Y",
  "BUL-01", "2025-10-03", "Channel", "Veg-Coniferous",             "Binary",     "Y",
  "BUL-01", "2025-10-03", "Channel", "Veg-Deciduous",              "Binary",     "Y",
  "BUL-01", "2025-10-03", "Channel", "Reach-DomStreamsideVeg",     "Category",   "Forest"
)

# --- 4b. Cross-section transects --------------------------------------------
# CABIN parameters: XSEC-DistanceFromShore, XSEC-DepthChannel,
#   XSEC-DepthFlowingWater, XSEC-DepthStagnation, XSEC-Velocity
# Sample Number = transect station number

xsec_raw <- tribble(
  ~`Site Code`, ~`Site Visit Date`, ~station, ~dist_m, ~depth_cm, ~flowing_cm, ~stagnation_cm, ~velocity,

  # BUL-05 (IMG_1397) — 5 stations
  "BUL-05", "2025-09-28", 1, 0.5,  1.0,  19.5, 17,   NA,
  "BUL-05", "2025-09-28", 2, 1.0,  2.0,  23,   18,   NA,
  "BUL-05", "2025-09-28", 3, 1.5,  2.0,  21,   19,   NA,
  "BUL-05", "2025-09-28", 4, 2.0,  4.0,  14,   12,   NA,
  "BUL-05", "2025-09-28", 5, 2.5,  5.0,  10.5, 10,   NA,

  # BUL-04 (IMG_1402) — 6 stations
  "BUL-04", "2025-10-02", 1, 1.2,  15.5, 9.5,  13.5, 0.31,
  "BUL-04", "2025-10-02", 2, 2.4,  11,   9.5,  13.5, 0.31,
  "BUL-04", "2025-10-02", 3, 3.6,  4.8,  3.5,  4.8,  0.17,
  "BUL-04", "2025-10-02", 4, 4.8,  13.5, 13.5, 13.5, NA,
  "BUL-04", "2025-10-02", 5, 6.6,  22,   15,   15,   NA,
  "BUL-04", "2025-10-02", 6, NA,   NA,   25,   15,   NA,

  # BUL-01 (IMG_1407) — 6 stations
  "BUL-01", "2025-10-03", 1, 2.4,  6.5,  2.1,  2.35, NA,
  "BUL-01", "2025-10-03", 2, 4.8,  14.5, 16.5, 14.5, 0.70,
  "BUL-01", "2025-10-03", 3, 7.2,  14.5, 10.5, 12.5, NA,
  "BUL-01", "2025-10-03", 4, 9.6,  10.5, 18.5, 21,   NA,
  "BUL-01", "2025-10-03", 5, 12,   22,   22,   13.5, NA,
  "BUL-01", "2025-10-03", 6, NA,   16.5, NA,   NA,   0.63
)

# Pivot to CABIN vertical format
xsec <- xsec_raw |>
  pivot_longer(
    cols = c(dist_m, depth_cm, flowing_cm, stagnation_cm, velocity),
    names_to = "measure",
    values_to = "value",
    values_drop_na = TRUE
  ) |>
  mutate(
    param = case_match(measure,
      "dist_m"         ~ "XSEC-DistanceFromShore",
      "depth_cm"       ~ "XSEC-DepthChannel",
      "flowing_cm"     ~ "XSEC-DepthFlowingWater",
      "stagnation_cm"  ~ "XSEC-DepthStagnation",
      "velocity"       ~ "XSEC-Velocity"
    ),
    unit = case_match(measure,
      "dist_m"         ~ "m",
      "depth_cm"       ~ "cm",
      "flowing_cm"     ~ "cm",
      "stagnation_cm"  ~ "cm",
      "velocity"       ~ "m/s"
    ),
    type = "Channel"
  ) |>
  transmute(
    `Site Code`, `Site Visit Date`,
    `Sample Number` = station,
    `Habitat Type` = type,
    Parameter = param,
    Unit = unit,
    Value = as.character(value)
  )

# --- 4c. Pebble counts → substrate summary stats ----------------------------
# CABIN Habitat Type = "Substrate Data". Template guide parameters:
#   D50 (median, cm), Dg (geometric mean, cm), Diameter-Mean (mean, cm),
#   %Silt+Clay, %Sand, %Gravel, %Pebble, %Cobble, %Boulder, %Bedrock,
#   Dominant-1st, Dominant-2nd (Category 0-9),
#   Embeddedness (Category 0-4), PebbleCount (string of all diameters),
#   PeriphytonCoverage (Category 1-5)
#
# Wentworth size classes (matching CABIN categories):
#   0: organic/silt+clay (<0.1 cm, field value 0)
#   1: <0.1 cm (silt/clay)
#   2: 0.1-0.2 cm (sand)
#   3: 0.2-1.6 cm (gravel)
#   4: 1.6-3.2 cm (gravel)
#   5: 3.2-6.4 cm (pebble)
#   6: 6.4-12.8 cm (cobble)
#   7: 12.8-25.6 cm (cobble)
#   8: >25.6 cm (boulder)
#   9: bedrock

assign_size_cat <- function(d) {
  case_when(
    d == 0        ~ 0L,
    d < 0.1       ~ 1L,
    d < 0.2       ~ 2L,
    d < 1.6       ~ 3L,
    d < 3.2       ~ 4L,
    d < 6.4       ~ 5L,
    d < 12.8      ~ 6L,
    d < 25.6      ~ 7L,
    TRUE          ~ 8L
  )
}

summarise_pebbles <- function(site, date, file) {
  if (!file.exists(file)) return(tibble())
  df <- read_csv(file, show_col_types = FALSE)

  diams <- df$diameter_cm
  # Remove zeros for geometric mean (log of 0 undefined)
  diams_pos <- diams[diams > 0]

  d50  <- median(diams)
  dg   <- if (length(diams_pos) > 0) exp(mean(log(diams_pos))) else 0
  dmean <- mean(diams)

  # Size class percentages
  cats <- assign_size_cat(diams)
  n <- length(cats)
  pct_siltclay <- sum(cats <= 1) / n * 100
  pct_sand     <- sum(cats == 2) / n * 100
  pct_gravel   <- sum(cats %in% 3:4) / n * 100
  pct_pebble   <- sum(cats == 5) / n * 100
  pct_cobble   <- sum(cats %in% 6:7) / n * 100
  pct_boulder  <- sum(cats == 8) / n * 100

  # Dominant categories (most frequent size class)
  cat_tbl <- sort(table(cats), decreasing = TRUE)
  dom1 <- as.integer(names(cat_tbl)[1])
  dom2 <- if (length(cat_tbl) > 1) as.integer(names(cat_tbl)[2]) else NA_integer_

  # Embeddedness — median of per-pebble values, convert to CABIN 0-4 scale
  # CABIN: 0=0%, 1=1/4, 2=1/2, 3=3/4, 4=100%
  # Field values recorded as decimals (0, 0.25, 0.5, 0.75, 1.0)
  embed_med <- median(df$embeddedness, na.rm = TRUE)
  embed_cat <- round(embed_med * 4)

  # PebbleCount — string collection of all diameters
  pebble_str <- paste(diams, collapse = ",")

  tibble(
    `Site Code` = site,
    `Site Visit Date` = date,
    Parameter = c("D50", "Dg", "Diameter-Mean",
                  "%Silt+Clay", "%Sand", "%Gravel", "%Pebble", "%Cobble", "%Boulder",
                  "Dominant-1st", "Dominant-2nd", "Embeddedness", "PebbleCount"),
    Unit = c("cm", "cm", "cm",
             "%", "%", "%", "%", "%", "%",
             "Category(0-9)", "Category(0-9)", "Category(0-4)", "cm"),
    Value = as.character(c(
      round(d50, 2), round(dg, 2), round(dmean, 2),
      round(pct_siltclay, 1), round(pct_sand, 1), round(pct_gravel, 1),
      round(pct_pebble, 1), round(pct_cobble, 1), round(pct_boulder, 1),
      dom1, dom2, embed_cat, pebble_str
    ))
  )
}

substrate <- bind_rows(
  summarise_pebbles("BUL-05", "2025-09-28", "data/processed/cabin/pebble_bul05.csv"),
  summarise_pebbles("BUL-04", "2025-10-02", "data/processed/cabin/pebble_bul04.csv"),
  summarise_pebbles("BUL-01", "2025-10-03", "data/processed/cabin/pebble_bul01.csv")
) |>
  mutate(
    `Sample Number` = 1L,
    `Habitat Type` = "Substrate Data"
  )

# --- 4d. Combine all habitat ------------------------------------------------

channel_fmt <- channel |>
  transmute(
    `Site Code`, `Site Visit Date`,
    `Sample Number` = 1L,
    `Habitat Type` = type,
    Parameter = param,
    Unit = unit,
    Value = value
  )

habitat <- bind_rows(channel_fmt, xsec, substrate)

write_csv(habitat, file.path(out_dir, "habitat.csv"))
cat("Wrote habitat.csv (", nrow(habitat), "rows )\n")

# =============================================================================
# STEP 5 — Summary -----------------------------------------------------------
# =============================================================================

cat("\n--- CABIN upload CSVs written to", out_dir, "---\n")
cat("Structure: one CSV per CABIN template sheet, all sites by Site Code\n")
for (f in list.files(out_dir, pattern = "^(sites|visits|habitat|chemistry)[.]csv$")) {
  n <- nrow(read_csv(file.path(out_dir, f), show_col_types = FALSE))
  cat("  ", f, "—", n, "rows\n")
}
cat("\nPer-site pebble CSVs retained for QA (pebble_bul*.csv)\n")
cat("Taxonomy sheet still needed from benthic_counts_tidy.csv\n")

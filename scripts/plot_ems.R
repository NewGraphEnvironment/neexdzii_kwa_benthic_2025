# plot_ems.R
#
# EMS water quality plots for the Upper Bulkley River, grouped for readability.
# Reads tidy CSVs from ems_prep.R (spatial query version).
#
# Plot groups:
#   1. Point source comparisons (Houston STP, Knockholt Landfill)
#   2. Neexdzii Kwa mainstem gradient
#   3. Buck Creek (Equity Silver mine context)
#
# Outputs: fig/ems/*.png
#
# Usage: Rscript scripts/plot_ems.R

library(tidyverse)

cat("=== EMS Exploratory Plots ===\n\n")

dir.create("fig/ems", showWarnings = FALSE, recursive = TRUE)

# --- Load data ------------------------------------------------------------

nutrients <- read_csv("data/processed/ems_nutrients.csv", show_col_types = FALSE) |>
  filter(unit == "mg/L" | is.na(unit))  # drop 54 TP records in ug/g
general   <- read_csv("data/processed/ems_general.csv", show_col_types = FALSE)
stations  <- read_csv("data/processed/ems_stations.csv", show_col_types = FALSE)

# Param labels
param_labels <- c(
  tp = "Total Phosphorus (mg/L)",
  tdp = "Total Dissolved P (mg/L)",
  srp = "Soluble Reactive P (mg/L)",
  nh3 = "Ammonia-N (mg/L)",
  no3no2 = "Nitrate+Nitrite (mg/L)",
  no3 = "Nitrate (mg/L)",
  no2 = "Nitrite (mg/L)",
  tkn = "Total Kjeldahl N (mg/L)",
  tn = "Total Nitrogen (mg/L)"
)

general_labels <- c(
  "pH" = "pH",
  "Oxygen Dissolved" = "Dissolved Oxygen (mg/L)",
  "Specific Conductance" = "Conductivity (uS/cm)",
  "Residue: Non-filterable (TSS)" = "TSS (mg/L)"
)

# --- BC Water Quality Guidelines (aquatic life) -----------------------------

# Nutrient guideline lines (simple horizontal references)
wqg_lines <- tribble(
  ~param_abb, ~yintercept, ~label,
  "tp",       0.01,        "CCME 10 ug/L",
  "no3no2",   3,           "BC WQG 3 mg/L",
  "no3",      3,           "BC WQG 3 mg/L"
)

# pH guideline bounds
wqg_ph <- data.frame(yintercept = c(6.5, 9.0), label = "BC WQG")

# --- Consistent colour palette --------------------------------------------
#
# Upstream sites: cool blues/greens (high contrast from downstream)
# Downstream sites: warm reds/oranges (similar tones to each other)
# Reference/mid sites: neutral greys/purples

stn_colours <- c(
  # Houston STP group
  "U/S Houston STP"              = "#1b7837",   # dark green (upstream)
  "D/S Houston STP Outfall"      = "#d62728",   # red (immediately downstream)
  "D/S Houston Sewage (2.4 km)"  = "#e6550d",   # orange-red (further downstream)
  # Knockholt group
  "U/S Knockholt"                = "#2166ac",   # blue (upstream)
  "D/S Knockholt"                = "#b2182b",   # dark red (downstream)
  # Mainstem gradient (upstream cool → downstream warm)
  "Bulkley Lake"                 = "#4393c3",   # light blue
  "D/S Bulkley Lake"             = "#74add1",   # lighter blue
  "Houston East Bridge"          = "#bababa",   # light grey
  # Buck Creek (upstream mine → downstream)
  "Above Bessemer (mine)"        = "#1a9850",   # green
  "At Goosly Lake (mine)"        = "#66bd63",   # light green
  "Klo Bridge"                   = "#a6d96a",   # yellow-green
  "2nd Bridge"                   = "#d9ef8b",   # pale yellow-green
  "@ 12 km"                      = "#878787",   # grey
  "At Houston"                   = "#fdae61",   # light orange
  "D/S Hwy 16"                   = "#f46d43"    # orange
)

# --- Station groups -------------------------------------------------------

# Houston STP stations
houston_stp_ids <- c("0400297", "0400295", "0400296")
houston_stp_labels <- c(
  "0400297" = "U/S Houston STP",
  "0400295" = "D/S Houston STP Outfall",
  "0400296" = "D/S Houston Sewage (2.4 km)"
)

# Knockholt Landfill stations
knockholt_ids <- c("E257276", "E257277")
knockholt_labels <- c(
  "E257276" = "U/S Knockholt",
  "E257277" = "D/S Knockholt"
)

# Neexdzii Kwa mainstem (upstream to downstream, including STP D/S)
# Removed E238643 (@ Knockholt), E238800 (@ Craker Rd), E262984 (Hunter Road) — no nutrient data
# Hunter Road also has incorrect EMS coordinates (lon -127.35 vs actual ~-126.75)
mainstem_ids <- c("E206292", "E307186", "E257276", "E257277",
                  "0400201", "0400297", "0400295", "0400296")
mainstem_labels <- c(
  "E206292" = "Bulkley Lake",
  "E307186" = "D/S Bulkley Lake",
  "E257276" = "U/S Knockholt",
  "E257277" = "D/S Knockholt",
  "0400201" = "Houston East Bridge",
  "0400297" = "U/S Houston STP",
  "0400295" = "D/S Houston STP Outfall",
  "0400296" = "D/S Houston Sewage (2.4 km)"
)

# Buck Creek (upstream to downstream)
# Removed E238625 (@ Bulkley Confluence) — no nutrient data
buck_ids <- c("0400765", "0400766", "0400767", "E207067",
              "E238622", "E207066", "E219804")
buck_labels <- c(
  "0400765" = "Above Bessemer (mine)",
  "0400766" = "At Goosly Lake (mine)",
  "0400767" = "Klo Bridge",
  "E207067" = "2nd Bridge",
  "E238622" = "@ 12 km",
  "E207066" = "At Houston",
  "E219804" = "D/S Hwy 16"
)

# --- Helper: label and factor a station subset ----------------------------

prep_subset <- function(data, ids, labels) {
  data |>
    filter(ems_id %in% ids) |>
    mutate(station = factor(labels[ems_id], levels = labels))
}

# --- Helper: get colours for a label set ----------------------------------

get_colours <- function(labels) {
  stn_colours[labels]
}

# --- Helper: time series --------------------------------------------------

plot_ts <- function(data, params, y_label = "Concentration (mg/L)", ncol = 2) {
  labels <- levels(data$station)
  cols <- get_colours(labels)

  d <- data |>
    filter(param_abb %in% params) |>
    mutate(param_label = param_labels[param_abb],
           param_label = factor(param_label, levels = param_labels[params]))

  # Build guideline reference df matched to facet labels
  gl <- wqg_lines |>
    filter(param_abb %in% params) |>
    mutate(param_label = param_labels[param_abb],
           param_label = factor(param_label, levels = param_labels[params]))

  ggplot(d, aes(x = date, y = result, colour = station)) +
    geom_hline(data = gl, aes(yintercept = yintercept),
               linetype = "dashed", colour = "red3", alpha = 0.7, linewidth = 0.5) +
    geom_point(size = 1.5, alpha = 0.7) +
    geom_line(alpha = 0.3, linewidth = 0.3) +
    facet_wrap(~ param_label, ncol = ncol, scales = "free_y") +
    scale_colour_manual(values = cols, name = "Station") +
    theme_bw(base_size = 11) +
    theme(
      axis.title.x = element_blank(),
      legend.position = "bottom",
      strip.text = element_text(size = 10)
    ) +
    labs(y = y_label) +
    guides(colour = guide_legend(nrow = 3, override.aes = list(size = 3)))
}

# --- Helper: box by station -----------------------------------------------

plot_stn_box <- function(data, params, y_label = "Concentration (mg/L)", ncol = 2) {
  labels <- levels(data$station)
  cols <- get_colours(labels)

  d <- data |>
    filter(param_abb %in% params) |>
    mutate(param_label = param_labels[param_abb],
           param_label = factor(param_label, levels = param_labels[params]))

  # Build guideline reference df matched to facet labels
  gl <- wqg_lines |>
    filter(param_abb %in% params) |>
    mutate(param_label = param_labels[param_abb],
           param_label = factor(param_label, levels = param_labels[params]))

  ggplot(d, aes(x = station, y = result, fill = station)) +
    geom_hline(data = gl, aes(yintercept = yintercept),
               linetype = "dashed", colour = "red3", alpha = 0.7, linewidth = 0.5) +
    stat_boxplot(geom = "errorbar", width = 0.4) +
    geom_boxplot(width = 0.6, outlier.size = 0.8, outlier.alpha = 0.5) +
    facet_wrap(~ param_label, ncol = ncol, scales = "free_y") +
    scale_fill_manual(values = cols, guide = "none") +
    theme_bw(base_size = 11) +
    theme(
      axis.title.x = element_blank(),
      axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
      strip.text = element_text(size = 10)
    ) +
    labs(y = y_label)
}

# === GROUP 1: Point Source Comparisons ====================================

cat("--- Group 1: Point source comparisons ---\n")

# 1a. Houston STP — TP trends with loess
houston_tp <- prep_subset(nutrients, houston_stp_ids, houston_stp_labels) |>
  filter(param_abb == "tp")

p <- ggplot(houston_tp, aes(x = date, y = result, colour = station)) +
  geom_hline(yintercept = 0.01, linetype = "dashed", colour = "red3",
             alpha = 0.7, linewidth = 0.5) +
  geom_point(size = 1.5, alpha = 0.7) +
  geom_smooth(method = "loess", se = FALSE, linewidth = 0.8) +
  scale_colour_manual(values = get_colours(houston_stp_labels), name = "Station") +
  theme_bw(base_size = 11) +
  theme(legend.position = "bottom") +
  labs(y = "Total Phosphorus (mg/L)")

ggsave("fig/ems/houston_stp_tp.png", p, width = 9, height = 5, dpi = 200)
cat("Saved fig/ems/houston_stp_tp.png\n")

# 1b. Houston STP — all nutrients time series
houston_nutr <- prep_subset(nutrients, houston_stp_ids, houston_stp_labels)
p <- plot_ts(houston_nutr, c("tp", "tdp", "nh3", "no3no2"))
ggsave("fig/ems/houston_stp_nutrients_ts.png", p, width = 10, height = 8, dpi = 200)
cat("Saved fig/ems/houston_stp_nutrients_ts.png\n")

# 1c. Houston STP — nutrient box plots
p <- plot_stn_box(houston_nutr, c("tp", "tdp", "nh3", "no3no2"))
ggsave("fig/ems/houston_stp_nutrients_box.png", p, width = 9, height = 7, dpi = 200)
cat("Saved fig/ems/houston_stp_nutrients_box.png\n")

# 1d. Knockholt Landfill — upstream vs downstream
knockholt <- prep_subset(nutrients, knockholt_ids, knockholt_labels) |>
  filter(param_abb %in% c("tp", "nh3", "no3no2", "tn"))

if (nrow(knockholt) > 0) {
  p <- knockholt |>
    mutate(param_label = param_labels[param_abb]) |>
    ggplot(aes(x = station, y = result, fill = station)) +
    geom_boxplot(width = 0.6) +
    geom_jitter(width = 0.1, size = 1.5, alpha = 0.6) +
    facet_wrap(~ param_label, scales = "free_y", ncol = 2) +
    scale_fill_manual(values = get_colours(knockholt_labels), guide = "none") +
    theme_bw(base_size = 11) +
    theme(axis.title.x = element_blank(),
          axis.text.x = element_text(size = 9)) +
    labs(y = "Concentration (mg/L)")

  ggsave("fig/ems/knockholt_compare.png", p, width = 8, height = 6, dpi = 200)
  cat("Saved fig/ems/knockholt_compare.png\n")
}

# === GROUP 2: Mainstem Gradient ==========================================

cat("\n--- Group 2: Mainstem gradient ---\n")

mainstem_nutr <- prep_subset(nutrients, mainstem_ids, mainstem_labels)
mainstem_gen  <- prep_subset(general, mainstem_ids, mainstem_labels)

# 2a. Phosphorus time series
p <- plot_ts(mainstem_nutr, c("tp", "tdp", "srp"))
ggsave("fig/ems/mainstem_phosphorus_ts.png", p, width = 10, height = 8, dpi = 200)
cat("Saved fig/ems/mainstem_phosphorus_ts.png\n")

# 2b. Phosphorus by station
p <- plot_stn_box(mainstem_nutr, c("tp", "tdp", "srp"))
ggsave("fig/ems/mainstem_phosphorus_box.png", p, width = 11, height = 7, dpi = 200)
cat("Saved fig/ems/mainstem_phosphorus_box.png\n")

# 2c. Nitrogen time series
p <- plot_ts(mainstem_nutr, c("nh3", "no3no2", "tkn", "tn"))
ggsave("fig/ems/mainstem_nitrogen_ts.png", p, width = 10, height = 8, dpi = 200)
cat("Saved fig/ems/mainstem_nitrogen_ts.png\n")

# 2d. Nitrogen by station
p <- plot_stn_box(mainstem_nutr, c("nh3", "no3no2", "tkn", "tn"))
ggsave("fig/ems/mainstem_nitrogen_box.png", p, width = 11, height = 7, dpi = 200)
cat("Saved fig/ems/mainstem_nitrogen_box.png\n")

# 2e. General WQ time series (pH, DO, conductivity, TSS — no turbidity/temp)
mainstem_gen <- mainstem_gen |>
  filter(parameter %in% names(general_labels))

# pH guideline lines for general plots
ph_gl <- data.frame(
  param_label = factor("pH", levels = general_labels),
  yintercept = c(6.5, 9.0)
)

p <- mainstem_gen |>
  mutate(param_label = general_labels[parameter],
         param_label = factor(param_label, levels = general_labels)) |>
  ggplot(aes(x = date, y = result, colour = station)) +
  geom_hline(data = ph_gl, aes(yintercept = yintercept),
             linetype = "dashed", colour = "red3", alpha = 0.7, linewidth = 0.5) +
  geom_point(size = 1.0, alpha = 0.6) +
  facet_wrap(~ param_label, ncol = 2, scales = "free_y") +
  scale_colour_manual(values = get_colours(mainstem_labels), name = "Station") +
  theme_bw(base_size = 10) +
  theme(
    axis.title.x = element_blank(),
    legend.position = "bottom",
    strip.text = element_text(size = 10)
  ) +
  labs(y = "Value") +
  guides(colour = guide_legend(nrow = 3, override.aes = list(size = 2.5)))

ggsave("fig/ems/mainstem_general_ts.png", p, width = 10, height = 8, dpi = 200)
cat("Saved fig/ems/mainstem_general_ts.png\n")

# 2f. General WQ by station
p <- mainstem_gen |>
  mutate(param_label = general_labels[parameter],
         param_label = factor(param_label, levels = general_labels)) |>
  ggplot(aes(x = station, y = result, fill = station)) +
  geom_hline(data = ph_gl, aes(yintercept = yintercept),
             linetype = "dashed", colour = "red3", alpha = 0.7, linewidth = 0.5) +
  stat_boxplot(geom = "errorbar", width = 0.4) +
  geom_boxplot(width = 0.6, outlier.size = 0.8, outlier.alpha = 0.5) +
  facet_wrap(~ param_label, ncol = 2, scales = "free_y") +
  scale_fill_manual(values = get_colours(mainstem_labels), guide = "none") +
  theme_bw(base_size = 10) +
  theme(
    axis.title.x = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1, size = 8),
    strip.text = element_text(size = 10)
  ) +
  labs(y = "Value")

ggsave("fig/ems/mainstem_general_box.png", p, width = 11, height = 8, dpi = 200)
cat("Saved fig/ems/mainstem_general_box.png\n")

# === GROUP 3: Buck Creek =================================================

cat("\n--- Group 3: Buck Creek ---\n")

buck_nutr <- prep_subset(nutrients, buck_ids, buck_labels)

if (nrow(buck_nutr) > 0) {
  # 3a. Phosphorus time series
  p <- plot_ts(buck_nutr, c("tp", "tdp", "srp"))
  ggsave("fig/ems/buck_phosphorus_ts.png", p, width = 10, height = 8, dpi = 200)
  cat("Saved fig/ems/buck_phosphorus_ts.png\n")

  # 3b. Phosphorus by station
  p <- plot_stn_box(buck_nutr, c("tp", "tdp", "srp"))
  ggsave("fig/ems/buck_phosphorus_box.png", p, width = 10, height = 7, dpi = 200)
  cat("Saved fig/ems/buck_phosphorus_box.png\n")

  # 3c. Nitrogen time series
  p <- plot_ts(buck_nutr, c("nh3", "no3no2", "tkn", "tn"))
  ggsave("fig/ems/buck_nitrogen_ts.png", p, width = 10, height = 8, dpi = 200)
  cat("Saved fig/ems/buck_nitrogen_ts.png\n")

  # 3d. Nitrogen by station
  p <- plot_stn_box(buck_nutr, c("nh3", "no3no2", "tkn", "tn"))
  ggsave("fig/ems/buck_nitrogen_box.png", p, width = 10, height = 7, dpi = 200)
  cat("Saved fig/ems/buck_nitrogen_box.png\n")
}

# === AMMONIA GUIDELINE EVALUATION — Houston STP ============================

cat("\n--- Ammonia BC WQG evaluation (Houston STP) ---\n")

# BC WQG ammonia long-term limit (mg/L total ammonia)
# Conditional on temperature (EMS_0013) and pH (EMS_0004)
# From wqbc::limits, simplified into a single function
calc_nh3_wqg <- function(temp, ph) {
  # Un-ionized fraction
  f_nh3 <- 1 / (10^((0.09018 + 2729.92 / (273.2 + temp)) - ph) + 1) * 100

  # Long-term limit by temp/pH bin
  limit <- case_when(
    # Low temp, high pH
    temp >= 0 & temp < 15 & ph >= 8 & ph <= 9 ~
      (0.8 / (10^(0.03 * (20 - temp))) / 16 * 0.822 * 100) / f_nh3,
    # Low temp, mid pH
    temp >= 0 & temp < 15 & ph >= 7.7 & ph < 8 ~
      (0.8 / (10^(0.03 * (20 - temp))) / ((1 + 10^(7.4 - ph)) / 1.25) / 16 * 0.822 * 100) / f_nh3,
    # Low temp, low-mid pH
    temp >= 0 & temp < 15 & ph >= 6.5 & ph < 7.7 ~
      (0.8 / (10^(0.03 * (20 - temp))) / ((1 + 10^(7.4 - ph)) / 1.25) /
       ((24 * 10^(7.7 - ph)) / (1 + 10^(7.4 - ph))) * 0.822 * 100) / f_nh3,
    # High temp, low-mid pH
    temp >= 15 & temp < 20 & ph >= 6.5 & ph < 7.7 ~
      (0.8 / 1.14 / ((1 + 10^(7.4 - ph)) / 1.25) /
       ((24 * 10^(7.7 - ph)) / (1 + 10^(7.4 - ph))) * 0.822 * 100) / f_nh3,
    # High temp, mid pH
    temp >= 15 & temp < 20 & ph >= 7.7 & ph < 8 ~
      (0.8 / 1.14 / ((1 + 10^(7.4 - ph)) / 1.25) / 16 * 0.822 * 100) / f_nh3,
    # High temp, high pH
    temp >= 15 & temp < 20 & ph >= 8 & ph <= 9 ~
      (0.8 / 1.14 / 16 * 0.822 * 100) / f_nh3,
    # Fallback: very low pH
    temp <= 20 & ph < 6.5 ~ 1.21,
    # Fallback: very high pH
    temp <= 20 & ph > 9 ~ 0.102,
    TRUE ~ NA_real_
  )
  limit
}

# a) Join ammonia + pH for Houston STP
nh3_stp <- nutrients |>
  filter(ems_id %in% houston_stp_ids, param_abb == "nh3") |>
  select(ems_id, monitoring_location, date, nh3 = result)

ph_stp <- general |>
  filter(ems_id %in% houston_stp_ids, parameter == "pH") |>
  mutate(date = as.Date(date)) |>
  group_by(ems_id, date) |>
  summarise(ph = mean(result, na.rm = TRUE), .groups = "drop")

temp_stp <- general |>
  filter(ems_id %in% houston_stp_ids, parameter == "Temperature") |>
  mutate(date = as.Date(date)) |>
  group_by(ems_id, date) |>
  summarise(temp_ems = mean(result, na.rm = TRUE), .groups = "drop")

nh3_eval <- nh3_stp |>
  left_join(ph_stp, by = c("ems_id", "date")) |>
  left_join(temp_stp, by = c("ems_id", "date"))

cat("Ammonia samples:", nrow(nh3_eval), "\n")
cat("With pH:", sum(!is.na(nh3_eval$ph)), "\n")
cat("With EMS temp:", sum(!is.na(nh3_eval$temp_ems)), "\n")

# b) Fill missing temp from water-temp-bc S3 parquet (monthly climatology)
cat("Querying water-temp-bc S3 for monthly temp climatology...\n")

con <- DBI::dbConnect(duckdb::duckdb())
DBI::dbExecute(con, "INSTALL httpfs; LOAD httpfs;")

# Query each parquet file separately (different schemas) then combine
s3_files <- c(
  "s3://water-temp-bc/data/realtime_raw_eccc_20221213.parquet",
  "s3://water-temp-bc/data/realtime_raw_20240119.parquet",
  "s3://water-temp-bc/data/realtime_raw_20250728.parquet"
)

temp_list <- lapply(s3_files, function(f) {
  tryCatch(
    DBI::dbGetQuery(con, sprintf("
      SELECT EXTRACT(MONTH FROM Date) AS month, Value AS temp
      FROM '%s'
      WHERE STATION_NUMBER = '08EE003' AND Parameter = '5'
        AND Value > 0 AND Value < 30
    ", f)),
    error = function(e) { cat("Skipping", f, ":", e$message, "\n"); NULL }
  )
})

monthly_temp <- bind_rows(temp_list) |>
  group_by(month) |>
  summarise(temp_monthly = mean(temp, na.rm = TRUE), .groups = "drop")

DBI::dbDisconnect(con)

cat("Monthly temp climatology (08EE003):\n")
print(monthly_temp)

# Join monthly climatology where EMS temp is missing
nh3_eval <- nh3_eval |>
  mutate(month = lubridate::month(date)) |>
  left_join(monthly_temp, by = "month") |>
  mutate(
    temp = coalesce(temp_ems, temp_monthly),
    temp_source = if_else(!is.na(temp_ems), "measured", "monthly_climatology")
  )

cat("After temp fill — with temp:", sum(!is.na(nh3_eval$temp)), "\n")

# c) Calculate BC WQG ammonia limit
nh3_eval <- nh3_eval |>
  filter(!is.na(ph), !is.na(temp)) |>
  mutate(
    wqg_limit = calc_nh3_wqg(temp, ph),
    exceeds = nh3 > wqg_limit,
    station = factor(houston_stp_labels[ems_id], levels = houston_stp_labels)
  )

cat("\nAmmonia guideline evaluation:\n")
cat("Samples evaluated:", nrow(nh3_eval), "\n")
cat("Exceedances:", sum(nh3_eval$exceeds, na.rm = TRUE), "\n")

nh3_eval |>
  group_by(station) |>
  summarise(
    n = n(),
    n_exceed = sum(exceeds, na.rm = TRUE),
    pct_exceed = round(100 * n_exceed / n, 1),
    .groups = "drop"
  ) |>
  print()

# d) Save
write_csv(nh3_eval, "data/processed/ems_ammonia_wqg.csv")
cat("Saved data/processed/ems_ammonia_wqg.csv\n")

# e) Plot — ammonia time series with calculated guideline per sample
p <- nh3_eval |>
  ggplot(aes(x = date)) +
  geom_line(aes(y = wqg_limit), colour = "red3", linetype = "dashed",
            alpha = 0.6, linewidth = 0.5) +
  geom_point(aes(y = nh3, colour = station, shape = exceeds), size = 2, alpha = 0.8) +
  scale_colour_manual(values = get_colours(houston_stp_labels), name = "Station") +
  scale_shape_manual(values = c("FALSE" = 16, "TRUE" = 17),
                     labels = c("Below", "Exceeds"),
                     name = "WQG Status") +
  facet_wrap(~ station, ncol = 1, scales = "free_y") +
  theme_bw(base_size = 11) +
  theme(
    axis.title.x = element_blank(),
    legend.position = "bottom",
    strip.text = element_text(size = 10)
  ) +
  labs(y = "Ammonia-N (mg/L)")

ggsave("fig/ems/houston_stp_ammonia_wqg.png", p, width = 10, height = 9, dpi = 200)
cat("Saved fig/ems/houston_stp_ammonia_wqg.png\n")

cat("\nDone. All EMS plots saved to fig/ems/\n")

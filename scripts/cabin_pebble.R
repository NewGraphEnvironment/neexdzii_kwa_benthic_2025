# cabin_pebble.R
#
# Verify substrate metrics in habitat.csv against pebble count CSVs and
# generate PebbleCount strings for CABIN upload.
#
# Size class boundaries (Wentworth scale, cm):
#   Silt+Clay < 0.2, Sand 0.2–1.6, Pebble 1.6–6.4, Cobble 6.4–25.6, Boulder > 25.6
#
# Usage: Rscript scripts/cabin_pebble.R

library(tidyverse)


# STEP 1 — Load pebble CSVs ---------------------------------------------------

sites <- c("bul01", "bul04", "bul05")

pebbles <- map(sites, \(s) {
  read_csv(paste0("data/processed/cabin/pebble_", s, ".csv"),
           show_col_types = FALSE) |>
    mutate(site = toupper(gsub("bul", "BUL-", s)))
}) |>
  bind_rows()


# STEP 2 — Compute metrics ----------------------------------------------------

classify <- function(d) {
  case_when(
    d <  0.2  ~ "%Silt+Clay",
    d <  1.6  ~ "%Sand",
    d <  6.4  ~ "%Pebble",
    d < 25.6  ~ "%Cobble",
    TRUE       ~ "%Boulder"
  )
}

metrics <- pebbles |>
  group_by(site) |>
  summarise(
    n           = n(),
    D50         = round(median(diameter_cm), 2),
    Dg          = round(exp(mean(log(diameter_cm))), 2),
    Mean        = round(mean(diameter_cm), 2),
    PebbleCount = paste(diameter_cm, collapse = ","),
    .groups = "drop"
  )

# Calculate size class percentages
all_classes <- c("%Silt+Clay", "%Sand", "%Pebble", "%Cobble", "%Boulder")

size_pct <- pebbles |>
  mutate(class = classify(diameter_cm)) |>
  count(site, class) |>
  mutate(pct = round(n / 100 * 100, 1)) |>
  pivot_wider(id_cols = site, names_from = class, values_from = pct,
              values_fill = 0)

# ensure all size class columns exist even if no stones in that class
for (cls in all_classes) {
  if (!cls %in% names(size_pct)) size_pct[[cls]] <- 0
}
size_pct <- select(size_pct, site, all_of(all_classes))

metrics <- metrics |>
  left_join(size_pct, by = "site")


# STEP 3 — Print results ------------------------------------------------------

cat("\n=== Substrate metrics from pebble CSVs ===\n\n")
for (s in unique(metrics$site)) {
  m <- filter(metrics, site == s)
  cat(s, "(n =", m$n, "):\n")
  cat("  D50  =", m$D50, "cm\n")
  cat("  Dg   =", m$Dg, "cm\n")
  cat("  Mean =", m$Mean, "cm\n")
  for (cls in c("%Silt+Clay", "%Sand", "%Pebble", "%Cobble", "%Boulder")) {
    cat(" ", cls, "=", m[[cls]], "%\n")
  }
  cat("  PebbleCount:", substr(m$PebbleCount, 1, 60), "...\n\n")
}


# STEP 4 — Print PebbleCount strings for habitat.csv --------------------------

cat("=== PebbleCount strings (paste into habitat.csv) ===\n\n")
for (s in unique(metrics$site)) {
  m <- filter(metrics, site == s)
  cat(s, ":\n", m$PebbleCount, "\n\n")
}

cat("--- Done ---\n")

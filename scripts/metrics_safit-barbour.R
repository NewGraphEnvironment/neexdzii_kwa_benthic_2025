# metrics_safit-barbour.R
#
# Independently calculate HBI and diversity metrics from raw counts and
# external tolerance databases, then compare to Cordillera's pre-calculated
# values.
#
# Sources:
#   - EPA Barbour et al. Appendix B — tolerance_nw column for BC (primary)
#     (data/raw/barbour_tolerance_nw.csv; originally extracted from PDF
#      in Sheep/R/01a_load_invert_ffg_tolerances.R)
#   - SAFIT tolerance/FFG database (fallback; downloaded fresh from safit.org)
#
# Priority: Barbour NW → SAFIT → family-level fallback (via tsn_parent
# or family name matching). Matches Sheep/R/01b_load_invert.R workflow.
#
# Taxonomy resolution via taxize::gna_verifier() standardizes our names
# against ITIS before matching to Barbour/SAFIT.
#
# Usage: Rscript scripts/metrics_safit-barbour.R

library(tidyverse)
library(readxl)
library(vegan)
library(taxize)


# STEP 1 — Load our raw counts ------------------------------------------------

counts <- read_csv("data/processed/benthic_counts_tidy.csv", show_col_types = FALSE) |>
  mutate(corrected = count * (100 / pct_sampled))

our_taxa <- sort(unique(counts$taxonomy))
cat("Our taxa:", length(our_taxa), "\n")


# STEP 2 — Download SAFIT tolerance database -----------------------------------

safit_url <- "https://safit.org/wp-content/uploads/2025/07/Tolerance_Values_and_Functional_Feeding_Groups.xls"
safit_path <- "data/raw/safit_db.xls"

if (!file.exists(safit_path)) {
  download.file(safit_url, safit_path, mode = "wb", quiet = TRUE)
  cat("Downloaded SAFIT database\n")
} else {
  cat("Using cached SAFIT database:", safit_path, "\n")
}

safit_raw <- read_excel(safit_path, sheet = 1,
                        .name_repair = make.names, col_types = "text")

# Extract lowest-level taxon name (rightmost non-NA in Phylum:Taxon columns)
tax_cols <- select(safit_raw, Phylum:Taxon)
taxon_name <- apply(tax_cols, 1, function(x) {
  vals <- x[!is.na(x)]
  if (length(vals) == 0) NA_character_ else tail(vals, 1)
})

safit <- safit_raw |>
  mutate(taxonomy = str_replace_all(taxon_name, " sp\\.", "")) |>
  rename(tolerance_safit = TolVal, ffg_safit = FFG) |>
  mutate(tolerance_safit = as.numeric(tolerance_safit)) |>
  filter(!is.na(taxonomy), !is.na(tolerance_safit)) |>
  distinct(taxonomy, .keep_all = TRUE) |>
  select(taxonomy, tolerance_safit, ffg_safit)

cat("SAFIT entries with tolerance:", nrow(safit), "\n")


# STEP 3 — Load EPA Barbour NW tolerance values --------------------------------
# Source: Barbour et al. Appendix B (EPA AR-1164.pdf pp. 277-322).
# Original PDF extraction in Sheep/R/01a_load_invert_ffg_tolerances.R.
# Local copy exported from Sheep/data/sheep_database.sqlite for reproducibility.

barbour_full <- read_csv("data/raw/barbour_tolerance_nw.csv", show_col_types = FALSE) |>
  mutate(tolerance_nw = as.numeric(tolerance_nw))

barbour <- barbour_full |>
  filter(!is.na(taxonomy), !is.na(tolerance_nw)) |>
  distinct(taxonomy, .keep_all = TRUE) |>
  select(taxonomy, itis_id, tsn_parent, tolerance_nw, ffg_barbour = ffg_primary)

cat("Barbour entries with tolerance_nw:", nrow(barbour), "\n")


# STEP 4 — Resolve taxonomy via taxize ----------------------------------------
# Standardize our names against ITIS so they match SAFIT/Barbour entries.

cat("\nResolving taxonomy via gna_verifier...\n")

resolved <- gna_verifier(our_taxa) |>
  as_tibble()

# Build lookup: original name → best matched canonical name
tax_xref <- tibble(taxonomy = our_taxa) |>
  left_join(
    resolved |>
      select(submittedName, matchedCanonicalSimple) |>
      distinct(submittedName, .keep_all = TRUE),
    by = c("taxonomy" = "submittedName")
  ) |>
  mutate(
    resolved = coalesce(matchedCanonicalSimple, taxonomy),
    resolved = str_trim(resolved)
  )

n_resolved <- sum(tax_xref$taxonomy != tax_xref$resolved)
cat("Resolved", n_resolved, "names via ITIS\n")

# Show what changed
changed <- tax_xref |> filter(taxonomy != resolved)
if (nrow(changed) > 0) {
  cat("Name changes:\n")
  walk2(changed$taxonomy, changed$resolved, \(orig, res) {
    cat("  ", orig, " → ", res, "\n")
  })
}


# STEP 5 — Match resolved names to Barbour NW + SAFIT -------------------------
# Priority: Barbour NW → SAFIT (matches Sheep/R/01b_load_invert.R workflow)

matched <- tax_xref |>
  # Barbour on resolved name
  left_join(barbour |> select(taxonomy, tol_nw_resolved = tolerance_nw),
            by = c("resolved" = "taxonomy")) |>
  # Barbour on original name
  left_join(barbour |> select(taxonomy, tol_nw_direct = tolerance_nw),
            by = "taxonomy") |>
  # SAFIT on resolved name
  left_join(safit |> select(taxonomy, tol_safit_resolved = tolerance_safit),
            by = c("resolved" = "taxonomy")) |>
  # SAFIT on original name
  left_join(safit |> select(taxonomy, tol_safit_direct = tolerance_safit),
            by = "taxonomy") |>
  mutate(
    tolerance = coalesce(tol_nw_resolved, tol_nw_direct,
                         tol_safit_resolved, tol_safit_direct),
    tol_source = case_when(
      !is.na(tol_nw_resolved)    ~ "Barbour NW (resolved)",
      !is.na(tol_nw_direct)      ~ "Barbour NW (direct)",
      !is.na(tol_safit_resolved) ~ "SAFIT (resolved)",
      !is.na(tol_safit_direct)   ~ "SAFIT (direct)",
      TRUE                        ~ NA_character_
    )
  ) |>
  select(taxonomy, resolved, tolerance, tol_source)

n_matched <- sum(!is.na(matched$tolerance))
cat("\nGenus-level match rate:", n_matched, "/", nrow(matched), "\n")


# STEP 5b — Family-level fallback for unmatched taxa --------------------------
# For taxa still unmatched, look up their family from our counts data and
# match against Barbour/SAFIT at the family level. Also try tsn_parent
# cascade from Barbour (Sheep/R/01b_load_invert.R lines 548-560).

family_lookup <- counts |>
  distinct(taxonomy, family) |>
  filter(!is.na(family))

unmatched <- matched |> filter(is.na(tolerance))

if (nrow(unmatched) > 0) {
  cat("Attempting family-level fallback for", nrow(unmatched), "unmatched taxa...\n")

  family_fallback <- unmatched |>
    select(taxonomy, resolved) |>
    left_join(family_lookup, by = "taxonomy") |>
    # Try family name against Barbour
    left_join(barbour |> select(taxonomy, tol_nw_family = tolerance_nw),
              by = c("family" = "taxonomy")) |>
    # Try family name against SAFIT
    left_join(safit |> select(taxonomy, tol_safit_family = tolerance_safit),
              by = c("family" = "taxonomy")) |>
    mutate(
      tolerance = coalesce(tol_nw_family, tol_safit_family),
      tol_source = case_when(
        !is.na(tol_nw_family)    ~ "Barbour NW (family)",
        !is.na(tol_safit_family) ~ "SAFIT (family)",
        TRUE                      ~ NA_character_
      )
    ) |>
    select(taxonomy, resolved, tolerance, tol_source)

  # Replace unmatched rows with family-level results
  matched <- bind_rows(
    matched |> filter(!is.na(tolerance)),
    family_fallback
  )

  n_family <- sum(!is.na(family_fallback$tolerance))
  cat("Family-level matches:", n_family, "\n")
}

n_matched <- sum(!is.na(matched$tolerance))
cat("\nFinal match rate:", n_matched, "/", nrow(matched), "\n")

by_source <- matched |> filter(!is.na(tol_source)) |> count(tol_source)
cat("By source:\n")
walk2(by_source$tol_source, by_source$n, \(s, n) cat("  ", s, ":", n, "\n"))

unmatched_taxa <- matched |> filter(is.na(tolerance)) |> pull(taxonomy)
if (length(unmatched_taxa) > 0) {
  cat("\nStill unmatched (", length(unmatched_taxa), "):\n")
  cat(paste(" -", unmatched_taxa), sep = "\n")
}


# STEP 6 — Calculate HBI ------------------------------------------------------

tol_lookup <- matched |> filter(!is.na(tolerance)) |> select(taxonomy, tolerance)

hbi_calc <- counts |>
  left_join(tol_lookup, by = "taxonomy") |>
  group_by(site, replicate) |>
  summarise(
    hbi_independent = sum(corrected[!is.na(tolerance)] * tolerance[!is.na(tolerance)]) /
                      sum(corrected[!is.na(tolerance)]),
    n_taxa_with_tol = n_distinct(taxonomy[!is.na(tolerance)]),
    pct_abundance_with_tol = round(
      sum(corrected[!is.na(tolerance)]) / sum(corrected) * 100, 1),
    .groups = "drop"
  )


# STEP 7 — Calculate Shannon and Simpson diversity -----------------------------

sp_matrix <- counts |>
  group_by(site, replicate, taxonomy) |>
  summarise(abundance = sum(corrected), .groups = "drop") |>
  pivot_wider(names_from = taxonomy, values_from = abundance, values_fill = 0)

site_rep <- sp_matrix |> select(site, replicate)
mat <- sp_matrix |> select(-site, -replicate) |> as.matrix()

diversity_calc <- site_rep |>
  mutate(
    shannon_log2 = diversity(mat, index = "shannon", base = 2),
    simpson_1d   = diversity(mat, index = "simpson")
  )


# STEP 8 — Load Cordillera metrics for comparison -----------------------------

cord_metrics <- read_csv("data/processed/metrics_long.csv", show_col_types = FALSE) |>
  mutate(site = str_replace_all(site, " ", "-"))

cord_hbi <- cord_metrics |>
  filter(metric == "Hilsenhoff Biotic Index") |>
  select(site, replicate, hbi_cordillera = value)

cord_shannon <- cord_metrics |>
  filter(metric == "Shannon-Weiner H' (log 2)") |>
  select(site, replicate, shannon_cordillera = value)

cord_simpson <- cord_metrics |>
  filter(metric == "Simpson's Index of Diversity (1 - D)") |>
  select(site, replicate, simpson_cordillera = value)


# STEP 9 — Compare and output -------------------------------------------------

cat("\n")
cat("================================================================\n")
cat("               METRICS VERIFICATION SUMMARY\n")
cat("================================================================\n")

cat("\n--- HBI ---\n")
hbi_compare <- hbi_calc |>
  left_join(cord_hbi, by = c("site", "replicate")) |>
  mutate(
    hbi_independent = round(hbi_independent, 2),
    diff = round(hbi_independent - hbi_cordillera, 2)
  )
print(hbi_compare |>
        select(site, replicate, independent = hbi_independent,
               cordillera = hbi_cordillera, diff, pct_matched = pct_abundance_with_tol),
      n = Inf)
cat("Mean absolute difference:", round(mean(abs(hbi_compare$diff), na.rm = TRUE), 3), "\n")

cat("\n--- Shannon H' (log 2) ---\n")
shannon_compare <- diversity_calc |>
  left_join(cord_shannon, by = c("site", "replicate")) |>
  mutate(
    shannon_log2 = round(shannon_log2, 2),
    diff = round(shannon_log2 - shannon_cordillera, 2)
  )
print(shannon_compare |>
        select(site, replicate, independent = shannon_log2,
               cordillera = shannon_cordillera, diff),
      n = Inf)
cat("Mean absolute difference:", round(mean(abs(shannon_compare$diff), na.rm = TRUE), 3), "\n")

cat("\n--- Simpson 1-D ---\n")
simpson_compare <- diversity_calc |>
  left_join(cord_simpson, by = c("site", "replicate")) |>
  mutate(
    simpson_1d = round(simpson_1d, 3),
    diff = round(simpson_1d - simpson_cordillera, 3)
  )
print(simpson_compare |>
        select(site, replicate, independent = simpson_1d,
               cordillera = simpson_cordillera, diff),
      n = Inf)
cat("Mean absolute difference:", round(mean(abs(simpson_compare$diff), na.rm = TRUE), 3), "\n")


# STEP 10 — Write comparison CSV -----------------------------------------------

comparison <- hbi_compare |>
  select(site, replicate,
         hbi_independent, hbi_cordillera, hbi_diff = diff,
         hbi_pct_matched = pct_abundance_with_tol) |>
  left_join(
    shannon_compare |> select(site, replicate,
                              shannon_independent = shannon_log2,
                              shannon_cordillera, shannon_diff = diff),
    by = c("site", "replicate")
  ) |>
  left_join(
    simpson_compare |> select(site, replicate,
                              simpson_independent = simpson_1d,
                              simpson_cordillera, simpson_diff = diff),
    by = c("site", "replicate")
  )

write_csv(comparison, "data/processed/metrics_comparison.csv")
cat("\nComparison written to data/processed/metrics_comparison.csv\n")

# Write tolerance lookup for reference
tol_out <- matched |>
  select(taxonomy, resolved_name = resolved, tolerance, source = tol_source)
write_csv(tol_out, "data/processed/tolerance_lookup.csv")
cat("Tolerance lookup written to data/processed/tolerance_lookup.csv\n")

cat("\n--- Done ---\n")

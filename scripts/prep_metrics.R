# Parse Cordillera metrics sheet into tidy long format and generate exploratory plots
#
# Input: data/raw/Project_Neexdzi_Kwah_Benthic_Invertebrates.xlsx (Metrics sheet)
# Output: data/processed/metrics_long.csv
#         fig/metrics/*.png

# STEP 1 - Load packages and read data ----------------------------------------

library(tidyverse)
library(readxl)

# STEP 2 - Parse Metrics sheet -------------------------------------------------

raw <- read_excel(
  "data/raw/Project_Neexdzi_Kwah_Benthic_Invertebrates.xlsx",
  sheet = "Metrics",
  col_names = FALSE
)

# Extract sample names from row 8 and dates from row 9
samples <- as.character(raw[8, -1])
dates <- as.character(raw[9, -1])

# Extract metric names and values (rows 12 onward, skip section headers and blanks)
metrics_raw <- raw[12:nrow(raw), ]
names(metrics_raw) <- c("metric", paste0("s", seq_along(samples)))

# Build sample metadata
sample_meta <- tibble(
  sample_id = paste0("s", seq_along(samples)),
  sample = samples,
  date = dates
) |>
  mutate(
    site = str_extract(sample, "BUL \\d+"),
    replicate = str_extract(sample, "[A-C]$")
  )

cat("Sample metadata:\n")
print(sample_meta)

# STEP 3 - Pivot to long format ------------------------------------------------

# Identify section headers and blank rows (no numeric data)
metrics_long <- metrics_raw |>
  # remove section header rows (where all sample columns are NA)
  filter(!if_all(-metric, is.na)) |>
  # remove rows where metric is NA
  filter(!is.na(metric)) |>
  # remove dominant taxon name rows (text not numeric)
  filter(!str_detect(metric, "Dominant Taxon$")) |>
  pivot_longer(
    cols = -metric,
    names_to = "sample_id",
    values_to = "value_raw"
  ) |>
  left_join(sample_meta, by = "sample_id") |>
  mutate(
    # strip % signs and convert to numeric
    is_pct = str_detect(value_raw, "%"),
    value = as.numeric(str_remove(value_raw, "%")),
    # convert percentages from 0-100 to proportion if needed
    # (keep as percentage for display)
  ) |>
  filter(!is.na(value)) |>
  select(site, replicate, sample, date, metric, value, is_pct)

cat("\nParsed", n_distinct(metrics_long$metric), "metrics across",
    n_distinct(metrics_long$sample), "samples\n")
cat("\nMetrics available:\n")
print(distinct(metrics_long, metric))

# STEP 4 - Assign metric categories -------------------------------------------

metrics_long <- metrics_long |>
  mutate(
    category = case_when(
      metric %in% c("Species Richness", "EPT Richness", "Ephemeroptera Richness",
                     "Plecoptera Richness", "Trichoptera Richness",
                     "Chironomidae Richness", "Oligochaeta Richness",
                     "Non-Chiro. Non-Olig. Richness") ~ "Richness",
      metric %in% c("Corrected Abundance", "EPT Abundance") ~ "Abundance",
      str_detect(metric, "Dominant Abundance|Dominant Taxon|Percent Dominance|% \\d") ~ "Dominance",
      metric %in% c("% Ephemeroptera", "% Plecoptera", "% Trichoptera",
                     "% EPT", "% Diptera", "% Oligochaeta", "% Baetidae",
                     "% Chironomidae", "% Odonata") ~ "Community Composition",
      str_detect(metric, "% Predators|% Shredder|% Collector|% Scrapers|% Macrophyte|% Omnivore|% Parasite|% Piercer|% Gatherer|% Unclassified") ~ "FFG",
      str_detect(metric, "Shannon|Simpson") ~ "Diversity",
      metric == "Hilsenhoff Biotic Index" ~ "Biotic Index",
      str_detect(metric, "Univoltine|Semivoltine|Multivoltine") ~ "Voltinism",
      TRUE ~ "Other"
    )
  )

cat("\nMetrics by category:\n")
metrics_long |>
  distinct(category, metric) |>
  arrange(category, metric) |>
  print(n = 50)

# STEP 5 - Save tidy metrics ---------------------------------------------------

dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)
write_csv(metrics_long, "data/processed/metrics_long.csv")
cat("\nWrote data/processed/metrics_long.csv\n")

# STEP 6 - Plot helpers --------------------------------------------------------

dir.create("fig/metrics", showWarnings = FALSE, recursive = TRUE)

# Colour palette for sites (consistent across all plots)
site_cols <- c("BUL 01" = "#1b9e77", "BUL 04" = "#d95f02", "BUL 05" = "#7570b3")

plot_box <- function(data, metrics, title = NULL, y_label = "Value",
                     ncol = 2, free_y = TRUE) {
  d <- data |>
    filter(metric %in% metrics) |>
    mutate(metric = factor(metric, levels = metrics))

  p <- ggplot(d, aes(x = site, y = value)) +
    stat_boxplot(geom = "errorbar", width = 0.4) +
    geom_boxplot(width = 0.6, outlier.shape = NA) +
    geom_jitter(width = 0.1, size = 1.5, alpha = 0.6) +
    theme_bw(base_size = 11) +
    theme(
      axis.title.x = element_blank(),
      strip.text = element_text(size = 9)
    ) +
    labs(y = y_label)

  if (!is.null(title)) p <- p + ggtitle(title)

  if (length(metrics) > 1) {
    p <- p + facet_wrap(~ metric,
                        ncol = ncol,
                        scales = if (free_y) "free_y" else "fixed")
  }
  p
}

plot_stacked_bar <- function(data, metrics, y_label = "Relative abundance (%)",
                             palette = NULL) {
  d <- data |>
    filter(metric %in% metrics) |>
    mutate(metric = factor(metric, levels = rev(metrics))) |>
    group_by(site, metric) |>
    summarise(value = mean(value), .groups = "drop")

  p <- ggplot(d, aes(x = site, y = value, fill = metric)) +
    geom_col(position = "stack", width = 0.7, colour = "grey30", linewidth = 0.2) +
    theme_bw(base_size = 11) +
    theme(
      axis.title.x = element_blank(),
      legend.title = element_blank(),
      legend.position = "right"
    ) +
    labs(y = y_label) +
    guides(fill = guide_legend(reverse = TRUE))

  if (!is.null(palette)) {
    p <- p + scale_fill_manual(values = palette)
  } else {
    p <- p + scale_fill_brewer(palette = "Set3", direction = -1)
  }
  p
}

# STEP 7 - Generate plots -----------------------------------------------------

# --- 7a. Richness (box) ---
p <- plot_box(
  metrics_long,
  c("Species Richness", "EPT Richness", "Ephemeroptera Richness",
    "Plecoptera Richness", "Trichoptera Richness", "Chironomidae Richness"),
  y_label = "Richness (taxa count)"
)
ggsave("fig/metrics/richness.png", p, width = 8, height = 7, dpi = 200)
cat("Saved fig/metrics/richness.png\n")

# --- 7b. Community composition - box (major groups) ---
p <- plot_box(
  metrics_long,
  c("% EPT", "% Ephemeroptera", "% Plecoptera", "% Trichoptera",
    "% Diptera", "% Chironomidae"),
  y_label = "Relative abundance (%)"
)
ggsave("fig/metrics/community_pct.png", p, width = 8, height = 7, dpi = 200)
cat("Saved fig/metrics/community_pct.png\n")

# --- 7c. Community composition - stacked bar ---
comm_metrics <- c("% Ephemeroptera", "% Plecoptera", "% Trichoptera",
                  "% Chironomidae", "% Oligochaeta", "% Odonata")
# Compute "Other" as remainder
comm_data <- metrics_long |>
  filter(metric %in% comm_metrics) |>
  group_by(site, metric) |>
  summarise(value = mean(value), .groups = "drop")
other_vals <- comm_data |>
  group_by(site) |>
  summarise(value = 100 - sum(value), .groups = "drop") |>
  mutate(metric = "Other Diptera & misc.")
comm_data <- bind_rows(comm_data, other_vals)

comm_order <- c("% Ephemeroptera", "% Plecoptera", "% Trichoptera",
                "% Chironomidae", "% Oligochaeta", "% Odonata",
                "Other Diptera & misc.")
comm_palette <- c(
  "% Ephemeroptera"       = "#66c2a5",
  "% Plecoptera"          = "#fc8d62",
  "% Trichoptera"         = "#8da0cb",
  "% Chironomidae"        = "#e78ac3",
  "% Oligochaeta"         = "#a6d854",
  "% Odonata"             = "#ffd92f",
  "Other Diptera & misc." = "#b3b3b3"
)
p <- ggplot(
  comm_data |> mutate(metric = factor(metric, levels = rev(comm_order))),
  aes(x = site, y = value, fill = metric)
) +
  geom_col(position = "stack", width = 0.7, colour = "grey30", linewidth = 0.2) +
  scale_fill_manual(values = comm_palette) +
  guides(fill = guide_legend(reverse = TRUE)) +
  theme_bw(base_size = 11) +
  theme(axis.title.x = element_blank(), legend.title = element_blank()) +
  labs(y = "Mean relative abundance (%)")
ggsave("fig/metrics/community_stacked.png", p, width = 7, height = 5, dpi = 200)
cat("Saved fig/metrics/community_stacked.png\n")

# --- 7d. Diversity & biotic index (box) ---
p <- plot_box(
  metrics_long,
  c("Shannon-Weiner H' (log 2)", "Simpson's Index of Diversity (1 - D)",
    "Hilsenhoff Biotic Index"),
  y_label = "Index value",
  ncol = 3
)
ggsave("fig/metrics/diversity_hbi.png", p, width = 10, height = 4, dpi = 200)
cat("Saved fig/metrics/diversity_hbi.png\n")

# --- 7e. Abundance (box) ---
p <- plot_box(
  metrics_long,
  c("Corrected Abundance", "EPT Abundance"),
  y_label = "Abundance (whole-sample extrapolated count)",
  ncol = 2
)
ggsave("fig/metrics/abundance.png", p, width = 8, height = 4, dpi = 200)
cat("Saved fig/metrics/abundance.png\n")

# --- 7f. FFG composition - box ---
p <- plot_box(
  metrics_long,
  c("% Collector-Gatherers", "% Collector-Filterer", "% Scrapers",
    "% Predators", "% Shredder-Herbivores"),
  y_label = "Relative abundance (%)",
  ncol = 3
)
ggsave("fig/metrics/ffg.png", p, width = 9, height = 5, dpi = 200)
cat("Saved fig/metrics/ffg.png\n")

# --- 7g. FFG composition - stacked bar ---
ffg_order <- c("% Collector-Gatherers", "% Collector-Filterer", "% Scrapers",
               "% Predators", "% Shredder-Herbivores", "% Macrophyte-Herbivore",
               "% Omnivore", "% Parasite", "% Piercer-Herbivore", "% Unclassified")
ffg_palette <- c(
  "% Collector-Gatherers"  = "#66c2a5",
  "% Collector-Filterer"   = "#fc8d62",
  "% Scrapers"             = "#8da0cb",
  "% Predators"            = "#e78ac3",
  "% Shredder-Herbivores"  = "#a6d854",
  "% Macrophyte-Herbivore" = "#ffd92f",
  "% Omnivore"             = "#e5c494",
  "% Parasite"             = "#b3b3b3",
  "% Piercer-Herbivore"    = "#1b9e77",
  "% Unclassified"         = "#999999"
)
p <- plot_stacked_bar(
  metrics_long,
  ffg_order,
  palette = ffg_palette
)
ggsave("fig/metrics/ffg_stacked.png", p, width = 8, height = 5, dpi = 200)
cat("Saved fig/metrics/ffg_stacked.png\n")

# --- 7h. FFG richness (box) ---
ffg_rich <- c("Collector-Gatherers Richness", "CF Richness", "Scrapers Richness",
              "Predators Richness", "Shredder-Herbivores Richness")
p <- plot_box(
  metrics_long,
  ffg_rich,
  y_label = "Richness (taxa count)",
  ncol = 3
)
ggsave("fig/metrics/ffg_richness.png", p, width = 9, height = 5, dpi = 200)
cat("Saved fig/metrics/ffg_richness.png\n")

# --- 7i. Dominance (box) ---
p <- plot_box(
  metrics_long,
  c("Percent Dominance", "1st Dominant Abundance",
    "2nd Dominant Abundance", "3rd Dominant Abundance"),
  y_label = "Value",
  ncol = 2
)
ggsave("fig/metrics/dominance.png", p, width = 8, height = 6, dpi = 200)
cat("Saved fig/metrics/dominance.png\n")

# --- 7j. Voltinism - stacked bar ---
volt_order <- c("% Univoltine", "% Semivoltine", "% Multivoltine")
volt_palette <- c(
  "% Univoltine"   = "#8da0cb",
  "% Semivoltine"  = "#fc8d62",
  "% Multivoltine" = "#66c2a5"
)
p <- plot_stacked_bar(
  metrics_long,
  volt_order,
  palette = volt_palette
)
ggsave("fig/metrics/voltinism_stacked.png", p, width = 6, height = 5, dpi = 200)
cat("Saved fig/metrics/voltinism_stacked.png\n")

# --- 7k. Voltinism - box ---
p <- plot_box(
  metrics_long,
  c("% Univoltine", "% Semivoltine", "% Multivoltine"),
  y_label = "Relative abundance (%)",
  ncol = 3
)
ggsave("fig/metrics/voltinism.png", p, width = 9, height = 4, dpi = 200)
cat("Saved fig/metrics/voltinism.png\n")

# --- 7l. Minor community groups (box) ---
p <- plot_box(
  metrics_long,
  c("% Oligochaeta", "% Odonata", "% Baetidae"),
  y_label = "Relative abundance (%)",
  ncol = 3
)
ggsave("fig/metrics/community_minor.png", p, width = 9, height = 4, dpi = 200)
cat("Saved fig/metrics/community_minor.png\n")

cat("\nDone. All plots saved to fig/metrics/\n")

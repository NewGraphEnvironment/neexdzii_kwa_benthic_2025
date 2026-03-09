# sort_photos.R
#
# Reads EXIF metadata from field photos on OneDrive and copies fall benthic
# sampling photos into data/photos/{site}/ directories based on sampling date.
#
# Sampling dates (from sites_benthic.csv):
#   BUL-05: 2025-09-28 (+ return visit 2025-09-29)
#   BUL-04: 2025-10-02
#   BUL-01: 2025-10-03
#
# Usage: Rscript scripts/sort_photos.R

library(exifr)
library(dplyr)
library(readr)
library(stringr)

# --- Source and destination --------------------------------------------------

photo_src <- "/Users/airvine/Library/CloudStorage/OneDrive-Personal/Projects/2025-079-sern-ow-neexdzi-kwa/data/photos/ai"
photo_dst <- "data/photos"

# --- Read EXIF metadata ------------------------------------------------------

photos <- list.files(photo_src, full.names = TRUE, pattern = "[.]JPG$")
meta <- read_exif(photos, tags = c("FileName", "DateTimeOriginal", "GPSLatitude", "GPSLongitude"))

# --- Filter to fall benthic trip and assign sites by date --------------------

fall <- meta |>
  mutate(date = substr(DateTimeOriginal, 1, 10)) |>
  filter(date >= "2025:09:28" & date <= "2025:10:03") |>
  mutate(site = case_when(
    date == "2025:09:28" ~ "BUL-05",
    date == "2025:09:29" ~ "BUL-05",
    date == "2025:10:02" ~ "BUL-04",
    date == "2025:10:03" ~ "BUL-01"
  ))

cat("Fall benthic photos:", nrow(fall), "\n")
fall |> count(site) |> print()

# --- Copy to site directories ------------------------------------------------

for (s in unique(fall$site)) {
  dir.create(file.path(photo_dst, s), recursive = TRUE, showWarnings = FALSE)
}

copied <- 0
for (i in seq_len(nrow(fall))) {
  src <- fall$SourceFile[i]
  dst <- file.path(photo_dst, fall$site[i], fall$FileName[i])
  if (!file.exists(dst)) {
    file.copy(src, dst)
    copied <- copied + 1
  }
}

cat("Copied", copied, "new photos to", photo_dst, "\n")
cat("Skipped", nrow(fall) - copied, "already present\n")

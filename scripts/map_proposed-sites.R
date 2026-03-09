# map_proposed-sites.R
#
# Produces fig/map_proposed-sites.png — existing 2025 sites plus proposed
# expansion sites for the monitoring network recommendation.
#
# Adapted from map_benthic-sites.R. Run data_map-study-area.R first to
# populate data/spatial/ cache.
#
# Usage: Rscript scripts/map_proposed-sites.R

library(sf)
library(tmap)
library(maptiles)
library(dplyr)
library(readr)
library(stringr)
library(magick)
library(bcmaps)
sf_use_s2(FALSE)

logo_path <- "fig/logo_newgraph/BLACK/PNG/nge-icon_black.png"
cache     <- "data/spatial"

# --- Load cached layers ---------------------------------------------------

watersheds <- readRDS(file.path(cache, "watersheds.rds"))
streams    <- readRDS(file.path(cache, "streams.rds"))
lakes      <- readRDS(file.path(cache, "lakes.rds"))
roads      <- readRDS(file.path(cache, "roads.rds"))
railway    <- readRDS(file.path(cache, "railway.rds"))

neexdzii <- watersheds |> filter(watershed == "Neexdzii Kwa")

# --- Subbasins -------------------------------------------------------------

subbasins_src  <- "/Users/airvine/Projects/repo/restoration_wedzin_kwa_2024/data/lulc/subbasins.gpkg"
subbasins_local <- file.path(cache, "subbasins.gpkg")
file.copy(subbasins_src, subbasins_local, overwrite = TRUE)

subbasins <- st_read(subbasins_local, quiet = TRUE) |>
  st_transform(4326) |>
  mutate(label = paste0(str_extract(gnis_name, "^\\w+"), " ", break_id))

# --- Existing 2025 sites -------------------------------------------------

sites_csv <- read_csv("data/raw/sites_benthic.csv", show_col_types = FALSE)
sites <- st_as_sf(sites_csv, coords = c("lon", "lat"), crs = 4326)

# --- Proposed expansion sites ---------------------------------------------
# Coordinates derived from BC Freshwater Atlas (fwapg) stream network

proposed <- st_sf(
  site = c(
    "Buck Cr below\nBessemer",
    "Lower Buck Cr",
    "Upper Foxy Cr\n(mine side)",
    "Maxan Cr near\nBulkley Lake",
    "Mainstem below\nRichfield confluence"
  ),
  rationale = c(
    "Mine drainage — south side of divide",
    "Chinook spawning/rearing; integrates upstream",
    "Mine drainage — north side of divide",
    "Forestry and agricultural influences",
    "Legacy concentrate shed; chinook; fish passage"
  ),
  geometry = st_sfc(
    st_point(c(-126.3164, 54.1607)),  # Buck Cr at Bessemer mouth (FWA BLK 360844271)
    st_point(c(-126.6540, 54.4019)),  # Buck Cr ~500m above Bulkley mouth (FWA BLK 360886221)
    st_point(c(-126.3262, 54.2214)),  # Foxy Cr upper reach near mine (FWA BLK 360877225)
    st_point(c(-126.1233, 54.3830)),  # Maxan Cr mouth (FWA BLK 360881038)
    st_point(c(-126.3441, 54.5076)),  # Bulkley mainstem below Richfield (FWA measure 217489)
    crs = 4326
  )
)

# --- Point sources --------------------------------------------------------

point_sources <- st_sf(
  name = c("Knockholt Landfill", "Houston WWTP", "Equity Silver Mine",
           "Richfield Loop\nconcentrate shed"),
  type = c("Landfill", "Wastewater", "Mine", "Legacy"),
  geometry = st_sfc(
    st_point(c(-126.527192, 54.440469)),
    st_point(c(-126.670421, 54.397655)),
    st_point(c(-126.268, 54.195)),
    st_point(c(-126.3410, 54.5106)),  # Richfield Cr near Bulkley confluence
    crs = 4326
  )
)

# --- Feature derivations --------------------------------------------------

roads_dissolved <- roads |>
  filter(!is.na(route)) |>
  group_by(route) |>
  summarise(geom = st_union(geom), .groups = "drop") |>
  mutate(label = paste0("Hwy ", route))

# Expand bbox to include mine area and Maxan/Foxy
bbox <- st_bbox(neexdzii)
bbox["ymax"] <- bbox["ymax"] + 0.06
bbox["ymin"] <- bbox["ymin"] - 0.08
bbox["xmin"] <- bbox["xmin"] - 0.04
bbox["xmax"] <- bbox["xmax"] + 0.04

bbox_clip_sf <- st_as_sfc(bbox) |> st_set_crs(4326)

streams_clip <- streams |> st_make_valid() |> st_crop(bbox_clip_sf)
lakes_clip   <- lakes |> st_make_valid() |> st_crop(bbox_clip_sf)

stream_label_pts <- streams_clip |>
  filter(!is.na(gnis_name) & stream_order >= 5) |>
  group_by(gnis_name) |>
  summarise(geom = st_union(geom), .groups = "drop") |>
  mutate(geometry = st_point_on_surface(geom)) |>
  st_set_geometry("geometry") |>
  st_set_crs(4326)

lake_labels <- lakes_clip[!is.na(lakes_clip$name) & lakes_clip$area_km2 > 1, ]

towns <- st_sf(
  name = c("Houston", "Topley"),
  geometry = st_sfc(
    st_point(c(-126.648, 54.398)),
    st_point(c(-126.246, 54.566)),
    crs = 4326
  )
)

# --- Basemap --------------------------------------------------------------

bbox_sf <- st_as_sfc(bbox) |> st_set_crs(4326)
relief  <- get_tiles(bbox_sf, provider = "Esri.WorldShadedRelief", zoom = 10, crop = TRUE)
basemap_stars <- stars::st_as_stars(relief)

# --- Map ------------------------------------------------------------------

tmap_mode("plot")

m <- tm_shape(basemap_stars, bbox = bbox) +
  tm_rgb() +

  # Watershed boundary
  tm_shape(neexdzii) +
  tm_polygons(fill = "#a8c8e0", fill_alpha = 0.25,
              col = "#2c3e50", lwd = 2.0) +

  # Subbasins
  tm_shape(subbasins) +
  tm_polygons(
    fill = "gnis_name",
    fill.scale = tm_scale_categorical(values = "BrBG"),
    fill_alpha = 0.3,
    col = "#5d4037",
    lwd = 1.0,
    fill.legend = tm_legend(show = FALSE)
  ) +
  tm_text("label", size = 0.50, col = "#5d4037", fontface = "italic") +

  # Lakes
  tm_shape(lakes_clip) +
  tm_polygons(fill = "#c6ddf0", col = "#7ba7cc", lwd = 0.4, fill_alpha = 0.85) +
  tm_shape(lake_labels) +
  tm_text("name", size = 0.55, col = "#1a5276", fontface = "italic") +

  # Streams
  tm_shape(streams_clip |> filter(stream_order >= 4)) +
  tm_lines(col = "#7ba7cc", lwd = 0.4) +
  tm_shape(streams_clip |> filter(stream_order >= 5)) +
  tm_lines(col = "#7ba7cc", lwd = 0.8) +
  tm_shape(stream_label_pts) +
  tm_text("gnis_name", size = 0.60, col = "#1a5276", fontface = "italic") +

  # Railway
  tm_shape(railway) +
  tm_lines(col = "black", lwd = 1.2) +
  tm_shape(railway) +
  tm_lines(col = "white", lwd = 0.6, lty = "42") +

  # Roads
  tm_shape(roads |> filter(road_type == "RC2")) +
  tm_lines(col = "#999999", lwd = 0.5) +
  tm_shape(roads_dissolved |> filter(route == "16")) +
  tm_lines(col = "#c0392b", lwd = 2.0) +
  tm_shape(roads_dissolved |> filter(route != "16")) +
  tm_lines(col = "#e67e22", lwd = 1.2) +

  # Point sources
  tm_shape(point_sources) +
  tm_symbols(
    fill = "#e74c3c",
    shape = 23,
    size = 0.8,
    col = "grey20",
    lwd = 0.5
  ) +
  tm_text("name", size = 0.50, col = "#8b0000",
          fontface = "italic",
          options = opt_tm_text(
            point.label = TRUE,
            point.label.method = "SANN",
            point.label.gap = 0.3,
            shadow = TRUE
          )) +

  # Existing 2025 benthic sites
  tm_shape(sites) +
  tm_symbols(
    fill = "#1f78b4",
    shape = 24,
    size = 0.9,
    col = "grey20",
    lwd = 0.5
  ) +
  tm_text("site", size = 0.65, col = "grey20",
          fontface = "bold",
          options = opt_tm_text(
            point.label = TRUE,
            point.label.method = "SANN",
            point.label.gap = 0.3,
            shadow = TRUE
          )) +

  # Proposed expansion sites
  tm_shape(proposed) +
  tm_symbols(
    fill = "#c0392b",
    shape = 21,
    size = 0.9,
    col = "grey20",
    lwd = 0.5
  ) +
  tm_text("site", size = 0.55, col = "#8b0000",
          fontface = "bold",
          options = opt_tm_text(
            point.label = TRUE,
            point.label.method = "SANN",
            point.label.gap = 0.3,
            shadow = TRUE
          )) +

  # Towns
  tm_shape(towns) +
  tm_dots(fill = "black", size = 0.30) +
  tm_text("name", size = 0.65, xmod = 0.8, ymod = -0.6,
          col = "grey10", fontface = "bold") +

  # Scale bar
  tm_scalebar(breaks = c(0, 10, 20),
              position = c("left", "bottom"),
              text.size = 0.6) +

  tm_logo(logo_path, position = c("left", "top"), height = 2.2) +

  # Legend
  tm_add_legend(
    type = "symbols",
    labels = c("2025 benthic site", "Proposed expansion site",
               "Potential point source"),
    fill   = c("#1f78b4", "#c0392b", "#e74c3c"),
    shape  = c(24, 21, 23),
    size   = c(0.9, 0.9, 0.8),
    col    = c("grey20", "grey20", "grey20")
  ) +
  tm_add_legend(
    type = "lines",
    labels = c("Highway 16", "Secondary highway", "Collector road", "Railway (CN)"),
    col  = c("#c0392b", "#e67e22", "#999999", "black"),
    lwd  = c(2, 1.2, 0.5, 1.2)
  ) +

  tm_layout(
    frame = TRUE,
    inner.margins  = c(0.005, 0.005, 0.005, 0.005),
    outer.margins  = c(0.002, 0.002, 0.002, 0.002),
    legend.position = c("right", "top"),
    legend.frame    = TRUE,
    legend.bg.color = "white",
    legend.bg.alpha = 0.85
  )

dir.create("fig", showWarnings = FALSE)
tmap_save(m, "fig/map_proposed-sites.png", width = 8.5, height = 11, dpi = 200)
system("sips -s dpiWidth 200.0 -s dpiHeight 200.0 fig/map_proposed-sites.png")

# --- Keymap inset ---------------------------------------------------------

bc_albers   <- bcmaps::bc_bound()
bbox_albers <- st_as_sfc(bbox) |> st_set_crs(4326) |> st_transform(3005)

keymap_tmp <- tempfile(fileext = ".png")
png(keymap_tmp, width = 200, height = 220, bg = "white")
par(mar = c(0, 0, 0, 0))
plot(st_geometry(bc_albers), col = "#e8e8e8", border = "#999999", lwd = 0.8, axes = FALSE)
plot(st_geometry(bbox_albers), col = adjustcolor("#c0392b", alpha.f = 0.45),
     border = "#c0392b", lwd = 2.5, add = TRUE)
box(col = "#999999", lwd = 1)
invisible(dev.off())

main_img   <- image_read("fig/map_proposed-sites.png")
keymap_img <- image_read(keymap_tmp) |>
  image_resize("200x220") |>
  image_border("white", "2x2") |>
  image_border("#aaaaaa", "1x1")

info   <- image_info(main_img)
km_inf <- image_info(keymap_img)

margin_px <- 25
ox <- info$width  - km_inf$width  - margin_px
oy <- info$height - km_inf$height - margin_px

main_img |>
  image_composite(keymap_img, offset = paste0("+", ox, "+", oy)) |>
  image_write("fig/map_proposed-sites.png")

system("sips -s dpiWidth 200.0 -s dpiHeight 200.0 fig/map_proposed-sites.png")
cat("Saved to fig/map_proposed-sites.png\n")

# map_study-area.R
#
# Produces fig/map_study-area.png from cached spatial layers in data/spatial/.
# Run data_map-study-area.R first (requires DB) to populate the cache.
#
# Usage: Rscript scripts/map_study-area.R

library(sf)
library(tmap)
library(maptiles)
library(dplyr)
library(magick)
library(bcmaps)
sf_use_s2(FALSE)

logo_path <- "fig/logo_newgraph/BLACK/PNG/nge-icon_black.png"
cache     <- "data/spatial"

# --- Load cached layers --------------------------------------------------

watersheds <- readRDS(file.path(cache, "watersheds.rds"))
streams    <- readRDS(file.path(cache, "streams.rds"))
lakes      <- readRDS(file.path(cache, "lakes.rds"))
roads      <- readRDS(file.path(cache, "roads.rds"))
railway    <- readRDS(file.path(cache, "railway.rds"))

# --- Feature derivations -------------------------------------------------

total <- st_union(watersheds)

# Per-feature label offsets for watershed sub-region labels
watersheds <- watersheds |>
  mutate(
    lbl_xmod = case_when(watershed == "Neexdzii Kwa" ~ -0.8, TRUE ~ 0),
    lbl_ymod = case_when(watershed == "Neexdzii Kwa" ~  0.6, TRUE ~ 0)
  )

# Dissolved roads by route
roads_dissolved <- roads |>
  filter(!is.na(route)) |>
  group_by(route) |>
  summarise(geom = st_union(geom), .groups = "drop") |>
  mutate(label = paste0("Hwy ", route))

# Stream label points (7th order+ named)
stream_label_pts <- streams |>
  filter(!is.na(gnis_name) & stream_order >= 7) |>
  group_by(gnis_name) |>
  summarise(geom = st_union(geom), .groups = "drop") |>
  mutate(geometry = st_point_on_surface(geom)) |>
  st_set_geometry("geometry") |>
  st_set_crs(4326)

# Lake labels (>3 km²)
lake_labels <- lakes[!is.na(lakes$name) & lakes$area_km2 > 3, ]

# Highway label points (non-16 labels)
road_label_pts <- roads_dissolved |>
  filter(route != "16") |>
  mutate(geometry = st_point_on_surface(geom)) |>
  st_set_geometry("geometry") |>
  st_set_crs(4326)

# Towns
towns <- st_sf(
  name = c("Houston", "Smithers", "Burns Lake"),
  geometry = st_sfc(
    st_point(c(-126.648, 54.398)),
    st_point(c(-127.176, 54.779)),
    st_point(c(-125.764, 54.230)),
    crs = 4326
  )
)

# --- Bounding box --------------------------------------------------------

bbox <- st_bbox(total)
bbox["ymax"] <- bbox["ymax"] + 0.05
bbox["ymin"] <- bbox["ymin"] - 0.08
bbox["xmin"] <- bbox["xmin"] - 0.05
bbox["xmax"] <- bbox["xmax"] + 0.30

# --- Basemap: hillshade --------------------------------------------------

bbox_sf <- st_as_sfc(bbox) |> st_set_crs(4326)
relief  <- get_tiles(bbox_sf, provider = "Esri.WorldShadedRelief", zoom = 9, crop = TRUE)

basemap_stars <- stars::st_as_stars(relief)

# --- Map -----------------------------------------------------------------

tmap_mode("plot")

m <- tm_shape(basemap_stars, bbox = bbox) +
  tm_rgb() +

  # Three-zone watershed polygons
  tm_shape(watersheds) +
  tm_polygons(
    fill = "watershed",
    fill.scale = tm_scale_categorical(
      values = c(
        "Upper Wedzin Kwa\n(Morice)" = "#4a85b5",
        "Neexdzii Kwa"               = "#a8c8e0",
        "Lower Wedzin Kwa"           = "#7eb8d4"
      )
    ),
    fill_alpha = 0.40,
    col = "#2c3e50",
    lwd = 1.8,
    fill.legend = tm_legend(show = FALSE)
  ) +

  # Lakes
  tm_shape(lakes) +
  tm_polygons(fill = "#c6ddf0", col = "#7ba7cc", lwd = 0.4, fill_alpha = 0.85) +
  tm_shape(lake_labels) +
  tm_text("name", size = 0.65, col = "#1a5276", fontface = "italic") +

  # Streams
  tm_shape(streams) +
  tm_lines(col = "#7ba7cc", lwd = 0.4) +
  tm_shape(stream_label_pts) +
  tm_text("gnis_name", size = 0.70, col = "#1a5276", fontface = "italic") +

  # Railway
  tm_shape(railway) +
  tm_lines(col = "black", lwd = 1.2) +
  tm_shape(railway) +
  tm_lines(col = "white", lwd = 0.6, lty = "42") +

  # Roads
  tm_shape(roads_dissolved |> filter(route == "16")) +
  tm_lines(col = "#c0392b", lwd = 2.0) +
  tm_shape(roads_dissolved |> filter(route != "16")) +
  tm_lines(col = "#e67e22", lwd = 1.4) +
  tm_shape(road_label_pts) +
  tm_text("label", size = 0.32, col = "#7f3b00", fontface = "bold",
          xmod = 0.0, ymod = 0.5,
          options = opt_tm_text(shadow = TRUE)) +

  # Sub-region labels
  tm_shape(watersheds) +
  tm_text("watershed", size = 0.65, fontface = "bold", col = "#1a3c5e",
          xmod = "lbl_xmod", ymod = "lbl_ymod") +

  # Towns
  tm_shape(towns) +
  tm_dots(fill = "black", size = 0.40) +
  tm_text("name", size = 0.70, xmod = 0.9, ymod = -0.7,
          col = "grey10", fontface = "bold") +

  # Scale bar
  tm_scalebar(breaks = c(0, 20, 40, 60),
              position = c("right", "bottom"),
              text.size = 0.5) +

  tm_logo(logo_path, position = c("right", "top"), height = 2) +

  # Legend
  tm_add_legend(
    type = "lines",
    labels = c("Highway 16", "Secondary highway", "Railway (CN)"),
    col  = c("#c0392b", "#e67e22", "black"),
    lwd  = c(2, 1.4, 1.2)
  ) +

  tm_layout(
    frame = TRUE,
    inner.margins  = c(0, 0, 0, 0),
    outer.margins  = c(0.002, 0.002, 0.002, 0.002),
    legend.position = c("left", "top"),
    legend.frame    = TRUE,
    legend.bg.color = "white",
    legend.bg.alpha = 0.85
  )

dir.create("fig", showWarnings = FALSE)
tmap_save(m, "fig/map_study-area.png", width = 10, height = 12.1, dpi = 200)
system("sips -s dpiWidth 200.0 -s dpiHeight 200.0 fig/map_study-area.png")

# --- Keymap inset (BC province + study area bbox) ------------------------

bc_albers  <- bcmaps::bc_bound()
bbox_albers <- st_as_sfc(bbox) |> st_set_crs(4326) |> st_transform(3005)

keymap_tmp <- tempfile(fileext = ".png")
png(keymap_tmp, width = 200, height = 220, bg = "white")
par(mar = c(0, 0, 0, 0))
plot(st_geometry(bc_albers), col = "#e8e8e8", border = "#999999", lwd = 0.8, axes = FALSE)
plot(st_geometry(bbox_albers), col = adjustcolor("#c0392b", alpha.f = 0.45),
     border = "#c0392b", lwd = 2.5, add = TRUE)
box(col = "#999999", lwd = 1)
invisible(dev.off())

main_img   <- image_read("fig/map_study-area.png")
keymap_img <- image_read(keymap_tmp) |>
  image_resize("300x330") |>
  image_border("white", "4x4") |>
  image_border("#aaaaaa", "1x1")

info   <- image_info(main_img)
km_inf <- image_info(keymap_img)

ox <- info$width  - km_inf$width  - 140
oy <- info$height - km_inf$height - 160

main_img |>
  image_composite(keymap_img, offset = paste0("+", ox, "+", oy)) |>
  image_write("fig/map_study-area.png")

system("sips -s dpiWidth 200.0 -s dpiHeight 200.0 fig/map_study-area.png")
cat("Saved to fig/map_study-area.png\n")

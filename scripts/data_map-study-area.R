# data_map-study-area.R
#
# Queries bcfishpass DB and caches spatial layers used by map_study-area.R.
# Run once whenever source data changes. Outputs go to data/spatial/.
# Requires SSH tunnel to newgraph DB on port 63333 (see db-newgraph skill)
#
# Usage: Rscript scripts/data_map-study-area.R

library(sf)
library(dplyr)
sf_use_s2(FALSE)

conn <- DBI::dbConnect(
  RPostgres::Postgres(),
  host = "localhost", port = 63333,
  dbname = "bcfishpass", user = "newgraph"
)

out <- "data/spatial"
dir.create(out, showWarnings = FALSE, recursive = TRUE)

# --- Watershed boundaries ------------------------------------------------

morice <- sf::st_read(conn, query = "
  SELECT 'Upper Wedzin Kwa\n(Morice)' as watershed,
         ST_Area(geom) / 1e6 as area_km2,
         ST_Transform(ST_Simplify(geom, 200), 4326) as geom
  FROM whse_basemapping.fwa_watershed_groups_poly
  WHERE watershed_group_code = 'MORR'
")

bulk <- sf::st_read(conn, query = "
  SELECT 'BULK' as watershed,
         ST_Area(geom) / 1e6 as area_km2,
         ST_Transform(ST_Simplify(geom, 200), 4326) as geom
  FROM whse_basemapping.fwa_watershed_groups_poly
  WHERE watershed_group_code = 'BULK'
")

upstream_confluence <- sf::st_read(conn, query = "
  SELECT ST_Transform(ST_Simplify(geom, 200), 4326) as geom,
         ST_Area(geom) / 1e6 as area_km2
  FROM fwa_watershedatmeasure(360873822, 166030.4)
")

neexdzii_kwa <- st_difference(upstream_confluence, morice) |>
  st_make_valid() |>
  mutate(watershed = "Neexdzii Kwa")

lower_wk <- st_difference(bulk, st_union(neexdzii_kwa)) |>
  st_make_valid() |>
  mutate(watershed = "Lower Wedzin Kwa")

watersheds <- rbind(
  st_sf(watershed = "Upper Wedzin Kwa\n(Morice)", geometry = morice$geom),
  st_sf(watershed = "Neexdzii Kwa",               geometry = neexdzii_kwa$geom),
  st_sf(watershed = "Lower Wedzin Kwa",            geometry = lower_wk$geom)
)

saveRDS(watersheds, file.path(out, "watersheds.rds"))
message("Saved watersheds")

# --- Streams (5th order+) -----------------------------------------------

streams <- sf::st_read(conn, query = "
  WITH ws AS (
    SELECT ST_Union(geom) as geom
    FROM whse_basemapping.fwa_watershed_groups_poly
    WHERE watershed_group_code IN ('BULK', 'MORR')
  )
  SELECT s.gnis_name,
         s.stream_order,
         ST_Transform(ST_Simplify(ST_Intersection(s.geom, ws.geom), 100), 4326) as geom
  FROM whse_basemapping.fwa_stream_networks_sp s, ws
  WHERE s.watershed_group_code IN ('BULK', 'MORR')
    AND s.stream_order >= 5
    AND ST_Intersects(s.geom, ws.geom)
")
saveRDS(streams, file.path(out, "streams.rds"))
message("Saved streams")

# --- Lakes ---------------------------------------------------------------

lakes <- sf::st_read(conn, query = "
  WITH ws AS (
    SELECT ST_Union(geom) as geom
    FROM whse_basemapping.fwa_watershed_groups_poly
    WHERE watershed_group_code IN ('BULK', 'MORR')
  )
  SELECT l.gnis_name_1 as name,
         ST_Transform(ST_Simplify(l.geom, 100), 4326) as geom,
         ST_Area(l.geom) / 1e6 as area_km2
  FROM whse_basemapping.fwa_lakes_poly l, ws
  WHERE ST_Intersects(l.geom, ws.geom)
    AND ST_Area(l.geom) > 5e5
")
saveRDS(lakes, file.path(out, "lakes.rds"))
message("Saved lakes")

# --- Roads (highway + arterial) -----------------------------------------

roads <- sf::st_read(conn, query = "
  WITH ws AS (
    SELECT ST_Union(geom) as geom
    FROM whse_basemapping.fwa_watershed_groups_poly
    WHERE watershed_group_code IN ('BULK', 'MORR')
  )
  SELECT t.transport_line_type_code as road_type,
         t.highway_route_1 as route,
         ST_Transform(ST_Simplify(t.geom, 100), 4326) as geom
  FROM whse_basemapping.transport_line t, ws
  WHERE t.transport_line_type_code IN ('RH1', 'RA1', 'RA2', 'RC2')
    AND ST_Intersects(t.geom, ST_Expand(ws.geom, 20000))
")
saveRDS(roads, file.path(out, "roads.rds"))
message("Saved roads")

# --- Railway -------------------------------------------------------------

railway <- sf::st_read(conn, query = "
  WITH ws AS (
    SELECT ST_Union(geom) as geom
    FROM whse_basemapping.fwa_watershed_groups_poly
    WHERE watershed_group_code IN ('BULK', 'MORR')
  )
  SELECT r.track_classification,
         ST_Transform(ST_Simplify(r.geom, 100), 4326) as geom
  FROM whse_basemapping.gba_railway_tracks_sp r, ws
  WHERE r.track_classification = 'Main'
    AND ST_Intersects(r.geom, ST_Expand(ws.geom, 20000))
") |>
  summarise(geom = st_union(geom))
saveRDS(railway, file.path(out, "railway.rds"))
message("Saved railway")

DBI::dbDisconnect(conn)
message("\nAll spatial layers cached to ", out)

# data_map-study-area.R
#
# Queries bcfishpass DB and caches spatial layers for the study area map.
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

# --- Neexdzii Kwa watershed ------------------------------------------------
# Delineate upstream of Houston (Morice confluence) on the Bulkley River
# blk 360873822, measure 164908 = Morice-Bulkley confluence

morice <- sf::st_read(conn, query = "
  SELECT ST_Area(geom) / 1e6 as area_km2,
         ST_Transform(ST_Simplify(geom, 200), 4326) as geom
  FROM whse_basemapping.fwa_watershed_groups_poly
  WHERE watershed_group_code = 'MORR'
")

upstream_confluence <- sf::st_read(conn, query = "
  SELECT ST_Transform(ST_Simplify(geom, 200), 4326) as geom,
         ST_Area(geom) / 1e6 as area_km2
  FROM fwa_watershedatmeasure(360873822, 164908)
")

neexdzii_kwa <- st_difference(upstream_confluence, morice) |>
  st_make_valid() |>
  mutate(watershed = "Neexdzii Kwa")

saveRDS(neexdzii_kwa, file.path(out, "neexdzii_kwa.rds"))
message("Saved neexdzii_kwa")

# --- Streams (4th order+) within Neexdzii Kwa ------------------------------

streams <- sf::st_read(conn, query = "
  WITH ws AS (
    SELECT ST_Difference(
      (SELECT geom FROM fwa_watershedatmeasure(360873822, 164908)),
      (SELECT geom FROM whse_basemapping.fwa_watershed_groups_poly
       WHERE watershed_group_code = 'MORR')
    ) as geom
  )
  SELECT s.gnis_name,
         s.stream_order,
         ST_Transform(ST_Simplify(ST_Intersection(s.geom, ws.geom), 50), 4326) as geom
  FROM whse_basemapping.fwa_stream_networks_sp s, ws
  WHERE s.watershed_group_code = 'BULK'
    AND s.stream_order >= 4
    AND ST_Intersects(s.geom, ws.geom)
")
saveRDS(streams, file.path(out, "streams.rds"))
message("Saved streams")

# --- Lakes within Neexdzii Kwa --------------------------------------------

lakes <- sf::st_read(conn, query = "
  WITH ws AS (
    SELECT ST_Difference(
      (SELECT geom FROM fwa_watershedatmeasure(360873822, 164908)),
      (SELECT geom FROM whse_basemapping.fwa_watershed_groups_poly
       WHERE watershed_group_code = 'MORR')
    ) as geom
  )
  SELECT l.gnis_name_1 as name,
         ST_Transform(ST_Simplify(l.geom, 50), 4326) as geom,
         ST_Area(l.geom) / 1e6 as area_km2
  FROM whse_basemapping.fwa_lakes_poly l, ws
  WHERE ST_Intersects(l.geom, ws.geom)
    AND ST_Area(l.geom) > 1e5
")
saveRDS(lakes, file.path(out, "lakes.rds"))
message("Saved lakes")

# --- Roads (highway) ------------------------------------------------------

roads <- sf::st_read(conn, query = "
  WITH ws AS (
    SELECT ST_Difference(
      (SELECT geom FROM fwa_watershedatmeasure(360873822, 164908)),
      (SELECT geom FROM whse_basemapping.fwa_watershed_groups_poly
       WHERE watershed_group_code = 'MORR')
    ) as geom
  )
  SELECT t.highway_route_1 as route,
         ST_Transform(ST_Simplify(t.geom, 50), 4326) as geom
  FROM whse_basemapping.transport_line t, ws
  WHERE t.transport_line_type_code IN ('RH1', 'RA1')
    AND ST_Intersects(t.geom, ST_Expand(ws.geom, 5000))
")
saveRDS(roads, file.path(out, "roads.rds"))
message("Saved roads")

DBI::dbDisconnect(conn)
message("\nAll spatial layers cached to ", out)

SHELL = /bin/bash

DB ?= staircase
PGUSER ?= postgres
PGDATABASE ?= $(PG_DB)
SCHEMA = stairs
PORT ?= 5555
GEOPKG ?= /mnt/u/FY2025/MobilityAnalysisDesign/Ped_Bridges_Study/qgis/count_locations_reproj.gpkg
psql = psql $(PSQLFLAGS)

SCHEMA = ped_stair_bridge



load:;
	psql -U $(PGUSER) -p $(PORT) -d $(DB) -c "CREATE SCHEMA IF NOT EXISTS $(SCHEMA);" && \
	ogr2ogr -f PostgreSQL PG:"dbname=staircase port=5555 user=postgres" $(GEOPKG) -lco SCHEMA=$(SCHEMA) -t_srs EPSG:26918

setup:; $(psql) -U $(PGUSER) -p $(PORT) -d $(DB) -v schema=$(SCHEMA) -f sql/setup.sql

detours:; $(psql) -U $(PGUSER) -p $(PORT) -d $(DB) -v schema=$(SCHEMA) -f sql/detours.sql 

clean:; $(psql) -U $(PGUSER) -p $(PORT) -d $(DB) -c "DROP SCHEMA $(SCHEMA) CASCADE"

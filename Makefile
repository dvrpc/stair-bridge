SHELL = /bin/bash

include .env

load:;
	psql -U $(PGUSER) -p $(PORT) -d $(DB) -c "CREATE SCHEMA IF NOT EXISTS $(SCHEMA);" && \
	psql -U $(PGUSER) -p $(PORT) -d $(DB) -c "CREATE EXTENSION IF NOT EXISTS postgis;" && \
	psql -U $(PGUSER) -p $(PORT) -d $(DB) -c "CREATE EXTENSION IF NOT EXISTS pgrouting;" && \
	ogr2ogr -f PostgreSQL PG:"dbname=$(DB) port=$(PORT) user=$(PGUSER)" $(GEOPKG) -lco SCHEMA=$(SCHEMA) -t_srs EPSG:26918

setup:; psql -U $(PGUSER) -p $(PORT) -d $(DB) -v schema=$(SCHEMA) -f sql/setup.sql

detours:; psql -U $(PGUSER) -p $(PORT) -d $(DB) -v schema=$(SCHEMA) -f sql/detours.sql 

walksheds:; psql -U $(PGUSER) -p $(PORT) -d $(DB) -v schema=$(SCHEMA) -f sql/walksheds.sql 

fieldwork:; psql -U $(PGUSER) -p $(PORT) -d $(DB) -v schema=$(SCHEMA) -v field_csv=$(FIELDWORK) -f sql/fieldwork.sql 

udrive:;
	ogr2ogr -f GPKG $(UDRIVE_OUTPUT_GPKG) \
		PG:"host=localhost user=$(PGUSER) dbname=$(DB) port=$(PORT)" \
		-sql "select * from $(SCHEMA).isoshells" -nln iso_hulls
	ogr2ogr -f GPKG -append $(UDRIVE_OUTPUT_GPKG) \
		PG:"host=localhost user=$(PGUSER) dbname=$(DB) port=$(PORT)" \
		-sql "select * from $(SCHEMA).links_joined" -nln links_joined
	ogr2ogr -f GPKG -append $(UDRIVE_OUTPUT_GPKG) \
		PG:"host=localhost user=$(PGUSER) dbname=$(DB) port=$(PORT)" \
		-sql "select * from $(SCHEMA).detours" -nln detours

all:; 
	make clean
	make load
	make setup
	make detours
	make walksheds
	make fieldwork
	make udrive

clean:; psql -U $(PGUSER) -p $(PORT) -d $(DB) -c "DROP SCHEMA IF EXISTS $(SCHEMA) CASCADE"

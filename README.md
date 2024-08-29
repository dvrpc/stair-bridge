# stair-bridge

This is a project for the City of Philadelphia in DVRPC's 2025 Fiscal Year. 
The purpose of the project is to count and analyze pedestrians on and around several bridges and staircases in the City.

## Data preparation
Sidewalk data from DVRPC was trimmed to only include Philadelphia. 
Bridges and staircases were removed from the sidewalk network, so that detours and walksheds could be calculated without those links to help determine their importance.
Another file was created with the bridge / staircase geometries, separate from the sidewalk layer, and both were edited to achieve topology.

## Installation/Setup
You will need:
- PostgreSQL
- PostGIS
- PGRouting
- ogr2ogr/gdaltools (optional but helpful)

Create a database called 'staircase' (or whatever you prefer) and enable PostGIS and PGRouting. 

You need to be behind the DVRPC firewall to access project folders. 

Use ogr2ogr (or whatever means you prefer) to move the following geopackage into Postgres. 

```shell 
ogr2ogr -f PostgreSQL PG:"dbname=staircase port=5555 user=postgres" /mnt/u/FY2025/MobilityAnalysisDesign/Ped_Bridges_Study/qgis/count_locations.gpkg
```

This contains:
- a copy of DVRPC's sidewalk network for Philadelphia, with some edits made for topology's sake (pedestrian_network_lines table) 
- locations that are being counted for the project (locations table)
- count locations around CLOSED bridges or staircases (closed table)

## Usage






## License

**MIT License**

Copyright (c) 2023 Delaware Valley Regional Planning Commission

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to
deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
IN THE SOFTWARE.

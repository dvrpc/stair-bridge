# Stair-bridge

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
- ogr2ogr

Create a database called 'staircase' (or whatever you prefer).

Create a .env file and fill in the following details. If you're on a Unix (Linux/Mac) system, keep all U drive files/paths.
If you're on Windows, change the paths to Windows format (e.g., 'U:\This\is\a\Windows\Path' )  

It's not recommended to use 'public' as your schema in the .env. 

```
DB=staircase
PGUSER=
PORT=
GEOPKG='/mnt/u/FY2025/MobilityAnalysisDesign/Ped_Bridges_Study/qgis/count_locations_reproj.gpkg'
SCHEMA=
UDRIVE_OUTPUT_GPKG='/mnt/u/FY2025/MobilityAnalysisDesign/Ped_Bridges_Study/project_output/outputs.gpkg'
FIELDWORK='/mnt/u/FY2025/MobilityAnalysisDesign/Ped_Bridges_Study/project_input/field_work_data.csv'
```

You need to be behind the DVRPC firewall to access project folders and run these scripts.

The Makefile at the root of this repo contains all commands. 

Simply run `make all` from the root to import the data, create the walksheds and detours, and produce a Geopackage for later use.
Geopackage works in both QGIS and ArcPro.

You can tweak variables if needed, for example, tweak 'WALKTIME' in sql/walksheds.sql to change walktime from 15-minutes to some other number.

## Final calculation analysis
- Get the relevant (requested) counts using [DVRPC count viewer](https://www.dvrpc.org/webmaps/trafficcounts/).
- Use (run) the R file for the calculation

## Steps for Creating Summary Tables with Weighted Counts per Bridge
1. **Clean the Raw Count Data:**
   - Remove data from **Columbus Day**.
   - Filter the data to include only two 12-hour timeframes:
     - **Daytime:** 7 AM to 7 PM  
     - **Nighttime:** 7 PM to 7 AM (next day)
2. **Calculate Distances:**
   - For each location, determine the path-based distance to the start of the corresponding bridge.  
   *(This step was performed manually using GIS software.)*
3. **Compute Weighted Counts:**
   - Iterate through each bridge and each hour within the defined timeframes.
   - For each case, calculate the weighted count using the following formula: <br>*Sum of (count ÷ distance) divided by sum of (1 ÷ distance)*
4. **Generate Summary Tables:**
   - Use the weighted count table to compute summary statistics (**maximum** and **median**) for each bridge.

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

library(dplyr)
library(tidyr)
library(sf)
library(lubridate)
library(igraph)     # For graph operations
library(sfnetworks) # For converting roads to network graph

# # Step 1: Read in the shapefiles
pedestrians <- st_read("PATH/daily_sum.shp")
sidewalks <- st_read("PATH/sidewalk_clip_philly.shp")

# Transform to a common CRS if needed (assuming WGS84 here, change if needed)
pedestrians <- st_transform(pedestrians, 4326)
sidewalks <- st_transform(sidewalks, 4326)

# creating a subset of most recent mondays without points duplications:

daily_sum_mon <- pedestrians %>% filter(dy_f_wk == "Mon")
#length(unique(daily_sum_mon$geometry)) #558 different points

# Sort the data frame by 'day' in descending order
daily_sum_mon <- daily_sum_mon[order(daily_sum_mon$day, decreasing = TRUE), ]

#cleaning very high total values:
daily_sum_mon_filtered <- daily_sum_mon %>% filter(total < 10000 & total > 0)

# Remove duplicates based on 'geometry' and keep the first (most recent) occurrence
unique_geom_df <- daily_sum_mon_filtered[!duplicated(daily_sum_mon_filtered$geometry), ]

#testing on a much smaller sample to see code is working:
#unique_geom_df <- head(unique_geom_df,20)

pedestrians <- unique_geom_df

# clean the sidewalks df:

sidewalks_linestrings <- st_cast(sidewalks, "LINESTRING")

#table(st_geometry_type(sidewalks))

sidewalks_linestrings <- st_make_valid(sidewalks_linestrings)

#table(st_geometry_type(sidewalks_linestrings))

sidewalks_linestrings <- sidewalks_linestrings %>% filter(st_geometry_type(.) == "LINESTRING")
sidewalks_linestrings <- st_cast(sidewalks, "LINESTRING")

# Step 3: Convert the road network into a graph using sfnetworks
road_network <- as_sfnetwork(sidewalks_linestrings, directed = FALSE)

# Step 4: Define the IDW Interpolation function
idw_interpolation <- function(values, distances, p) {
  numerator <- sum(values / (distances^p))
  denominator <- sum(1 / (distances^p))
  interpolated_value <- numerator / denominator
  return(interpolated_value)
}

# Power parameter for IDW
p <- 2

# Initialize a new column to store interpolated aadp values
pedestrians$interpolated_total <- NA

# Convert the road network to an igraph object
g <- as.igraph(road_network)

# Step 5: Loop over each point, treating each one as the "unknown" in turn
for (i in 1:nrow(pedestrians)) {
  # Step 5a: Split into known and unknown points for this iteration
  known_points <- pedestrians[-i, ]  # All points except the current one
  unknown_point <- pedestrians[i, ]  # The current unknown point
  
  # Step 5b: Extract coordinates of known and unknown points
  known_coords <- st_coordinates(known_points)
  unknown_coords <- st_coordinates(unknown_point)
  
  # Step 5c: Find the closest network node for each known and unknown point
  known_nodes <- st_nearest_feature(known_points, road_network)
  unknown_node <- st_nearest_feature(unknown_point, road_network)
  
  # Step 5d: Calculate shortest path distances from the unknown point to each known point
  distances <- sapply(known_nodes, function(node) {
    path_distance <- distances(g, v = unknown_node, to = node, weights = E(g)$weight)
    as.numeric(path_distance)  # Ensure the distance is numeric
  })
  
  # Step 5e: Perform IDW Interpolation
  values <- known_points$total  # Known values (aadp from other points)
  
  interpolated_value <- idw_interpolation(values, distances, p)
  
  # Step 5f: Store the interpolated value in the new column
  pedestrians$interpolated_total[i] <- interpolated_value
}

pedestrians$change_in_intr <- pedestrians$interpolated_total - pedestrians$total
summary(pedestrians$change_in_intr)

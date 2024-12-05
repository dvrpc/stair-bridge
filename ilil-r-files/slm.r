library(sf)
library(dplyr)
library(spdep)       # Spatial weights
library(spatialreg)  # Spatial lag model
library(sfnetworks)  # For network-based distances
library(stplanr)   # For calculating network-based distances
library(rgeos)     # For geometric operations
library(maptools)
library(sp)
library(dodgr)
library(units)

# 1. Load Data
pedestrians <- st_read("PATH/daily_sum.shp")
sidewalks <- st_read("PATH/sidewalk_clip_philly.shp")
commercial <- st_read("PATH/lu_philly_comm_2023.shp")
institutional <- st_read("PATH/lu_philly_inst_2023.shp")
pass_rail <- st_read("PATH/passenger_rail_philly.shp")

# Transform to a common CRS if needed (assuming WGS84 here, change if needed)
pedestrians <- st_transform(pedestrians, 4326)
sidewalks <- st_transform(sidewalks, 4326)
commercial <- st_transform(commercial, 4326)
institutional <- st_transform(institutional, 4326)
pass_rail <- st_transform(pass_rail, 4326)

# creating a subset of most recent mondays without points duplications:
# this is ONE WAY to subset this data, please explore others

daily_sum_mon <- pedestrians %>% filter(dy_f_wk == "Mon")

nrow(daily_sum_mon)
length(unique(daily_sum_mon$geometry)) #558 different points

# Sort the data frame by 'day' in descending order
daily_sum_mon <- daily_sum_mon[order(daily_sum_mon$day, decreasing = TRUE), ]

#cleaning very high total values:
daily_sum_mon_filtered <- daily_sum_mon %>% filter(total < 10000 & total > 0)

# Remove duplicates based on 'geometry' and keep the first (most recent) occurrence
unique_geom_df <- daily_sum_mon_filtered[!duplicated(daily_sum_mon_filtered$geometry), ]

hist(unique_geom_df$total)
summary(unique_geom_df$total)
plot(unique_geom_df$total)

# test with slm model:

# select the deataset (rename, for existing code):
pedestrians <- unique_geom_df

sidewalks <- sidewalks %>% st_cast("LINESTRING") 

#table(st_geometry_type(sidewalks))

# 2. Create a Network from the Sidewalks Layer
# please review and consider using roads if sidewalks not in good-enough quality

network <- as_sfnetwork(sidewalks, directed = FALSE) %>%
  activate("edges") %>%
  mutate(weight = edge_length()) # Use edge length as weight

# snap points to sidwalk line
# Convert sf objects to sp objects (SpatialPointsDataFrame and SpatialLinesDataFrame)
pedestrians_sp <- as(pedestrians, "Spatial")
sidewalks_sp <- as(sidewalks, "Spatial")

# Use snapPointsToLines to snap points to the nearest line (sidewalk)
snapped_pedestrians_sp <- snapPointsToLines(pedestrians_sp, sidewalks_sp, maxDist = 10)  # Adjust maxDist as needed

# Convert the snapped points back to sf format
snapped_pedestrians_sf <- st_as_sf(snapped_pedestrians_sp)

# Ensure the CRS is consistent with the original data
st_crs(snapped_pedestrians_sf) <- st_crs(pedestrians)

# changing the used data to be the snapped points:
pedestrians <- cbind(snapped_pedestrians_sf,pedestrians %>% st_set_geometry(NULL))

# 3. Calculate Network-Based Distances
# Function to calculate nearest distance to a target layer using network paths
calculate_network_distance <- function(points, target_layer, network) {
  target_nodes <- st_nearest_points(st_geometry(points), st_geometry(target_layer))
  target_nodes <- st_as_sf(st_combine(target_nodes))  # Combine and convert to SF

  distances <- st_network_cost(network, from = points, to = target_nodes)
  apply(distances, 1, min)  # Get the minimum distance for each point
}

# Nearest distances
pedestrians$nearest_rail_distance <- calculate_network_distance(pedestrians, pass_rail, network)

# Convert pedestrian points to nearest points on polygon
# this step takes a lot of time to run, there is possibly a way to improve it
commercial <- commercial %>% st_make_valid()
commercial_points <- commercial %>%
  st_boundary() %>%            # Get the polygon boundaries
  st_cast("MULTIPOINT") %>%    # Convert them to points
  st_cast("POINT")             # Ensure single points

pedestrians$nearest_commercial_distance <- calculate_network_distance(pedestrians, commercial_points, network)

institutional <- institutional %>% st_make_valid()
institutional_points <- institutional %>%
  st_boundary() %>%            # Get the polygon boundaries
  st_cast("MULTIPOINT") %>%    # Convert them to points
  st_cast("POINT")             # Ensure single points

pedestrians$nearest_inst_distance <- calculate_network_distance(pedestrians, institutional_points, network)

# Define k for k-nearest neighbors
k <- 7
# TO BE LATER OPTIMIZED TO BEST OPTION FOR SELECTED SUBSET

# Create a matrix of network distances
network_weights <- st_network_cost(network, from = snapped_pedestrians_sf, to = snapped_pedestrians_sf)

# Remove units for plain numeric matrix
numeric_network_weights <- as.matrix(set_units(network_weights, NULL))

# Replace Inf with a large finite value
max_finite_value <- max(numeric_network_weights[!is.infinite(numeric_network_weights)], na.rm = TRUE)
numeric_network_weights[is.infinite(numeric_network_weights)] <- max_finite_value

# Create a kNN neighbor list based on network distances
knn_network_nb <- apply(numeric_network_weights, 1, function(row) {
  order(row, decreasing = FALSE)[1:k]
})

# Convert knn_network_nb to a neighbor object
nb_network_knn <- lapply(1:nrow(numeric_network_weights), function(i) knn_network_nb[, i])
class(nb_network_knn) <- "nb"

# Convert neighbor list to spatial weights matrix
lw_network_knn <- nb2listw(nb_network_knn, style = "W")

# Add spatial lag based on network kNN weights
pedestrians$spatial_lag <- lag.listw(lw_network_knn, pedestrians$total)

pedestrians$log_total <- log(pedestrians$total)
# because of the subset distribution NOW, it is best to log it, to be re-examined with a different subset

# Fit Spatial Lag Model using the new kNN-based spatial lag
# v1: model only with spatial lag
slm_model_v1_network_knn <- lagsarlm(log_total ~ spatial_lag,
                                  data = pedestrians,
                                  listw = lw_network_knn)

summary(slm_model_v1_network_knn)

# v2: model with additional independent variables
slm_model_v2_network_knn <- lagsarlm(log_total ~ spatial_lag + nearest_commercial_distance + nearest_inst_distance,
                                  data = pedestrians,
                                  listw = lw_network_knn)

summary(slm_model_v2_network_knn)

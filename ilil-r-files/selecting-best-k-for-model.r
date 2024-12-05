# This is an old part of code that was built for GWR model but can be altered to SLM
# IT WILL NOT RUN AS IS BECAUSE THE MODEL CODE IS MISSING
# Review for steps. If you want, you can copy it into the SLM code and modify it

# Load libraries
library(sf)        
library(dplyr)     
library(sp)
library(spdep)

# test different k values: 

# [Step 0: predict using a model]
# # Extract GWR results
# gwr_results <- gwr_model$SDF
# # Extract the fitted/predicted values (the predicted aadp) from the GWR model
# gwr_fitted <- gwr_model$SDF$pred  # This gives the predicted values (aadp_predict)
# # Add the predicted values as a new column to your pedestrian dataset
# pedestrians_sp@data$aadp_predict <- gwr_fitted

# Step 1: Calculate residuals
pedestrians_sf$residuals <- pedestrians_sf$aadp - pedestrians_sf$aadp_predict
# The difference between observed values and model-predicted ones

# Step 2: Function to fit GWR model and return residuals
fit_gwr_for_k <- function(k) {
  # Create nearest neighbors for the given k
  knn_obj <- knearneigh(coordinates(pedestrians_sp), k = k)
  nb <- knn2nb(knn_obj)
  lw <- nb2listw(nb, style = "W")

  pedestrians_sp@data$aadp_lag <- lag.listw(lw, pedestrians_sp@data$aadp)

  # Select bandwidth and fit GWR model
  # that is a step relevant for GWR, not for SLM
  gwr_bandwidth <- gwr.sel(gwr_formula,
                           data = pedestrians_sp,
                           gweight = gwr.bisquare,
                           method = "aic")
  gwr_model <- gwr(gwr_formula,
                   data = pedestrians_sp,
                   bandwidth = gwr_bandwidth,
                   gweight = gwr.bisquare)

  # Extract fitted values and calculate residuals
  gwr_fitted <- gwr_model$SDF$pred
  residuals <- pedestrians_sp@data$aadp - gwr_fitted

  # Calculate RMSE for the model
  rmse <- sqrt(mean(residuals^2))

  return(list(k = k, rmse = rmse, residuals = residuals, gwr_model = gwr_model))
}

# Step 3: Loop through different k values
k_values <- 4:10
gwr_results_list <- lapply(k_values, fit_gwr_for_k)
# this steps tests 7 different models using k=4 trough k=10 for the results

# Step 4: Extract the RMSE for each k and find the best one
rmse_values <- sapply(gwr_results_list, function(x) x$rmse)
best_k_index <- which.min(rmse_values)
best_k <- gwr_results_list[[best_k_index]]$k

# Print the best k value and corresponding RMSE
cat("Best k:", best_k, "\n")
cat("Best RMSE:", rmse_values[best_k_index], "\n")

# Step 5: Extract residuals for the best model and add to sf dataframe
pedestrians_sf$residuals <- gwr_results_list[[best_k_index]]$residuals

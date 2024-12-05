# Files and code from Ilil

This folder contains the most updated r code of raw data cleaning and preliminary models testing for the stair bridge estimations. 

- It does not contain the paths (were cleaned), relevant files are stored under the input folder in U drive.
- There are no r.environ/secrets in the code but could be added to improve it

## R code files
- sample-data-for-models-tests.r :cleaning the raw data to Philly only and aggregating to daily sums. 
- idw-base-code.r : a preliminary simple network-based IDW code I tested early on
- slm.r : the most updated SLM (spatial lag model) code I tested
- selecting-best-k-for-model.r : part of an old code (GWR model-based) to show the steps of optimizing K neighborhoods. It will not run as is because it is missing the model code, only to review steps.

## Other notes
- The network-based IDW, the SLM, and negative-binomial regression models are worth exploring and comparing.
- With the IDW, it is best to add a step restricting the radius of sample points per point (in other words, not sampling the entire data but points within X miles from the estimated location).
- I did not run the SLM model with all the additional independent variables because converting the polygons to points was too time-consuming; however, it was worth exploring all and adding more relevant ones, spatial and non-spatial (weather, for example). 

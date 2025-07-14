library(dplyr)
library(tidyr)
library(sf)
library(lubridate)
library(ggplot2)
library(stringr)
library(sfnetworks)
library(tidygraph)
library(units)

# read and format the files
paths <- read_sf("PATH_HERE/path_projected_crs.shp") #path projected correctly
paths <- st_zm(paths, drop = TRUE, what = "ZM")
paths$length_m <- st_length(paths) #using the new calc bcs different projection
paths$length_m <- as.numeric(paths$length_m)
paths <- paths %>% st_set_geometry(NULL) %>% select(Name = count, length_m)

long_data <- read.csv("PATH_HERE_FILE_IN_REPO/long_data_all.csv")
name_dictionary <- read.csv("PATH_HERE_FILE_IN_REPO/collection_point_id.csv")

long_data$hour_corrected <- with(long_data, ifelse(am_pm == "AM" & hour_numeric == 12, 0,
                                     ifelse(am_pm == "PM" & hour_numeric == 12, 12,
                                            ifelse(am_pm == "PM", hour_numeric + 12,
                                                   hour_numeric))))

long_data <- long_data %>% rename(bridge_name = name)

loc_dist <- merge(paths,name_dictionary,by.x="Name",by.y="name")

# add both tables:
both <- merge(long_data,loc_dist,by= "recordnum",all=TRUE) %>% dplyr::select(-X,-hour_numeric, -am_pm, -Name)

# there is a dawson location that was dropped, cleaning it:
both <- both %>% filter(recordnum != '174430')
 
wc_by_bridge <- both %>%
  group_by(date, hour_corrected, bridge_name) %>%
  summarise(
    weighted_count = sum(value / length_m, na.rm = TRUE) / 
      sum(1 / length_m, na.rm = TRUE),
    .groups = "drop"
  )

#d1 <- both %>% filter(recordnum == 174421)
  
#rm(list = setdiff(ls(), "wc_by_bridge"))

# subset to weekdays and weekends

weekdays_counts <- wc_by_bridge %>%
  mutate(weekday = wday(date, label = TRUE, week_start = 1)) %>%  # Extract day of the week (Mon=1, Sun=7)
  filter(!(weekday %in% c("Sat", "Sun")))  # Exclude Saturday and Sunday

weekends_counts <- wc_by_bridge %>%
  mutate(weekday = wday(date, label = TRUE, week_start = 1)) %>%  # Extract day of the week (Mon=1, Sun=7)
  filter((weekday %in% c("Sat", "Sun"))) 

# two time intervals:

weekdays_counts_day <- weekdays_counts %>%
  filter(hour_corrected %in% c("7", "8", "9", "10", "11", "12","13","14","15","16","17","18"))  

weekdays_counts_night <- weekdays_counts %>%
  filter(!(hour_corrected %in% c("7", "8", "9", "10", "11", "12","13","14","15","16","17","18")))  

weekends_counts_day <- weekends_counts %>%
  filter(hour_corrected %in% c("7", "8", "9", "10", "11", "12","13","14","15","16","17","18"))  

weekends_counts_night <- weekends_counts %>%
  filter(!(hour_corrected %in% c("7", "8", "9", "10", "11", "12","13","14","15","16","17","18")))  

weekdays_for_bridge_day <- weekdays_counts_day %>%
  group_by(bridge_name) %>%
  summarise(
    max_value_weekday_day = max(weighted_count, na.rm = TRUE),
    median_value_weekday_day = median(weighted_count, na.rm = TRUE)
  )

weekdays_for_bridge_night <- weekdays_counts_night %>%
  group_by(bridge_name) %>%
  summarise(
    max_value_weekday_night = max(weighted_count, na.rm = TRUE),
    median_value_weekday_night = median(weighted_count, na.rm = TRUE)
  )

by_bridge_weekday <- merge(weekdays_for_bridge_day,weekdays_for_bridge_night,
                   by = "bridge_name")

weekends_for_bridge_day <- weekends_counts_day %>%
  group_by(bridge_name) %>%
  summarise(
    max_value_weekends_day = max(weighted_count, na.rm = TRUE),
    median_value_weekends_day = median(weighted_count, na.rm = TRUE)
  )

weekends_for_bridge_night <- weekends_counts_night %>%
  group_by(bridge_name) %>%
  summarise(
    max_value_weekends_night = max(weighted_count, na.rm = TRUE),
    median_value_weekends_night = median(weighted_count, na.rm = TRUE)
  )

by_bridge_weekends <- merge(weekends_for_bridge_day,weekends_for_bridge_night,
                           by = "bridge_name")

by_bridge_all <- merge(by_bridge_weekday,by_bridge_weekends,
                   by = "bridge_name")

write.csv(by_bridge_all,"EXPORTH_FOLDER_PATH_HERE/by_bridge_weighted_count_day_night.csv")

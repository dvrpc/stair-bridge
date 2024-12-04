library(dplyr)  
library(sf)
library(lubridate)
library(ggplot2)

# some raw counts:
counts <- read.csv("ENTER-PATH-HERE-AND-CHANGE-TO-SECRET/ped_detail.csv") #this csv is exported from the DVRPC counts raw data

# identifying the day of the week:

class(counts$DAY)

counts$DAY <- mdy(counts$DAY) #convert to date format 

counts$day_of_week <- wday(counts$DAY, label = TRUE, abbr = TRUE)

colnames(counts) <- c("recordnum","day","time","total","high_temp","low_temp","weather","lat","long","day_of_week")

# filter philly only 

rec_num_point <- unique(counts %>% dplyr::select(recordnum,long,lat))

rec_num_point <- st_as_sf(rec_num_point, coords = c("long", "lat"), crs = 4326)

philly <- read_sf("ENTER-PATH-HERE-TO-PHILLY-POLYGON/philly.shp")
philly <- st_transform(philly, crs = 4326)  # WGS 84 
philly <- philly %>% dplyr::select(geometry)

# ggplot() +
#   geom_sf(data = philly, fill = "lightblue", color = "black") +  # Polygon layer
#   geom_sf(data = rec_num_point, color = "red", size = 3) +                # Point layer
#   theme_minimal()

rec_num_philly <- st_intersection(rec_num_point, philly)

counts_philly <- merge(rec_num_philly,counts,by="recordnum",all=FALSE)

# dropping points with no weather:

unique(counts_philly$weather)

counts_philly <- counts_philly %>% filter(weather != "")

daily_sum <- counts_philly %>%
  group_by(recordnum,day) %>%
  summarise(total = sum(total, na.rm = TRUE))  # na.rm = TRUE removes NAs

added_col <- unique(counts_philly %>% dplyr::select(recordnum,day,day_of_week,
                                                    high_temp,low_temp,weather) %>% st_set_geometry(NULL))

daily_sum <- merge(daily_sum,added_col,by=c("recordnum","day"),all=TRUE)

rm("counts","added_col")

daily_sum$year <- year(daily_sum$day)

# dropping end of year (HOLIDAYS)

daily_sum$month_day <- format(as.Date(daily_sum$day), "%m-%d")
daily_sum$month_year <- format(as.Date(daily_sum$day), "%Y-%m")

daily_sum <- daily_sum %>% 
  filter(!(month_day >= "11-25" | month_day <= "01-05")) 

# flagging very high / low weather

daily_sum$above_90_f <- ifelse(daily_sum$high_temp > 90,TRUE,FALSE)
daily_sum$below_20_f <- ifelse(daily_sum$low_temp < 20,TRUE,FALSE)

daily_sum$weekend <- ifelse(daily_sum$day_of_week == "Sun"| daily_sum$day_of_week == "Sat",TRUE,FALSE)

daily_sum$covid <- ifelse(daily_sum$day >= as.Date("2020-03-01") & 
                            daily_sum$day <= as.Date("2021-03-01"), TRUE, FALSE)
# that is a VERY rough/selective def for COVID times that can be disregarded or adjusted if needed

rm(list=setdiff(ls(), "daily_sum"))

#export shapefile
write_sf(daily_sum,"PATH-TO-EXPORT-HERE/daily_sum.shp")
# This shapefile is already stored on UDrive; this code is here for reference. 

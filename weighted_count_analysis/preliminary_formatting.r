library(dplyr)
library(tidyr)
library(sf)
library(lubridate)
library(ggplot2)
library(stringr)

# read and format the files

# Reed (1)

reed_1 <- read.csv("PATH_TO_RAW_COUNTS_TABLES/174405.csv", skip = 3)
reed_1 <- cbind(name='reed',recordnum = '174405', reed_1)

reed_2 <- read.csv("PATH_TO_RAW_COUNTS_TABLES/174406.csv", skip = 3)
reed_2 <- cbind(name='reed',recordnum = '174406', reed_2)

reed_3 <- read.csv("PATH_TO_RAW_COUNTS_TABLES/174407.csv", skip = 3)
reed_3 <- cbind(name='reed',recordnum = '174407', reed_3)

reed_4 <- read.csv("PATH_TO_RAW_COUNTS_TABLES/174408.csv", skip = 3)
reed_4 <- cbind(name='reed',recordnum = '174408', reed_4)

reed_5 <- read.csv("PATH_TO_RAW_COUNTS_TABLES/174409.csv", skip = 3)
reed_5 <- cbind(name='reed',recordnum = '174409', reed_5)

reed_6 <- read.csv("PATH_TO_RAW_COUNTS_TABLES/174410.csv", skip = 3)
reed_6 <- cbind(name='reed',recordnum = '174410', reed_6)

# Morris (2)

morris_1 <- read.csv("PATH_TO_RAW_COUNTS_TABLES/174411.csv", skip = 3)
morris_1 <- cbind(name='morris',recordnum = '174411', morris_1)

morris_2 <- read.csv("PATH_TO_RAW_COUNTS_TABLES/174412.csv", skip = 3)
morris_2 <- cbind(name='morris',recordnum = '174412', morris_2)

morris_3 <- read.csv("PATH_TO_RAW_COUNTS_TABLES/174413.csv", skip = 3)
morris_3 <- cbind(name='morris',recordnum = '174413', morris_3)

# Wheatsheaf (3)

wheatsheaf_1 <- read.csv("PATH_TO_RAW_COUNTS_TABLES/174414.csv", skip = 3)
wheatsheaf_1 <- cbind(name='wheatsheaf',recordnum = '174414', wheatsheaf_1)

wheatsheaf_2 <- read.csv("PATH_TO_RAW_COUNTS_TABLES/174415.csv", skip = 3)
wheatsheaf_2 <- cbind(name='wheatsheaf',recordnum = '174415', wheatsheaf_2)

wheatsheaf_3 <- read.csv("PATH_TO_RAW_COUNTS_TABLES/174417.csv", skip = 3)
wheatsheaf_3 <- cbind(name='wheatsheaf',recordnum = '174417', wheatsheaf_3)

wheatsheaf_4 <- read.csv("PATH_TO_RAW_COUNTS_TABLES/174418.csv", skip = 3)
wheatsheaf_4 <- cbind(name='wheatsheaf',recordnum = '174418', wheatsheaf_4)

wheatsheaf_5 <- read.csv("PATH_TO_RAW_COUNTS_TABLES/174419.csv", skip = 3)
wheatsheaf_5 <- cbind(name='wheatsheaf',recordnum = '174419', wheatsheaf_5)

wheatsheaf_6 <- read.csv("PATH_TO_RAW_COUNTS_TABLES/174420.csv", skip = 3)
wheatsheaf_6 <- cbind(name='wheatsheaf',recordnum = '174420', wheatsheaf_6)

# dawson (4)

dawson_1 <- read.csv("PATH_TO_RAW_COUNTS_TABLES/174421.csv", skip = 3)
dawson_1 <- cbind(name='dawson',recordnum = '174421', dawson_1)

dawson_2 <- read.csv("PATH_TO_RAW_COUNTS_TABLES/174422.csv", skip = 3)
dawson_2 <- cbind(name='dawson',recordnum = '174422', dawson_2)

dawson_3 <- read.csv("PATH_TO_RAW_COUNTS_TABLES/174423.csv", skip = 3)
dawson_3 <- cbind(name='dawson',recordnum = '174423', dawson_3)

dawson_4 <- read.csv("PATH_TO_RAW_COUNTS_TABLES/174424.csv", skip = 3)
dawson_4 <- cbind(name='dawson',recordnum = '174424', dawson_4)

dawson_5 <- read.csv("PATH_TO_RAW_COUNTS_TABLES/174425.csv", skip = 3)
dawson_5 <- cbind(name='dawson',recordnum = '174425', dawson_5)

dawson_6 <- read.csv("PATH_TO_RAW_COUNTS_TABLES/174430.csv", skip = 3)
dawson_6 <- cbind(name='dawson',recordnum = '174430', dawson_6)

# Duval (5) 

duval_1 <- read.csv("PATH_TO_RAW_COUNTS_TABLES/174426.csv", skip = 3)
duval_1 <- cbind(name='duval',recordnum = '174426', duval_1)

duval_2 <- read.csv("PATH_TO_RAW_COUNTS_TABLES/174427.csv", skip = 3)
duval_2 <- cbind(name='duval',recordnum = '174427', duval_2)

duval_3 <- read.csv("PATH_TO_RAW_COUNTS_TABLES/174428.csv", skip = 3)
duval_3 <- cbind(name='duval',recordnum = '174428', duval_3)

duval_4 <- read.csv("PATH_TO_RAW_COUNTS_TABLES/174429.csv", skip = 3)
duval_4 <- cbind(name='duval',recordnum = '174429', duval_4)

# merge all to one:

all <- rbind(reed_1,reed_2,reed_3,reed_4,reed_5,reed_6,
             morris_1,morris_2,morris_3,
             wheatsheaf_1,wheatsheaf_2,wheatsheaf_3,wheatsheaf_4,wheatsheaf_5,wheatsheaf_6,
             dawson_1,dawson_2,dawson_3,dawson_4,dawson_5,dawson_6,
             duval_1,duval_2,duval_3,duval_4)

rm(list = setdiff(ls(), "all"))

#

all <- all[, 1:(ncol(all) - 3)] #drop last three col

long_data_all <- pivot_longer(
  all, 
  cols = -c(1, 2, 3),      # Keep the first three columns, reshape the rest
  names_to = "hour",    # Column names become 'hour'
  values_to = "value"   # Their respective values go into 'value'
)

long_data_all <- long_data_all %>% filter (hour != 'total') # remove total counts

# Convert 'hour' column to proper time format
long_data_all <- long_data_all %>%
  mutate(
    hour_numeric = as.numeric(str_extract(hour, "\\d+")),  # Extract just the number
    am_pm = str_extract(hour, "AM|PM"),  # Extract AM or PM
    hour_corrected = ifelse(am_pm == "PM", hour_numeric + 12, hour_numeric),  # Add 12 to PM values
    hour_corrected = ifelse(hour_numeric == 12 & am_pm == "AM", 0, hour_corrected),  # Convert 12 AM to 00
    hour_corrected = as.character(hour_corrected)  # Ensure it's in character format
  )

# drop holidays: colombus day

unique(long_data_all$date)

long_data_all <- long_data_all %>% filter(date != as.Date("2024-10-14"))

#write.csv(long_data_all,"PATH_HERE/long_data_all.csv")

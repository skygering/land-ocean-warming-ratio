library(ggplot2)
library(tidyr)
library(dplyr)

upper_bound = 300
lower_bound = 270
ensemble = 'r1i1p1f1'
experiment = ''
path_name = 'Temperature Data/1pctCO2 Data'
file_name = '1pctCO2_temp.csv'

# Read in CSV Data
temp_data <- read.csv(file = file.path(path_name, file_name),
                     stringsAsFactors = FALSE)

#split the Ensemble_Model variable into two variables
temp_data <- separate(temp_data, "Ensemble_Model", 
                      c("Experiment", "Ensemble", "Model"), "_", 
                      remove = TRUE)

# Convert time just to year value
temp_data$Time <- round(temp_data$Time/10000)
temp_data <- temp_data[order(temp_data[,3], temp_data[,4], temp_data[,5]),]

unique_models = unique(temp_data$Model)

for (model in unique_models) {
  model_data <- filter(temp_data, Model == model)
  min_year <- min(model_data[,5], na.rm = F)
  temp_data$Time <- ifelse((temp_data$Model == model), (temp_data$Time - min_year), temp_data$Time)
}


# Identify data that falls outside the regular range
bad_data <- filter(temp_data, Temp > upper_bound | Temp < lower_bound)
bad_models<- unique(bad_data$Model)

# Remove outliers from data
for(model in bad_models){
  temp_data <- subset(temp_data, Model != model)   
}

# Plot to confirm visually that there is no other weird data
ggplot(temp_data, aes(x=Time, y=Temp, group = Model)) + 
  geom_line(aes(color = Model)) +
  facet_grid(cols = vars(Data)) +
  ggtitle("Annual Average Temperature from CMIP6 Data", subtitle = 
         expression('1% CO'[2]*' Scenario and r1i1p1f1 Ensemble')) +
  xlab("Time (years)") + ylab("Temperature (K)") +
  theme(plot.title = element_text(hjust = 0.5))
  

# Write cleaned data to a CSV
write.csv(temp_data, file.path(path_name, '1pctCO2_cleaned_temp.csv'),
          row.names = FALSE)
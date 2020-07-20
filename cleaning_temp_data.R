library(ggplot2)
library(tidyr)
library(dplyr)

upper_bound = 295
lower_bound = 275
path_name = 'Temperature Data'
file_name = 'temp.csv'

# Read in CSV Data
temp_data <- read.csv(file = file.path(path_name, file_name),
                     stringsAsFactors = FALSE)

#split the Ensemble_Model variable into two variables
temp_data <- separate(temp_data, "Ensemble_Model", 
                      c("Experiment", "Ensemble", "Model"), "_", 
                      remove = TRUE)

# Convert time just to year value
temp_data$Time <- round(temp_data$Time/10000)

temp_data <- temp_data[with(temp_data, order('Model', 'Time'))]

unique_models = unique(temp_data$Model)

for (model in unique_models) {
  min_year <- min(temp_data$Model == model)
  temp_data <- (temp_data$Model == model) - min_year
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
  facet_grid(cols = vars(Data))

# Write cleaned data to a CSV
write.csv(temp_data, file.path(path_name, 'cleaned_temp.csv'),
          row.names = FALSE)
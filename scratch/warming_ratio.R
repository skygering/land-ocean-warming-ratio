library(plyr)

standard_error <- function(x, n){
  sd(x)/sqrt(n)
}

get_warming <- function(temp_data, model, data_type){
  data <- filter(temp_data, Model == model & Data == data_type)
  end_range <- max(data$Time) - 30
  start <- filter(data, Time < 30)
  end <- filter(data, Time > end_range)
  warming <- mean(end$Temp) - mean(start$Temp)
  
  start_error <-standard_error(start$Temp, nrow(start))
  end_error <- standard_error(end$Temp, nrow(end))
  error <- sqrt(start_error^2 + end_error^2)
  
  c(warming, error)
}



# get_warming_constant:
# calculates the land-ocean warming constant for each timestep from the first temperature listed in land and ocean respectivly (historical data)
# inputs: 
#     land_temp: .nc file location with annual average temperature weighted by percent of grid that is land
#     ocean_temp:.nc file location with annual average temperature weighted by percent of grid that is ocean
#     land_warming: .nc file location that will hold land warming over each timestep
#     ocean_warming: .nc file location that will hold the ocean warming over each timestep
#     ratio: .nc file location that will hold land-ocean warming constant for each timestep
#output: 
#     land_warming.nc, ocean_warming.nc, and ratio.nc as specified above - saved at path_name
path_name = 'Temperature Data/1pctCO2 Data'
file_name = '1pctCO2_cleaned_temp.csv'

temp_data <- read.csv(file = file.path(path_name, file_name),
                      stringsAsFactors = FALSE)

ratio_df <- data.frame(Model = character(),
                       Ratio = double(), 
                       Error = double())

unique_models = unique(temp_data$Model)

for (model in unique_models){
  land_warming_err <- get_warming(temp_data, model, 'Land')
  ocean_warming_err <- get_warming(temp_data, model, 'Ocean')
  
  ratio <- land_warming_err[1]/ocean_warming_err[1]
  
  error <- ratio * sqrt((land_warming_err[2]/land_warming_err[1])^2 +
                  (ocean_warming_err[2]/ocean_warming_err[1])^2)
  
  model_df <- data.frame(Model = model,
             Ratio = ratio, 
             Error = error)
  
  ratio_df <- rbind.fill(ratio_df, model_df)
}

ggplot(ratio_df) + geom_boxplot()


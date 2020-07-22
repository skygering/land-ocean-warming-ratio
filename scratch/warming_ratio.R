library(plyr)

# standard error:
# returns the standard error
# inputs:
#       x: a vector of data for which to calculate the standard error
#       n: the length of x
# output:
#       the standard error of x
standard_error <- function(x, n){
  sd(x)/sqrt(n)
}

# get_avg_temp:
# calculates average temp for given range and standard error
# inputs:
#       data: data frame with Time, Temp, and Model parameters
#       start1: int - start range of data for average temp1 (inclusive)
#       end1: int - end range of data for average temp1 (exclusive)
# output: vector with mean temperature and standard error for given data
get_avg_temp <- function(data, start, end){
  range_data <- filter(data, Time >= start & Time < end)
  mean <- mean(range_data$Temp)
  error<- standard_error(range_data$Temp, nrow(range_data)) 
  c(mean, error)
}
# get_warming:
# calculates warming between two temperatures and can calculate the error given
# the standard error of each temperature
# input:
#       temp1: vector with avg temp and standard error
#       temp2: vector with avg temp and standard error
#       error: boolean - if true calculates standard error
# output:
#       a vector with the warming and the standard error (if error = T) 
#       of the warming calculation respectively
get_warming <- function(temp1, temp2, error = FALSE){
  
  total_error = NaN
  warming <- temp2[1] - temp1[1]
  if(error){
    total_error <- sqrt(temp2[2]^2 + temp1[2]^2)  # add the standard error in quadrature
  }

  c(warming, total_error)
}

### MAIN ###

path_name = 'Temperature Data/1pctCO2 Data'
file_name = 'cleaned_1pctCO2_temp.csv'

temp_data <- read.csv(file = file.path(path_name, file_name),
                      stringsAsFactors = FALSE)

ratio_df <- data.frame(Model = character(),
                       Ratio = double(), 
                       Error = double())

unique_models = unique(temp_data$Model)

# calculates very beginning and end warming to find overall warming - not over time
for (model in unique_models){
  model_data <- filter(temp_data, Model == model)
  land_data <- filter(model_data, Data == 'Land')
  ocean_data <- filter(model_data, Data == 'Ocean')
  
  start1 = 0
  end1 = 30
  land_temp_1 <- get_avg_temp(land_data, start1, end1)
  ocean_temp_1 <- get_avg_temp(ocean_data, start1, end1)
  
  start2 = 30
  end2 = 60
  while(end2 <= 150){
    year = mean(c(start2, end2))
    land_temp_2 <-get_avg_temp(land_data, start2, end2)
    ocean_temp_2 <- get_avg_temp(ocean_data, start2, end2)
    
    land_warming_err <- get_warming(land_temp_1, land_temp_2, TRUE)
    ocean_warming_err <- get_warming(ocean_temp_1, ocean_temp_2, TRUE)
    ratio <- land_warming_err[1]/ocean_warming_err[1]
    
    error <- ratio * sqrt((land_warming_err[2]/land_warming_err[1])^2 +
                            (ocean_warming_err[2]/ocean_warming_err[1])^2)
    
    model_df <- data.frame(Model = model,
                           Ratio = ratio, 
                           Error = error, Year = year)
    
    ratio_df <- rbind.fill(ratio_df, model_df)
    start2 = start2 + 30
    end2 = end2 + 30
  }
}

write.csv(ratio_df, file.path(path_name, paste0('ratio_', file_name)),
          row.names = FALSE)


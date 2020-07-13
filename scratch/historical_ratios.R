library(ncdf4)
library(ggplot2)
library(dplyr)

#THIS FILE IS TO LOOP THROUGH ALL OF THE DATA AND CALL THE TEMP AND WARMING RATION FUNCTIONS


path_name = 'land-ocean-warming-ratio/scratch/nc_data'
cdo_path = '../../usr/local/Cellar/cdo/1.9.8/bin/cdo'
source('land-ocean-warming-ratio/scratch/average_temp_cdo.R')

temp <- file.path(path_name, 'tas_Amon_ACCESS-CM2_historical_r1i1p1f1_gn_185001-201412.nc')
area <- file.path(path_name, 'areacella_fx_ACCESS-CM2_historical_r1i1p1f1_gn.nc')
land_frac <- file.path(path_name, 'sftlf_fx_ACCESS-CM2_historical_r1i1p1f1_gn.nc')


land_ocean_temps(path_name, cdo_path, temp, area, land_frac, TRUE)

temp_frame <- data.frame(Data = rep(c("Land", "Ocean", "Global"), each = dim(time)),
                         Time = rep(time, 3),
                         Temp = c(land_tas, ocean_tas, global_tas))

write.csv(temp_frame, file.path(path_name, 'temp.csv'), row.names = TRUE)

###FIGURE OUT HOW TO LOOP###

# Importing the CMIP6 archive 
archive <- readr::read_csv(url("https://raw.githubusercontent.com/JGCRI/CMIP6/master/cmip6_archive_index.csv"))
historical_data <- archive[c(archive$experiment == 'historical' & archive$variable %in% c('tas', 'areacella', 'sftlf')),]

#models and scenarios we want to run ? How do want to call this?

#MAKE A LIST OF ALL OF THE NAMES OF THE ENSEMBLES WE WANT TO USE (example 'r1i1p1f1')
for(ALL ENSEMBLE NAMES){
  ensemble_data <- historical_data[historical_data$ensemble == ensemble_name, ]
  tas_models <- unique(ensemble_data [ensemble_data $variable == 'tas', ]$model) 
  areacella_models <- unique(ensemble_data [ensemble_data $variable == 'areacella', ]$model) 
  sftlf_models <- unique(ensemble_data [ensemble_data $variable == 'sftlf', ]$model) 
  models_with_data <- intersect(intersect(tas_models, areacella_models), sftlf_models)
  
  for(ALL MODELS WITH DATA){
    #call average_temp_cdo.R
    #call warming_ratio.R
    #write results of warming_ratio.R to csv file!
  }
}








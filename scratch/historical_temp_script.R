library(plyr)

path_name = 'land-ocean-warming-ratio/scratch/nc_data' #Where do we save data to?
cdo_path = '../../usr/local/Cellar/cdo/1.9.8/bin/cdo' #Where is cdo located on PIC

source(path_file(path_name, 'average_temp_cdo.R'))  # access to functions to calculate annual temperature -> where is it?

# get_usable_models:
# get a list of the models in the given ensemble with temperature data, areacella data, and sftlf data
# inputs:
#       ensemble: the string name of the ensemble we want data from
# outputs:
#       a string list of the names of the models with all of the needed data to calculate average annual temperature
get_usable_models = function(ensemble_data){
  tas_models <- unique(ensemble_data [ensemble_data $variable == 'tas', ]$model) 
  areacella_models <- unique(ensemble_data [ensemble_data $variable == 'areacella', ]$model) 
  sftlf_models <- unique(ensemble_data [ensemble_data $variable == 'sftlf', ]$model) 
  intersect(intersect(tas_models, areacella_models), sftlf_models)
}

# get_file:
# given a model and a data type get the path to the file within PIC
# input: data frame of ensemble data
# output: file path
get_file = function(ensemble_data, model, data_type){
  ensemble_data[c(ensemble_data$model == model & ensemble_data$variable == data_type),]$file
}

### MAIN ###

# Importing the CMIP6 archive 
archive <- readr::read_csv(url("https://raw.githubusercontent.com/JGCRI/CMIP6/master/cmip6_archive_index.csv"))
historical_data <- archive[c(archive$experiment == 'historical' & archive$variable %in% c('tas', 'areacella', 'sftlf')),]

df_temps <- data.frame(Ensemble = character(),
                      Model = character(),
                      Data = character(),
                      Time = integer(),
                      Temp = double())

ensembles = c('r1i1p1f1')  # ensembles we will loop over

for(e in ensembles){
  ensemble_data <- historical_data[historical_data$ensemble == e, ]
  models_with_data <- get_usable_models(ensemble_data)
  
  for(model in models_with_data){
    temp <- get_file(ensemble_data, model, 'tas')
    area <- get_file(ensemble_data, model, 'areacella')
    land_frac <- get_file(ensemble_data, model, 'sftlf')
    
    model_path_name <- file.path(path_name, paste0(e, '_', model))  # data for each model and ensemble will have its own folder
    dir.create(model_path_name)
  
    land_ocean_global_temps(model_path_name, cdo_path, temp, area, land_frac, TRUE)
    
    nc_open(file.path(path_name, 'land_temp.nc')) %>% ncvar_get("tas") -> land_tas
    nc_open(file.path(path_name, 'ocean_temp.nc')) %>% ncvar_get("tas") -> ocean_tas
    nc_open(file.path(path_name, 'global_temp.nc')) %>% ncvar_get("tas") -> global_tas
    nc_open(file.path(path_name, 'land_temp.nc')) %>% ncvar_get("time") -> time
    
    # create data frame out of land, ocean, and global annual data
    temp_frame <- data.frame(Ensemble = rep(e, dim(time)),
                             Model = rep(model, dim(time)),
                             Data = rep(c("Land", "Ocean", "Global"), each = dim(time)),
                             Time = rep(time, 3),
                             Temp = c(land_tas, ocean_tas, global_tas))
    
    df_temps <- rbind.fill(df_temps, temp_frame)
  }
}

write.csv(df_temps, file.path(path_name, 'temp.csv'))  # write data from all models and ensembles to .csv at path_name


library(plyr)

path_name = 'pic/projects/GCAM/Gering/land-ocean-warming-ratio' #Where do we save data to?
cdo_path = '../../share/apps/netcdf/4.3.2/gcc/4.4.7/bin/cdo'

source(file.path(path_name, 'average_temp_cdo.R'))  # access to functions to calculate annual temperature -> where is it?

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

# get_file_location:
# given a model and a data type get the path to the file within PIC
# input: data frame of ensemble data
# output: file path
get_file_location = function(ensemble_data, model, data_type){
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
  
  #FOR TESTING SET MODELS_WITH_DATA TO FIRST ELEMENT
  model <- models_with_data[1]
  
  for(model in models_with_data){
    temp <- get_file_location(ensemble_data, model, 'tas')
    area <- get_file_location(ensemble_data, model, 'areacella')
    land_frac <- get_file_location(ensemble_data, model, 'sftlf')
    
    model_ensemble = paste0(e, '_', model)
    
    model_path_name <- file.path(path_name, model_ensemble)  # data for each model and ensemble will have its own folder
    dir.create(model_path_name)
  
    land_ocean_global_temps(model_path_name, cdo_path, model_ensemble, temp, area, land_frac, TRUE)
    
    nc_open(file.path(model_path_name, paste0(model_ensemble,'land_temp.nc'))) %>% ncvar_get("tas") -> land_tas
    nc_open(file.path(model_path_name, paste0(model_ensemble,'ocean_temp.nc'))) %>% ncvar_get("tas") -> ocean_tas
    nc_open(file.path(model_path_name, paste0(model_ensemble,'global_temp.nc'))) %>% ncvar_get("tas") -> global_tas
    nc_open(file.path(model_path_name, paste0(model_ensemble,'land_temp.nc'))) %>% ncvar_get("time") -> time
    
    # create data frame out of land, ocean, and global annual data
    temp_frame <- data.frame(Ensemble = rep(e, dim(time)),
                             Model = rep(model, dim(time)),
                             Data = rep(c("Land", "Ocean", "Global"), each = dim(time)),
                             Time = rep(time, 3),
                             Temp = c(land_tas, ocean_tas, global_tas))
    write.csv(temp_frame, file.path(model_path_name, paste0(model_ensemble, "_temp.csv")))
    
    df_temps <- rbind.fill(df_temps, temp_frame)
  }
}

write.csv(df_temps, file.path(path_name, 'temp.csv'), row.names = FALSE)  # write data from all models and ensembles to .csv at path_name


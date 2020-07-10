#THIS FILE IS TO LOOP THROUGH ALL OF THE DATA AND CALL THE TEMP AND WARMING RATION FUNCTIONS
#MAKE A CSV FILE THAT WE WILL PUT ALL THE DATA IN

# Importing the CMIP6 archive 
archive <- readr::read_csv(url("https://raw.githubusercontent.com/JGCRI/CMIP6/master/cmip6_archive_index.csv"))
historical_data <- archive[c(archive$experiment == 'historical' & archive$variable %in% c('tas', 'areacella', 'sftlf')),]

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











# The purpose of this script is to select example nc files to use from the CMIP6 archive. 
# Using R to do this makes is reproducible and means that we are not picking models at 
# random to see if we have enough data (a nc file for every output variable).


# Importing the CMIP6 archive 
archive <- readr::read_csv(url("https://raw.githubusercontent.com/JGCRI/CMIP6/master/cmip6_archive_index.csv"))

# Subset the archive so that it only includes entries for the historical experiment 
# for the variables we are intrested in. (Here we are subsetting with base R, while using tidyverse and 
# data.table can nice they also have some problems. Having a good foundation of base R is ideal because 
# base R never really changes unlike tidyverse and data.table syntax).
historical_entries <- archive[c(archive$experiment == 'historical' & archive$variable %in% c('tas', 'areacella', 'sftlf')), ]

# Subset the data again so that it only contains results from a single ensemble, for now we don't care about 
# the other ensembles. 
historical_entries <- historical_entries[historical_entries$ensemble == 'r1i1p1f1', ] 

# Now we have to determine which of models have results for all three variables. There
# are several different ways we could go about doing this but for now let's rely on
# base R and determine which models have data in each  of the three variables.

## Make a vector that contains all of the models we have tas data for but make sure this vector only contains 
## a single entry for each model. What happens when we don't use unique()? 
tas_models <- unique(historical_entries[historical_entries$variable == 'tas', ]$model) 
areacella_models <- unique(historical_entries[historical_entries$variable == 'areacella', ]$model) 
sftlf_models <- unique(historical_entries[historical_entries$variable == 'sftlf', ]$model) 

# Now use intersect to determine which of the models are in all three variable lists. 
# These models will have the required data for all of the output variables we are intrested in. 
model_with_data <- intersect(intersect(tas_models, areacella_models), sftlf_models)

# For our example we want to take a look at a single model, select the files of a single model to 
# process. 
model_to_process <- model_with_data[1]
files <- historical_entries[historical_entries$model == model_to_process, ]$file
message('The files we want are at... \n', paste0(files, '\n'))



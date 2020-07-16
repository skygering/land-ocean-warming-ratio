library(ncdf4)
library(ggplot2)
library(dplyr)

#get_weighted_area:
#Calculates and saves the fraction of each grid that is land and ocean in decimal form (max 1, min 0) and saves both
#inputs:
#     land_frac: .nc file location that contains fraction of grid that is land (either in decimal or percent)
#     land_area: .nc file location that will contain the area of each gris square weighted by the percent of the grid that is land
#     ocean_frac: .nc file location that will contain the area of each gris square weighted by the percent of the grid that is
#     cleanup: a boolean value - if true than intermediate files will be deleted - defaults to true
#outputs:
#     land_area.nc and ocean_area.nc: as specified above - saved at path_name

get_weighted_areas = function(land_frac, land_area, ocean_area, cleanup = TRUE){
  
  nc_open(land_frac) %>% ncvar_get('sftlf') %>% max(na.rm = FALSE) -> max_frac
  
  if(max_frac > 1){
    land_frac_dec <- file.path(path_name, paste0(model_ensemble,"_land_frac.nc"))
    system2(cdo_path, args = c('divc,100', land_frac, land_frac_dec))
    land_frac <- land_frac_dec
  }
  
  ocean_frac <- file.path(path_name, paste0(model_ensemble,'_ocean_frac.nc'))
  system2(cdo_path, args = c('-mulc,-1', '-addc,-1', land_frac, ocean_frac), stdout = TRUE, stderr = TRUE)
  
  #calculates weighted area
  system2(cdo_path, args = c('mul', area, land_frac, land_area), stdout = TRUE, stderr = TRUE)
  system2(cdo_path, args = c('mul', area, ocean_frac, ocean_area), stdout = TRUE, stderr = TRUE)
  
  if(cleanup){
    file.remove(ocean_frac)
    if(exists('land_frac_dec')){  # if it doesn't exist this is original sftlf data, which we don't want to delete
      file.remove(land_frac)
    }
  }
  
}

# get_annual_temp:
# Calculates the annual temp based on the weighting .nc file passed into the function
# inputs: 
#     weight_area: .nc file location that contains the weighted area of each grid square
#     annual_temp: .nc file location that will contain the weighted average temperature over the data's time steps
#     cleanup: a boolean value - if true than intermediate files will be deleted - defaults to true
#outputs:
#     annual_temp: as specified above - saved at path_name

get_annual_temp = function(weight_area, annual_temp, cleanup = TRUE){
  assertthat::assert_that(file.exists(weight_area))
  if(!file.exists(annual_temp)){
    #file to be created
    combo <-file.path(path_name, paste0(model_ensemble,'_combo_weight_temp.nc'))  # temp and weighted area parameteres in same netCDF files so weighted mean can be calculated
    month_temp <- file.path(path_name, paste0(model_ensemble,'_month_temp.nc'))
    
    #calculates weighted average temperature for each timestep
    system2(cdo_path, args = c('merge', temp, weight_area, combo), stdout = TRUE, stderr = TRUE)
    system2(cdo_path, args = c('-fldmean', combo, month_temp), stdout = TRUE, stderr = TRUE)
    system2(cdo_path, args = c('-a', 'yearmonmean', month_temp, annual_temp), stdout = TRUE, stderr = TRUE) #Might be able to combine on PIC -> seg fault rn
    
    if(cleanup){
      file.remove(combo)
      file.remove(month_temp)
      if(!identical(weight_area, area)){  # don't want to remove area if it is for global temperature
        file.remove(weight_area)
      }
    }
  }
}


# land_ocean_temps:
# Calculates average annual temperatures for land, ocean, and global
# Inputs:
#       path_name: path to a folder where the output .nc files will be stored
#       cdo_path: path to where the cdo.exe is located on the local computer
#       temp: .nc file location that contains the monthly temperature data
#       area: .nc file location that contains the area of each grid cell 
#       land_fac: .nc file location that contains the percent of each grid cell that is land
# Outputs:
#       Three .nc files (land_temp.nc, ocean_temp.nc, and global_temp.nc) which contain annual average temperatures -
#       Located at path_name

land_ocean_global_temps = function(path_name, cdo_path, model_ensemble, temp, area, land_frac, cleanup = TRUE){
  assertthat::assert_that(file.exists(temp))
  assertthat::assert_that(file.exists(area))
  assertthat::assert_that(file.exists(land_frac))
  
  land_area <-  file.path(path_name, paste0(model_ensemble, '_land_area.nc'))
  ocean_area <- file.path(path_name, paste0(model_ensemble, '_ocean_area.nc'))
  if(!file.exists(land_area) && !file.exists(ocean_area)){
    get_weighted_areas(land_frac, land_area, ocean_area, cleanup)
  }
  
  land_temp <- file.path(path_name, paste0(model_ensemble, '_land_temp.nc'))
  ocean_temp <- file.path(path_name, paste0(model_ensemble, '_ocean_temp.nc'))
  global_temp <- file.path(path_name, paste0(model_ensemble, '_global_temp.nc'))
  

  get_annual_temp(land_area, land_temp, cleanup)
  get_annual_temp(ocean_area, ocean_temp, cleanup)
  get_annual_temp(area, global_temp, cleanup)
 
}






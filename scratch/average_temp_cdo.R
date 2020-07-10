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
  assertthat::assert_that(file.exists(land_frac))
  assertthat::assert_that(file.exists(area))
  
  nc_open(land_frac) %>% ncvar_get('sftlf') %>% max(na.rm = FALSE) -> max_frac
  if(max_frac > 1){
    land_frac_dec <- file.path(path_name, "land_frac.nc")
    system2(cdo_path, args = c('divc,100', land_frac, land_frac_dec))
    land_frac <- land_frac_dec
  }
  
  ocean_frac <- file.path(path_name, 'ocean_frac.nc')
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
  #file to be created
  combo <-file.path(path_name, 'combo_weight_temp.nc')  # temp and weighted area parameteres in same netCDF files so weighted mean can be calculated
  
  #calculates weighted average temperature for each timestep
  combo <-file.path(path_name, 'combo_weight_temp.nc')
  system2(cdo_path, args = c('merge', temp, weight_area, combo), stdout = TRUE, stderr = TRUE)
  system2(cdo_path, args = c('-fldmean', combo, annual_temp), stdout = TRUE, stderr = TRUE)
  assertthat::assert_that(file.exists(combo))
  
  if(cleanup){
    file.remove(combo)
    if(!identical(weight_area, area)){  # don't want to remove area if it is for global temperature
      file.remove(weight_area)
    }
  }
}


### MAIN ###
#These are paths that are specific to your computer and need to be adjusted before running this script
path_name = 'land-ocean-warming-ratio/scratch/nc_data'
cdo_path = '../../usr/local/Cellar/cdo/1.9.8/bin/cdo'

# This is the data that you want to analyize (3 .nc files). They need to be in the same file as path_name
temp <- file.path(path_name, 'tas_Amon_ACCESS-CM2_historical_r1i1p1f1_gn_185001-201412.nc')
area <- file.path(path_name, 'areacella_fx_ACCESS-CM2_historical_r1i1p1f1_gn.nc')
land_frac <- file.path(path_name, 'sftlf_fx_ACCESS-CM2_historical_r1i1p1f1_gn.nc')

land_area <-  file.path(path_name, 'land_area.nc')
ocean_area <- file.path(path_name, 'ocean_area.nc')
get_weighted_areas(land_frac, land_area, ocean_area)
  
land_temp <- file.path(path_name, 'land_temp.nc')
ocean_temp <- file.path(path_name, 'ocean_temp.nc')
global_temp <- file.path(path_name, 'global_temp.nc')
  
get_annual_temp(land_area, land_temp)
get_annual_temp(ocean_area, ocean_temp)
get_annual_temp(area, global_temp)


#getting variables
nc_open(land_temp) %>% ncvar_get("tas") -> land_tas
nc_open(ocean_temp) %>% ncvar_get("tas") -> ocean_tas
nc_open(global_temp) %>% ncvar_get("tas") -> global_tas

nc_open(temp) %>% ncvar_get("time") %>% as.Date('1850-01-01', tz = "PDT") -> time

#make data frame (same code as above in R section)
temp_frame <- data.frame(Data = rep(c("Land", "Ocean", "Global"), each = dim(time)),
                            Time = rep(time, 3),
                            Temp = c(land_tas, ocean_tas, global_tas))

#graphing
ggplot(temp_frame, aes(x = Time, y = Temp, group = Data)) + geom_line(aes(linetype=Data, color=Data))+
  geom_point(aes(color=Data)) + ggtitle("Average Surface Temperature") + 
  theme(plot.title = element_text(hjust = 0.5)) + xlab("Time (year)") + ylab("Temp (K)") +
  coord_cartesian()



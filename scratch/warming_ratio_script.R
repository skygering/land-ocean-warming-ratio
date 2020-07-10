library(ncdf4)
library(ggplot2)
library(dplyr)

#These are paths that are specific to your computer and need to be adjusted before running this script
path_name = 'land-ocean-warming-ratio/scratch/nc_data'
cdo_path = '../../usr/local/Cellar/cdo/1.9.8/bin/cdo'

# This is the data that you want to analyize (3 .nc files). They need to be in the same file as path_name
temp <- file.path(path_name, 'tas_Amon_ACCESS-CM2_historical_r1i1p1f1_gn_185001-201412.nc')
area <- file.path(path_name, 'areacella_fx_ACCESS-CM2_historical_r1i1p1f1_gn.nc')
land_frac <- file.path(path_name, 'sftlf_fx_ACCESS-CM2_historical_r1i1p1f1_gn.nc')

#get_fractions:
#Calculates and saves the fraction of each grid that is land and ocean in decimal form (max 1, min 0) and saves both
#inputs:
#     land_frac: .nc file location that contains fraction of grid that is land (either in decimal or percent)
#     ocean_frac: .nc file location that will contain the fraction of each grid that is land in decimal form
#outputs:
#     land_frac.nc and ocean_frac.nc: as specified above - saved at path_name
get_fractions = function(land_frac, ocean_frac){
  nc_open(land_frac) %>% ncvar_get('sftlf') %>% max(na.rm = FALSE) -> max_frac
  if(max_frac > 1){
    land_frac_dec <- file.path(path_name, "land_frac.nc")
    system2(cdo_path, args = c('divc,100', land_frac, land_frac_dec))
    land_frac <- land_frac_dec
  }
  system2(cdo_path, args = c('-mulc,-1', '-addc,-1', land_frac, ocean_frac), stdout = TRUE, stderr = TRUE)
}

# get_annual_temp:
# Cacluates the annual temp based on the weighting .nc file passed into the function
# inputs: 
#     frac_area: .nc file location that contains the fraction of the grid with either land/ocean
#     annual_temp: .nc file location that will contain the weighted average temperature over the data's time steps
#outputs:
#     annual_temp: as specified above - saved at path_name

get_annual_temp = function(frac_area, annual_temp){
  
  #files to be created
  weight_area <- file.path(path_name, 'weighted_area.nc')  # netCDF holding land/ocean fraction multiplied by area netCDF giving weighted area
  combo <-file.path(path_name, 'combo_weight_temp.nc')  # temp and weighted area parameteres in same netCDF files so weighted mean can be calculated
  
  #calculates weighted area
  system2(cdo_path, args = c('mul', area, frac_area, weight_area), stdout = TRUE, stderr = TRUE)
  assertthat::assert_that(file.exists(weight_area))
  
  #calculates weighted average temperature for each timestep
  combo <-file.path(path_name, 'combo_weight_temp.nc')
  system2(cdo_path, args = c('merge', temp, weight_area, combo), stdout = TRUE, stderr = TRUE)
  system2(cdo_path, args = c('-fldmean', combo, annual_temp), stdout = TRUE, stderr = TRUE)
  assertthat::assert_that(file.exists(combo))
  
  #deletes intermediate files
  file.remove(weight_area)
  file.remove(combo)
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

get_warming_constant = function(land_temp, ocean_temp, land_warming, ocean_warming, ratio){
  nc_open(land_temp) %>% ncvar_get("tas") -> land
  nc_open(ocean_temp) %>% ncvar_get("tas") -> ocean
  land_base <- land[1] *-1
  ocean_base <- ocean[1] *-1
  
  #It doesn't like that I am adding variables..... might need to do in R?
  system2(cdo_path, args = c('addc,', land_base, land_temp, land_warming))
  system2(cdo_path, args = c('addc,', ocean_base, ocean_temp, ocean_warming))
  system2(cdo_path, args = c('div', land_warming, ocean_warming, ratio))
  
}

#Main method??

  ocean_frac <- file.path(path_name, 'ocean_frac.nc')
  get_fractions(land_frac, ocean_frac)
  
  land_temp <- file.path(path_name, 'land_temp.nc')
  ocean_temp <- file.path(path_name, 'ocean_temp.nc')
  
  get_annual_temp(land_frac, land_temp)
  get_annual_temp(ocean_frac, ocean_temp)
  
  land_warming <- file.path(path_name, 'land_warming.nc')
  ocean_warming <- file.path(path_name, 'ocean_warming.nc')
  ratio <- file.path(path_name, 'ratio.nc')
  
  get_warming_constant(land_temp, ocean_temp, land_warming, ocean_warming, ratio)



#getting variables
nc_open(land_temp) %>% ncvar_get("tas") -> land_tas
nc_open(ocean_temp) %>% ncvar_get("tas") -> ocean_tas

nc_open(temp) %>% ncvar_get("time") %>% as.Date('1850-01-01', tz = "PDT") -> time

#make data frame (same code as above in R section)
temp_frame <- data.frame(Data = rep(c("Land", "Ocean"), each = dim(time)),
                            Time = rep(time, 2),
                            Temp = c(land_tas, ocean_tas))

#graphing
ggplot(temp_frame, aes(x = Time, y = Temp, group = Data)) + geom_line(aes(linetype=Data, color=Data))+
  geom_point(aes(color=Data)) + ggtitle("Average Surface Temperature") + 
  theme(plot.title = element_text(hjust = 0.5)) + xlab("Time (year)") + ylab("Temp (K)")




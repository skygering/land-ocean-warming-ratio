library(ncdf4)
library(ggplot2)
library(dplyr)

#These are paths that are specific to your computer and need to be adjusted before running this script
path_name = 'land-ocean-warming-ratio/scratch/0000-0025_nc_data'
cdo_path = '../../usr/local/Cellar/cdo/1.9.8/bin/cdo'

# This is the data that you want to analyize (3 .nc files). They need to be in the same file as path_name
temp <- file.path(path_name, 'tas_Amon_E3SM-1-0_1pctCO2_r1i1p1f1_gr_000101-002512.nc')
area <- file.path(path_name, 'areacella_fx_E3SM-1-0_1pctCO2_r1i1p1f1_gr.nc')
land_frac <- file.path(path_name, 'sftlf_fx_E3SM-1-0_1pctCO2_r1i1p1f1_gr.nc')

# netCDF file that holds the fraction of each grid cell occupied by water (1-land_frac)
ocean_frac <- file.path(path_name, 'ocean_frac.nc')
system2(cdo_path, args = c('-mulc,-1', '-addc,-1', land_frac, ocean_frac), stdout = TRUE, stderr = TRUE)

# get_annual_temp:
# inputs: 
#     frac_area: name of a .nc file that contains the fraction of the grid with either land/ocean
#     annual_temp: name of output .nc file that will contain the weighted average temperature over the data's time steps

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

get_warming_constant = function(land_temp, ocean_temp, land_warming, ocean_warming, ratio){
  nc_open(land_temp) %>% ncvar_get("tas") -> land
  nc_open(ocean_temp) %>% ncvar_get("tas") -> ocean
  land_base <- land[1] *-1
  ocean_base <- ocean[1] *-1
  
  system2(cdo_path, args = c('addc,', land_base, land_temp, land_warming))
  system2(cdo_path, args = c('addc,', ocean_base, ocean_temp, ocean_warming))
  
  
}

land_temp <- file.path(path_name, 'land_temp.nc')
ocean_temp <- file.path(path_name, 'ocean_temp.nc')

get_annual_temp(land_frac, land_temp)
get_annual_temp(ocean_frac, ocean_temp)

land_warming <- file.path(path_name, 'land_warming.nc')
ocean_warming <- file.path(path_name, 'ocean_warming.nc')


#getting variables
nc_open(land_temp) %>% ncvar_get("tas") -> land_temp
nc_open(ocean_temp) %>% ncvar_get("tas") -> ocean_temp

nc_open(temp_nc) %>% ncvar_get("time") %>% as.Date("0001-01-01", tz = "PDT") -> time_nc

#make data frame (same code as above in R section)
temp_frame_nc <- data.frame(Data = rep(c("Land", "Ocean"), each = 300),
                            Time = rep(time_nc, 2),
                            Temp = c(land_temp, ocean_temp))

ggplot(temp_frame_nc, aes(x = Time, y = Temp, group = Data)) + geom_line(aes(linetype=Data, color=Data))+
  geom_point(aes(color=Data)) + ggtitle("Average Monthly Surface Temperature") + 
  theme(plot.title = element_text(hjust = 0.5)) + xlab("Time (year)") + ylab("Temp (K)")


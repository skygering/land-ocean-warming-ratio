library(ncdf4)
library(ggplot2)
library(dplyr)

#opens nc files and saves variables 
nc_open("land-ocean-warming-ratio/scratch/nc_data/tas_Amon_E3SM-1-0_1pctCO2_r1i1p1f1_gr_000101-002512.nc") %>%
  ncvar_get("tas") -> temp

nc_open("land-ocean-warming-ratio/scratch/nc_data/tas_Amon_E3SM-1-0_1pctCO2_r1i1p1f1_gr_000101-002512.nc") %>%
  ncvar_get("time") -> time

nc_open("land-ocean-warming-ratio/scratch/nc_data/sftlf_fx_E3SM-1-0_1pctCO2_r1i1p1f1_gr.nc") %>%
  ncvar_get("sftlf") -> land_frac

nc_open("land-ocean-warming-ratio/scratch/nc_data/areacella_fx_E3SM-1-0_1pctCO2_r1i1p1f1_gr.nc") %>%
  ncvar_get("areacella") -> area_cell

ocean_frac = 1 - land_frac

weighted_land_area = land_frac * area_cell
weighted_ocean_area = ocean_frac * area_cell

land_temp <- apply(temp, 3, function(x) weighted.mean(x, w = weighted_land_area, na.rm = TRUE))
ocean_temp <- apply(temp, 3, function(x) weighted.mean(x, w = weighted_ocean_area, na.rm = TRUE))
global_temp <- apply(temp, 3, function(x) weighted.mean(x, w = area_cell, na.rm = TRUE))
unweighted_global_temp <- apply(temp, 3, function(x) mean(x, na.rm = TRUE))

land_temp_df <- data.frame(time = time, value = land_temp)
ocean_temp_df <- data.frame(time = time, value = ocean_temp)
global_temp_df <- data.frame(time = time, value = global_temp)
uw_global_temp_df <- data.frame(time = time, value = unweighted_global_temp)



#cdo_land_area <- function(land_frac, area_cell, save_path){
  
  #LandArea_nc <- file.path(save_path, 'land-ocean-warming-ratio/scratch/nc_data/tas_Amon_E3SM-1-0_1pctCO2_r1i1p1f1_gr_000101-002512_LandArea.nc')
  #cdo_path = '../../usr/local/Cellar/cdo/1.9.8/bin/cdo'
  #weighted_land <- system2(cdo_path, args = c("mul", area_cell, land_frac, LandArea_nc), stdout = TRUE, stderr = TRUE)
  
  
  
  
  
  
}

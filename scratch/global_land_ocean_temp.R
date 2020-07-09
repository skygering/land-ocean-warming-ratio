library(ncdf4)
library(ggplot2)
library(dplyr)

####USING ONLY R#####

#opens nc files and saves variables [THESE CAN BE COMBINED WITH PIPELINES IF DONT USE CDO]
nc_open("land-ocean-warming-ratio/scratch/nc_data/tas_Amon_E3SM-1-0_1pctCO2_r1i1p1f1_gr_000101-002512.nc") %>% 
  ncvar_get("tas") -> temp

nc_open("land-ocean-warming-ratio/scratch/nc_data/areacella_fx_E3SM-1-0_1pctCO2_r1i1p1f1_gr.nc") %>%
  ncvar_get("areacella") -> area_cell

nc_open("land-ocean-warming-ratio/scratch/nc_data/sftlf_fx_E3SM-1-0_1pctCO2_r1i1p1f1_gr.nc") %>%
  ncvar_get("sftlf") -> land_frac

nc_open("land-ocean-warming-ratio/scratch/nc_data/tas_Amon_E3SM-1-0_1pctCO2_r1i1p1f1_gr_000101-002512.nc") %>%
  ncvar_get("time") %>% as.Date("0001-01-01 00:00:00", tz = "PDT") -> time

#all grid space that is not land is ocean
ocean_frac = 1 - land_frac

#Find the weight of land and ocean
weighted_land_area = land_frac * area_cell
weighted_ocean_area = ocean_frac * area_cell

#find the weighted mean using the appropriate weight depending on land/sea/global
land_temp <- apply(temp, 3, function(x) weighted.mean(x, w = weighted_land_area, na.rm = TRUE)) #land area
ocean_temp <- apply(temp, 3, function(x) weighted.mean(x, w = weighted_ocean_area, na.rm = TRUE)) #ocean area
global_temp <- apply(temp, 3, function(x) weighted.mean(x, w = area_cell, na.rm = TRUE)) #all area

#make a data frame with all land, ocean, and global average temperatures
temp_frame <- data.frame(Data = rep(c("Land", "Ocean", "Global"), each = 300),
                         Time = rep(time, 3),
                         Temp = c(land_temp, ocean_temp, global_temp))

#plot
ggplot(temp_frame, aes(x = Time, y = Temp, group = Data)) + geom_line(aes(linetype=Data, color=Data))+
  geom_point(aes(shape=Data, color=Data)) + ggtitle("Average Monthly Surface Temperature") + 
  theme(plot.title = element_text(hjust = 0.5)) + xlab("Time (year)") + ylab("Temp (K)")

####ALL IN CDO####

# Original files that will be inputs
temp_nc <- "land-ocean-warming-ratio/scratch/nc_data/tas_Amon_E3SM-1-0_1pctCO2_r1i1p1f1_gr_000101-002512.nc"
area_nc <- "land-ocean-warming-ratio/scratch/nc_data/areacella_fx_E3SM-1-0_1pctCO2_r1i1p1f1_gr.nc"
land_frac_nc <- "land-ocean-warming-ratio/scratch/nc_data/sftlf_fx_E3SM-1-0_1pctCO2_r1i1p1f1_gr.nc"


# New Files to be created through CDO commands
  LandArea_nc <- 'land-ocean-warming-ratio/scratch/nc_data/LandArea.nc'
  OceanFrac_nc <- 'land-ocean-warming-ratio/scratch/nc_data/OceanFrac.nc'
  OceanArea_nc <- 'land-ocean-warming-ratio/scratch/nc_data/OceanArea.nc'
  
  cdo_path = '../../usr/local/Cellar/cdo/1.9.8/bin/cdo'
  
  # Calculating weights for land and ocean
  system2(cdo_path, args = c('mul', area_nc, land_frac_nc, LandArea_nc), stdout = TRUE, stderr = TRUE)
  system2(cdo_path, args = c('-mulc,-1', '-addc,-1', land_frac_nc, OceanFrac_nc), stdout = TRUE, stderr = TRUE)
  system2(cdo_path, args = c('mul', area_nc, OceanFrac_nc, OceanArea_nc), stdout = TRUE, stderr = TRUE)
  
  
  # Creating intermediate file linking temperature data to weighted grid cells -> will be overwritten for ocean, land, and global
  out1 <-'land-ocean-warming-ratio/scratch/nc_data/out1.nc'
  out2 <-'land-ocean-warming-ratio/scratch/nc_data/out2.nc'
  out3 <- 'land-ocean-warming-ratio/scratch/nc_data/out3.nc'
  
  # New file paths and names for the average temperatures calculated using fldmean and the weights calculated above
  GlobalTemp_nc <- 'land-ocean-warming-ratio/scratch/nc_data/GlobalTemp.nc'
  OceanTemp_nc <- 'land-ocean-warming-ratio/scratch/nc_data/OceanTemp.nc'
  LandTemp_nc <- 'land-ocean-warming-ratio/scratch/nc_data/LandTemp.nc'
  
  ###SETGRIDAREA isn't working right...
  
  #Land
  system2(cdo_path, args = c('merge', temp_nc, LandArea_nc, out1), stdout = TRUE, stderr = TRUE)
  system2(cdo_path, args = c('-fldmean', out1, LandTemp_nc), stdout = TRUE, stderr = TRUE)
  
  #Ocean
  system2(cdo_path, args = c('merge', temp_nc, OceanArea_nc, out2), stdout = TRUE, stderr = TRUE)
  system2(cdo_path, args = c('-fldmean', out2, OceanTemp_nc), stdout = TRUE, stderr = TRUE)
  
  #Global
  system2(cdo_path, args = c('merge', temp_nc, area_nc, out3), stdout = TRUE, stderr = TRUE)
  system2(cdo_path, args = c('-fldmean', out3, GlobalTemp_nc), stdout = TRUE, stderr = TRUE)
  
  
  #graphing land, ocean, and global from CDO
  
  #getting variables
  nc_open(LandTemp_nc) %>% ncvar_get("tas") -> land_temp_nc
  nc_open(OceanTemp_nc) %>% ncvar_get("tas") -> ocean_temp_nc
  nc_open(GlobalTemp_nc) %>% ncvar_get("tas") -> global_temp_nc
  nc_open(temp_nc) %>% ncvar_get("time") %>% as.Date("0001-01-01", tz = "PDT") -> time_nc
  
  #make data frame (same code as above in R section)
  temp_frame_nc <- data.frame(Data = rep(c("Land", "Ocean", "Global"), each = 300),
                           Time = rep(time_nc, 3),
                           Temp = c(land_temp_nc, ocean_temp_nc, global_temp_nc))
  
  ggplot(temp_frame_nc, aes(x = Time, y = Temp, group = Data)) + geom_line(aes(linetype=Data, color=Data))+
    geom_point(aes(color=Data)) + ggtitle("Average Monthly Surface Temperature") + 
    theme(plot.title = element_text(hjust = 0.5)) + xlab("Time (year)") + ylab("Temp (K)")
  


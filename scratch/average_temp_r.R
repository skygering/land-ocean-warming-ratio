library(ncdf4)
library(ggplot2)
library(dplyr)

path_name = 'land-ocean-warming-ratio/scratch/nc_data'

nc_open(file.path(path_name, 'tas_Amon_ACCESS-CM2_historical_r1i1p1f1_gn_185001-201412.nc')) %>% 
  ncvar_get('tas') -> temp

nc_open(file.path(path_name, 'areacella_fx_ACCESS-CM2_historical_r1i1p1f1_gn.nc')) %>%
  ncvar_get('areacella') -> area_cell

nc_open(file.path(path_name, 'sftlf_fx_ACCESS-CM2_historical_r1i1p1f1_gn.nc')) %>%
  ncvar_get('sftlf') -> land_frac

nc_open(file.path(path_name, 'land-ocean-warming-ratio/scratch/nc_data/tas_Amon_ACCESS-CM2_historical_r1i1p1f1_gn_185001-201412.nc')) %>%
  ncvar_get('time') -> time

if(max(land_frac) > 1){
  land_frac <- land_frac/100
}

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
temp_frame <- data.frame(Data = rep(c("Land", "Ocean", "Global"), each = 1980),
                         Time = rep(time, 3),
                         Temp = c(land_temp, ocean_temp, global_temp))

#plot
ggplot(temp_frame, aes(x = Time, y = Temp, group = Data)) + geom_line(aes(linetype=Data, color=Data))+
  geom_point(aes(shape=Data, color=Data)) + ggtitle("Average Monthly Surface Temperature") + 
  theme(plot.title = element_text(hjust = 0.5)) + xlab("Time (year)") + ylab("Temp (K)")

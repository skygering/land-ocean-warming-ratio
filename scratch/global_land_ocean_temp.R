library(ncdf4)
library(ggplot2)
library(dplyr)

#opens nc files and saves variables [THESE CAN BE COMBINED WITH PIPELINES IF DONT USE CDO]
nc_temp <- nc_open("land-ocean-warming-ratio/scratch/nc_data/tas_Amon_E3SM-1-0_1pctCO2_r1i1p1f1_gr_000101-002512.nc")
nc_area <- nc_open("land-ocean-warming-ratio/scratch/nc_data/areacella_fx_E3SM-1-0_1pctCO2_r1i1p1f1_gr.nc")
nc_land_frac <-nc_open("land-ocean-warming-ratio/scratch/nc_data/sftlf_fx_E3SM-1-0_1pctCO2_r1i1p1f1_gr.nc")

temp <- ncvar_get(nc_temp, "tas")
area_cell <- ncvar_get(nc_area, "areacella")
land_frac <- ncvar_get(nc_frac, "sftlf")

nc_open("land-ocean-warming-ratio/scratch/nc_data/tas_Amon_E3SM-1-0_1pctCO2_r1i1p1f1_gr_000101-002512.nc") %>%
  ncvar_get("time") %>% as.Date(time, "0001-01-01 00:00:00", tz = "PDT") -> time


  

#all grid space that is not land is ocean
ocean_frac = 1 - land_frac

weighted_land_area = land_frac * area_cell
weighted_ocean_area = ocean_frac * area_cell

land_temp <- apply(temp, 3, function(x) weighted.mean(x, w = weighted_land_area, na.rm = TRUE))
ocean_temp <- apply(temp, 3, function(x) weighted.mean(x, w = weighted_ocean_area, na.rm = TRUE))
global_temp <- apply(temp, 3, function(x) weighted.mean(x, w = area_cell, na.rm = TRUE))

temp_frame <- data.frame(Data = rep(c("Land", "Ocean", "Global"), each = 300),
                         Time = rep(time, 3),
                         Temp = c(land_temp, ocean_temp, global_temp))

ggplot(temp_frame, aes(x = Time, y = Temp, group = Data)) + geom_line(aes(linetype=Data, color=Data))+
  geom_point(aes(shape=Data, color=Data)) + ggtitle("Average Monthly Surface Temperature") + 
  theme(plot.title = element_text(hjust = 0.5)) + xlab("Time (year)") + ylab("Temp (K)")

#QUESTIONS:
#1) Why would I make netCDf files for any of these outputs? Seems simple to do in R
#2) How do you use System2. I realized I used system() earlier and I don't understand the difference
#3) Need to talk about how to calculate warming since it is a rate --  from when?
#4) In the example file, it seems like the frac file was in %, not dec. What is standard?
#5) How do I pull apart file names? In the example there is a parse_cmip_info function. 
    #Should I try to write something or is this availible

  LandArea_nc <- 'land-ocean-warming-ratio/scratch/nc_data/tas_Amon_E3SM-1-0_1pctCO2_r1i1p1f1_gr_000101-002512_LandArea.nc'
  OceanFrac_nc <- 'land-ocean-warming-ratio/scratch/nc_data/tas_Amon_E3SM-1-0_1pctCO2_r1i1p1f1_gr_000101-002512_OceanFrac.nc'
  OceanArea_nc <- 'land-ocean-warming-ratio/scratch/nc_data/tas_Amon_E3SM-1-0_1pctCO2_r1i1p1f1_gr_000101-002512_OceanArea.nc'
  cdo_path = '../../usr/local/Cellar/cdo/1.9.8/bin/cdo'
  
  #weighted_land <- system2('cdo.exe', args = c("mul", nc_area, nc_frac, LandArea_nc), stdout = TRUE, stderr = TRUE)
  
  weighted_land <- system(paste(cdo_path, ' mul ', nc_area, " ", nc_land_frac, " ", LandArea_nc)) #output in nc_data folder from panoply
  weighted_ocean <- system(paste(cdo_path, ' -mulc,-1', ' -addc,-1 ', nc_land_frac, " ", OceanFrac_nc))
  
  
  
  
}

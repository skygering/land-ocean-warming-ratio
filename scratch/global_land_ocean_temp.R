library(ncdf4)
library(dplyr)
library(tidyr)
library(tibble)
library(readr)


#open temperature data
tas = nc_open("land-ocean-warming-ratio/scratch/nc_data/tas_Amon_E3SM-1-0_1pctCO2_r1i1p1f1_gr_000101-002512.nc")
areaCell = nc_open("land-ocean-warming-ratio/scratch/nc_data/areacella_fx_E3SM-1-0_1pctCO2_r1i1p1f1_gr.nc")
landFrac = nc_open("land-ocean-warming-ratio/scratch/nc_data/sftlf_fx_E3SM-1-0_1pctCO2_r1i1p1f1_gr.nc")

cdo_land_area <- function(data, filePath){
  
}
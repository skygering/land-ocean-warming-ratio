library(ncdf4)
library(ggplot2)
library(dplyr)

nc_open("land-ocean-warming-ratio/scratch/nc_data/tas_Amon_E3SM-1-0_1pctCO2_r1i1p1f1_gr_000101-002512.nc") %>%
  ncvar_get("tas") -> temp

nc_open("land-ocean-warming-ratio/scratch/nc_data/sftlf_fx_E3SM-1-0_1pctCO2_r1i1p1f1_gr.nc") %>%
  ncvar_get("sftlf") -> landFrac

nc_open("land-ocean-warming-ratio/scratch/nc_data/areacella_fx_E3SM-1-0_1pctCO2_r1i1p1f1_gr.nc") %>%
  ncvar_get("areacella") -> areaCell




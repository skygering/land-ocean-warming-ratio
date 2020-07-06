library(ncdf4)
library(dplyr)
library(tidyr)
library(tibble)
library(readr)


#open temperature data
archive <- readr::read_csv(url("https://raw.githubusercontent.com/JGCRI/CMIP6/master/cmip6_archive_index.csv"))
 
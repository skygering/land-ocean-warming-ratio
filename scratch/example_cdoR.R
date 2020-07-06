
#upload information
cmip6_archive <- read.csv(file = '/pic/projects/GCAM/CMIP6/cmip6_archive_index.csv', stringsAsFactors = FALSE)

#old code -> get the data from the archive
cmip6_archive %>%
    dplyr::filter(variable == 'tas' & domain == 'Amon') %>%
    dplyr::filter(experiment %in% c('1pctCO2', 'abrupt-4xCO2', 'historical', 'piControl')) %>%
    as.data.table ->
    tas_data

cmip6_archive %>%
    dplyr::filter(variable %in% c('areacella', 'sftlf')) %>%
    dplyr::select(-time, -domain, -type) %>%
    tidyr::spread(variable, file) %>%
    na.omit %>%
    as.data.table ->
    meta_data

#combines the two downloaded data sets into catagories "model", "experiment", "ensemble", and "grid"
tas_meta <- dplyr::inner_join(tas_data, meta_data, by = c("model", "experiment", "ensemble", "grid"))


#creates function cdo_land_area
#inputs: dt (see below "input" for form) and intermed_dir (directory name)
cdo_land_area <- function(dt, intermed_dir){

    # Check the inputs
    assertthat::assert_that(all(c('areacella', 'sftlf') %in% names(dt)))
    info <- parse_cmip_info(dt, not_required = 'variable')
    basename <- paste(info, collapse = '_')
    
    #creates files to save the percent land and land area data
    PercentLand_nc <- file.path(intermed_dir, paste0(basename, '_PercentLand.nc'))
    LandArea_nc    <- file.path(intermed_dir, paste0(basename, '_LandArea.nc'))

    #uses cdo to calculate percent land and land area data
    system2(cdoR::cdo_exe, args = c("-divc,100", dt[['sftlf']], PercentLand_nc), stdout = TRUE, stderr = TRUE)
    system2(cdoR::cdo_exe, args = c("-mul", dt[['areacella']], PercentLand_nc, LandArea_nc), stdout = TRUE, stderr = TRUE)

    #makes sure that LandArea_nc gets created
    assertthat::assert_that(file.exists(LandArea_nc))
    LandArea_nc

}


#creates function cdo_yearmonmean (yearly mean from monthly data)
cdo_yearmonmean <- function(name, in_nc, intermed_dir){

    #makes sure that the files all exist
    assertthat::assert_that(file.exists(in_nc))
    assertthat::assert_that(dir.exists(intermed_dir))
    
    #creates the output file name and if that file already exists it deletes the earlier file
    out_nc      <- file.path(intermed_dir, paste0(name, '-yearmonmean.nc'))
    if(file.exists(out_nc)) file.remove(out_nc)

    #does cdo calculation
    system2(cdoR::cdo_exe, args = c('yearmonmean', in_nc, out_nc), stdout = TRUE, stderr = TRUE)

    assertthat::assert_that(file.exists(out_nc))
    out_nc
}

#creates function cdo_ocean_area with inputs dt and intermed_dir
cdo_ocean_area <- function(dt, intermed_dir){

    # Check the inputs
    assertthat::assert_that(all(c('areacella', 'sftlf') %in% names(dt)))
    info <- parse_cmip_info(dt, not_required = 'variable')
    basename <- paste(info, collapse = '_')
    
    #creates new files
    PercentOcean_nc <- file.path(intermed_dir, paste0(basename, '_PercentOcean.nc'))
    OceanArea_nc    <- file.path(intermed_dir, paste0(basename, '_OceanArea.nc'))

    #subtract a constant of 1 to get land percentage and multiply by a constant of -0.01
    #does it go inside to outside or outside to inside (??)
    system2(cdoR::cdo_exe, args = c("-addc,1","-mulc,-0.01", dt[['sftlf']], PercentOcean_nc), stdout = TRUE, stderr = TRUE)
    #multiplies land percentage by area cells
    system2(cdoR::cdo_exe, args = c("-mul", dt[['areacella']], PercentOcean_nc, OceanArea_nc), stdout = TRUE, stderr = TRUE)

    #makes sure that new files were created
    assertthat::assert_that(file.exists(OceanArea_nc))
    OceanArea_nc

}

#creates function fldmean_area
fldmean_area <- function(info, in_nc, area_nc, area_var = 'areacella', showMessages = FALSE){

    #checks input data
    assertthat::assert_that(file.exists(area_nc))
    assertthat::assert_that(file.exists(in_nc))

    #extacts data from in_nc
    if(showMessages) message('extracting time')
    nc <- ncdf4::nc_open(in_nc)
    time <- format_time(nc)
    data <- ncdf4::ncvar_get(nc, info$variable)

    #extracts area data from area_nc
    area <- ncdf4::ncvar_get(ncdf4::nc_open(area_nc), area_var)
    
    #calculates weighted mean for each time step using the area map as the weighted mean
    mean <- apply(data, 3, weighted.mean, w = area, na.rm = TRUE)

    #combines all of the mean data into one vector
    cbind(time,
          value = mean,
          units = ncdf4::ncatt_get(nc, info$variable)$unit,
          info,
          stringsAsFactors = FALSE)

}

# applies long function specified within {} to the tas_meta rows
apply(tas_meta, 1, function(x){

    #organizes the data into catagories
    input <- tibble(file = x[["file"]],
                    type = x[["type"]],
                    variable = x[["variable"]],
                    domain = x[["domain"]],
                    model = x[["model"]],
                    experiment = x[["experiment"]],
                    ensemble = x[["ensemble"]],
                    grid = x[["grid"]],
                    time = x[["time"]],
                    areacella = x[["areacella"]],
                    sftlf = x[["sftlf"]])

    land_nc <- cdo_land_area(input, inter_dir)
    ocean_nc <- cdo_ocean_area(input, inter_dir)

    #adds new data to input file
    input$land_nc <- land_nc
    input$ocean_nc <- ocean_nc

    return(input)
}) %>%
    bind_rows() ->
    area_data

to_process <- dplyr::inner_join(tas_meta, area_data)

apply(to_process, 1, function(x){


    input <- tibble::tibble(file = x[["file"]],
                            type = x[["type"]],
                            variable = x[["variable"]],
                            domain = x[["domain"]],
                            model = x[["model"]],
                            experiment = x[["experiment"]],
                            ensemble = x[["ensemble"]],
                            grid = x[["grid"]],
                            time = x[["time"]],
                            areacella = x[["areacella"]],
                            land_nc = x[['land_nc']],
                            ocean_nc = x[['ocean_nc']])

    info <- parse_cmip_info(input)
    base_name <- paste0(paste(info, collapse = '_'), x[['time']])


    #makes the weighted mean of the variable that we are trying to figure out using the weighted
    #land/ocean map that we created above
    land_mean  <- fldmean_area(info = info, in_nc = input[['file']], area_nc = input[['land_nc']])
    ocean_mean <- fldmean_area(info, in_nc = input[['file']], area_nc = input[['ocean_nc']])
    globe_mean <- fldmean_area(info, in_nc = input[['file']], area_nc = input[['areacella']])

    #saves all of the data we just calculated
    out <- dplyr::select(land_mean, -value)
    out$land <- land_mean$value
    out$ocean <- ocean_mean$value
    out$globe <- globe_mean$value

    #writes all of the data to a file
    write.csv(out, file = file.path(out_dir, paste0(base_name, '-fldMean.csv')), row.names = FALSE)
})



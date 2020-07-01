

cmip6_archive <- read.csv(file = '/pic/projects/GCAM/CMIP6/cmip6_archive_index.csv', stringsAsFactors = FALSE)

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


tas_meta <- dplyr::inner_join(tas_data, meta_data, by = c("model", "experiment", "ensemble", "grid"))



cdo_land_area <- function(dt, intermed_dir){

    # Check the inputs
    assertthat::assert_that(all(c('areacella', 'sftlf') %in% names(dt)))
    info <- parse_cmip_info(dt, not_required = 'variable')
    basename <- paste(info, collapse = '_')
    PercentLand_nc <- file.path(intermed_dir, paste0(basename, '_PercentLand.nc'))
    LandArea_nc    <- file.path(intermed_dir, paste0(basename, '_LandArea.nc'))

    system2(cdoR::cdo_exe, args = c("-divc,100", dt[['sftlf']], PercentLand_nc), stdout = TRUE, stderr = TRUE)
    system2(cdoR::cdo_exe, args = c("-mul", dt[['areacella']], PercentLand_nc, LandArea_nc), stdout = TRUE, stderr = TRUE)

    assertthat::assert_that(file.exists(LandArea_nc))
    LandArea_nc

}



cdo_yearmonmean <- function(name, in_nc, intermed_dir){

    assertthat::assert_that(file.exists(in_nc))
    assertthat::assert_that(dir.exists(intermed_dir))
    out_nc      <- file.path(intermed_dir, paste0(name, '-yearmonmean.nc'))
    if(file.exists(out_nc)) file.remove(out_nc)

    system2(cdoR::cdo_exe, args = c('yearmonmean', in_nc, out_nc), stdout = TRUE, stderr = TRUE)

    assertthat::assert_that(file.exists(out_nc))
    out_nc
}


cdo_ocean_area <- function(dt, intermed_dir){

    # Check the inputs
    assertthat::assert_that(all(c('areacella', 'sftlf') %in% names(dt)))
    info <- parse_cmip_info(dt, not_required = 'variable')
    basename <- paste(info, collapse = '_')
    PercentOcean_nc <- file.path(intermed_dir, paste0(basename, '_PercentOcean.nc'))
    OceanArea_nc    <- file.path(intermed_dir, paste0(basename, '_OceanArea.nc'))

    system2(cdoR::cdo_exe, args = c("-addc,1","-mulc,-0.01", dt[['sftlf']], PercentOcean_nc), stdout = TRUE, stderr = TRUE)
    system2(cdoR::cdo_exe, args = c("-mul", dt[['areacella']], PercentOcean_nc, OceanArea_nc), stdout = TRUE, stderr = TRUE)

    assertthat::assert_that(file.exists(OceanArea_nc))
    OceanArea_nc

}


fldmean_area <- function(info, in_nc, area_nc, area_var = 'areacella', showMessages = FALSE){

    assertthat::assert_that(file.exists(area_nc))
    assertthat::assert_that(file.exists(in_nc))

    if(showMessages) message('extracting time')
    nc <- ncdf4::nc_open(in_nc)
    time <- format_time(nc)
    data <- ncdf4::ncvar_get(nc, info$variable)

    area <- ncdf4::ncvar_get(ncdf4::nc_open(area_nc), area_var)

    mean <- apply(data, 3, weighted.mean, w = area, na.rm = TRUE)

    cbind(time,
          value = mean,
          units = ncdf4::ncatt_get(nc, info$variable)$unit,
          info,
          stringsAsFactors = FALSE)

}














apply(tas_meta, 1, function(x){

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



    land_mean  <- fldmean_area(info = info, in_nc = input[['file']], area_nc = input[['land_nc']])
    ocean_mean <- fldmean_area(info, in_nc = input[['file']], area_nc = input[['ocean_nc']])
    globe_mean <- fldmean_area(info, in_nc = input[['file']], area_nc = input[['areacella']])


    out <- dplyr::select(land_mean, -value)
    out$land <- land_mean$value
    out$ocean <- ocean_mean$value
    out$globe <- globe_mean$value


    write.csv(out, file = file.path(out_dir, paste0(base_name, '-fldMean.csv')), row.names = FALSE)
})



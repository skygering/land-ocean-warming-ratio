library(ggplot2)
path_name = '/Users/skylargering/land-ocean-warming-ratio'
ratio_file_name = 'ratio_cleaned_1pctCO2_temp.csv'
rcp45 <- system.file("input", "hector_rcp45.ini", package = "hector")
rcp85 <- system.file("input", "hector_rcp85.ini", package = "hector")
numRuns = 500


run_with_param <- function(core, parameter, value) {
    old_value <- fetchvars(core, NA, parameter)
    unit <- as.character(old_value[["units"]])
    setvar(core, NA, parameter, value, unit)
    reset(core)
    run(core)
    result <- fetchvars(core, 1850:2300)
    result[["parameter_value"]] <- value
    result
}

#' Run Hector with a range of parameter values
run_with_param_range <- function(core, parameter, values) {
    mapped <- Map(function(x) run_with_param(core, parameter, x), values)
    Reduce(rbind, mapped)
}

### MAIN ###

ratio_data <- read.csv(file = file.path(path_name, ratio_file_name), stringsAsFactors = FALSE)
mean <- mean(ratio_data$Ratio)
sd <- sd(ratio_data$Ratio)
ran_dist <- c(rnorm(numRuns, mean, sd), 1.0)

core <- newcore(rcp45, suppresslogging = TRUE)
range_lo_warming_ratio <- run_with_param_range(core, LO_WARMING_RATIO(), ran_dist)

ggplot(range_lo_warming_ratio) +
    aes(x = year, y = value, color = parameter_value, group = parameter_value) +
    geom_line() +
    facet_wrap(~variable, scales = "free_y") +
    guides(color = guide_colorbar(title = expression("Land-Ocean Warming Ratio"))) +
    scale_color_viridis_c()

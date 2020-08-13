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

####### GRAPHS I MIGHT NEED ##########

# Hector Downstream Change graph
downstream_df <- filter(final_df, key == 'Emergent Ratio with Downstream Changes')

ggplot(downstream_df) + geom_hline(yintercept = 0, linetype = 'dashed') +
    geom_line(aes(x=year, y=value, color = key)) + facet_grid(val_unit ~ run_name, scales =  "free_y") +
    ggtitle('Effects of Downstream Changes on Hector Results \n for 4 Warming Scenarios') +
    theme(legend.position="bottom",
          axis.text.x = element_text(angle = 45, vjust = 1.0, hjust = 1.0),
          legend.title=element_blank(),
          plot.title = element_text(hjust = 0.5))


# Hector Emergent Ratio

emergent_lo_warming_ratio <- function(core, scenario){
    reset(core)
    run(core)
    Tland <- fetchvars(core, 1850:2300, LAND_AIR_TEMP())
    Tocean <- fetchvars(core, 1850:2300, OCEAN_AIR_TEMP())
    warming_ratio <- data.frame(Year = Tland$year, Ratio = Tland$value/Tocean$value, Scenario = scenario)
    warming_ratio
}

core26 <-  newcore(rcp26, suppresslogging = TRUE)
core45 <- newcore(rcp45, suppresslogging = TRUE)
core60 <- newcore(rcp60, suppresslogging = TRUE)
core85 <- newcore(rcp85, suppresslogging = TRUE)

ratio26 <- emergent_lo_warming_ratio(core26, 'rcp26')
ratio45 <- emergent_lo_warming_ratio(core45, 'rcp45')
ratio60 <- emergent_lo_warming_ratio(core60, 'rcp60')
ratio85 <- emergent_lo_warming_ratio(core85, 'rcp85')

all_ratios <- data.frame(Year = integer(), Ratio = double(), Scenario = character())
all_ratios <- bindDataFrames(all_ratios, list(ratio26, ratio45, ratio60, ratio85))
all_ratios_clean <- all_ratios[all_ratios$Ratio > 1 & all_ratios$Ratio < 2.5 & all_ratios$Year > 2000, ]
ggplot(all_ratios_clean) + aes(x = Year, y = Ratio) + geom_line(aes(color = Scenario)) + ggtitle(" Hector Emergent Warming Ratio") + theme(plot.title = element_text(hjust = 0.5))

median(all_ratios_clean$Ratio)
median(filter(all_ratios_clean, Scenario == 'rcp26')$Ratio)
median(filter(all_ratios_clean, Scenario == 'rcp45')$Ratio)
median(filter(all_ratios_clean, Scenario == 'rcp60')$Ratio)
median(filter(all_ratios_clean, Scenario == 'rcp85')$Ratio)




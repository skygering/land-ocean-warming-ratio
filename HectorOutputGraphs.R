library(dplyr)
library(tidyr)
library(plyr)
library(ggplot2)



getData <- function(data, var){
  data %>% filter(variable == var & spinup == 0) %>% subset(select = -c(component, variable, spinup, units))
}

makeDataFrame <- function(data, data_name){
  data.frame(Run = data$run_name, Data = data$value, Year = data$year, Type = data_name)
}

bindFrames <- function(df_list, final_df){
  for(df in df_list){
    final_df <- rbind.fill(final_df, df)
  }
  final_df
}

theme_set(theme_minimal())

path_name<-'/Users/skylargering/Desktop/Hector\ Output'
RCPs<- c('rcp26', 'rcp45', 'rcp60', 'rcp85')

ca_df <- data.frame(Run = character(), Data = double(), Year = integer(), Type = character())
temp_df <- data.frame(Run = character(), Data = double(), Year = integer(), Type = character())
atmos_co2_df <- data.frame(Run = character(), Data = double(), Year = integer(), Type = character())


for(rcp in RCPs){
  rcp_data_path<-file.path(path_name, rcp)
  og<-read.csv(file = file.path(rcp_data_path, paste0('master_outputstream_', rcp, '.csv')), skip=1, stringsAsFactors = FALSE)
  updated<-read.csv(file = file.path(rcp_data_path, paste0('emergent_outputstream_', rcp, '.csv')), skip=1, stringsAsFactors = FALSE)
  downstream<-read.csv(file = file.path(rcp_data_path, paste0('constrain_outputstream_', rcp, '.csv')), skip=1,stringsAsFactors = FALSE)
  
  og_ca <- getData(og, 'Ca')
  updated_ca <- getData(updated, 'Ca')
  downsteam_ca <- getData(downstream, 'Ca')
  
  og_temp <- getData(og, 'Tgav')
  updated_temp <- getData(updated, 'Tgav')
  downstream_temp <- getData(downstream, 'Tgav')
  
  og_atmos_c <- getData(og, 'atmos_c')
  updated_atmos_c <- getData(updated, 'atmos_c')
  downstream_atmos_c <- getData(downstream, 'atmos_c')
  
  og_temp_df <- makeDataFrame(og_temp, 'Emergent ratio - No downstream changes')
  updated_temp_df <- makeDataFrame(updated_temp, 'Emergent Ratio - Downstream changes')
  downstream_temp_df <- makeDataFrame(downstream_temp, 'Ratio = 1.591 - downstream changes')
  
  og_ca_df <- makeDataFrame(og_ca, 'Emergent ratio - No downstream changes')
  updated_ca_df <- makeDataFrame(updated_ca, 'Emergent Ratio - Downstream changes')
  downstream_ca_df <- makeDataFrame(downsteam_ca,'Ratio = 1.591 - downstream changes')
  
  og_atmos_df <- makeDataFrame(og_atmos_c,'Emergent ratio - No downstream changes')
  updated_atmos_df <- makeDataFrame(updated_atmos_c, 'Emergent Ratio - Downstream changes')
  downstream_atmos_df <- makeDataFrame(downstream_atmos_c, 'Ratio = 1.591 - downstream changes')
  
  ca_df <- bindFrames(list(og_ca_df, updated_ca_df, downstream_ca_df), ca_df)
  temp_df <- bindFrames(list(og_temp_df, updated_temp_df, downstream_temp_df), temp_df)
  atmos_co2_df <- bindFrames(list(og_atmos_df, updated_atmos_df, downstream_atmos_df), atmos_co2_df)
}


ggplot(temp_df, aes(x=Year, y=Data)) + geom_line(aes(color = Type)) + facet_wrap(vars(Run)) + ggtitle("Annual Temperature")

ggplot(ca_df, aes(x=Year, y=Data)) + geom_line(aes(color = Type)) + facet_wrap(vars(Run)) + ggtitle("Annual CO2")

ggplot(atmos_co2_df, aes(x=Year, y=Data) + geom_line(aes(color = Type)) + facet_wrap(vars(Run)) + ggtitle("Annual Atmopsheric Carbon")






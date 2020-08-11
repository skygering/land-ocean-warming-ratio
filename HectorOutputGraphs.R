library(dplyr)
library(tidyr)
library(plyr)
library(ggplot2)
library(tidyverse)



cleanData <- function(full_data, var){
  var_df <- data.frame(year = integer(), run_name = character(), variable = character(), value = double(), units = character(), type = character(), title = character())
  for(i in 1:length(full_data)){
    data <- full_data[[i]]
    data %>% filter(variable == var & spinup == 0) %>% subset(select = -c(component, spinup)) %>% unite(title, c(variable, units), sep = "-", remove = TRUE) -> data
    var_df <- rbind(var_df, data)
  }
  var_df
}

bindDataFrames <- function(final_df, frames_to_bind){
  for(frame in frames_to_bind){
    final_df <- rbind(final_df, frame)
  }
  final_df
}



theme_set(theme_minimal())

path_name<-'/Users/skylargering/Desktop/Hector\ Output'
RCPs<- c('rcp26', 'rcp45', 'rcp60', 'rcp85')

all_df <- data.frame(year = integer(), run_name = character(), variable = character(), variable = character(), value = double(), units = character(), type = character(), title = character())
#ca_df <- data.frame(year = integer(), run_name = character(), variable = character(), value = double(), units = character(), type = character(), title = character())
#temp_df <- data.frame(year = integer(), run_name = character(), variable = character(), value = double(), units = character(), type = character(), title = character())
#fco2_df <-  data.frame(year = integer(), run_name = character(), variable = character(), value = double(), units = character(), type = character(), title = character())
#ftot_df <-  data.frame(year = integer(), run_name = character(), variable = character(), value = double(), units = character(), type = character(), title = character())

for(rcp in RCPs){
  rcp_data_path<-file.path(path_name, rcp)
  read.csv(file = file.path(rcp_data_path, paste0('master_outputstream_', rcp, '.csv')), skip=1, stringsAsFactors = FALSE) %>%
      cbind(data.frame(type = 'No Downstream Changes - Emergent Ratio')) -> master
  read.csv(file = file.path(rcp_data_path, paste0('emergent_outputstream_', rcp, '.csv')), skip=1, stringsAsFactors = FALSE) %>%
      cbind(data.frame(type = 'Downstream Changes - Emergent Ratio')) -> downstream_emergent
  read.csv(file = file.path(rcp_data_path, paste0('constrain_outputstream_', rcp, '.csv')), skip=1,stringsAsFactors = FALSE) %>%
      cbind(data.frame(type = 'Downstream Changes - Ratio = 1.591')) -> downstream_constrained

  all_data <- list(master, downstream_emergent, downstream_constrained)
  ca_data <- cleanData(all_data, 'Ca')
  tgav_data <- cleanData(all_data, 'Tgav')
  fco2_data <- cleanData(all_data, 'FCO2')
  ftot_data <- cleanData(all_data, 'Ftot')

  #ca_df <- rbind(ca_df, ca_data)
  #temp_df <- rbind(temp_df, tgav_data)
  #fco2_df <- rbind(fco2_df, fco2_data)
  #ftot_df <- rbind(ftot_df, ftot_data)
  all_df <- bindDataFrames(all_df, list(ca_data, tgav_data, fco2_data, ftot_data))
}

all_df$type <- factor(all_df$type, c('No Downstream Changes - Emergent Ratio', 'Downstream Changes - Emergent Ratio',
                                     'Downstream Changes - Ratio = 1.591'))

ggplot(all_df, aes(x=year, y=value)) + geom_line(aes(color = type)) + facet_grid(title ~ run_name, scales =  "free_y") +
  ggtitle('Effects of Downstream Changes and Warming Ratio on Hector Results for 4 Warming Scenarios',
          subtitle = expression('Effects on Ambient CO'[2]*' Concentration (Ca),
                                Forcing due to CO'[2]*' (FCO2), Total Forcing (Ftot), and Average Global Temperature (Tgav)'))+
theme(legend.position="bottom",
      axis.text.x = element_text(angle = 45, vjust = 1.0, hjust = 1.0),
      legend.title=element_blank(),
      plot.title = element_text(hjust = 0.5))


#ggplot(temp_df, aes(x=year, y=value)) + geom_line(aes(color = type)) + facet_wrap(vars(run_name)) + ggtitle('Global Average Temperature')

#ggplot(ca_df, aes(x=year, y=value)) + geom_line(aes(color = type)) + facet_wrap(vars(run_name)) + ggtitle(expression('Ambient CO'[2]*' Concentration'))

#ggplot(fco2_df, aes(x=year, y=value))+ geom_line(aes(color = type)) + facet_wrap(vars(run_name)) + ggtitle(expression('Forcing due to CO'[2]*''))

#ggplot(atmos_df, aes(x=year, y=value))+ geom_line(aes(color = type)) + facet_wrap(vars(run_name)) + ggtitle('Total Forcing')






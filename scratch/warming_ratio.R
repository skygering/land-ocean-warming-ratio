#SHOULD I PUT THIS IN THE SAME FILE AS TEMP CALCULATIONS (average_temp_cdo.R?)

# get_warming_constant:
# calculates the land-ocean warming constant for each timestep from the first temperature listed in land and ocean respectivly (historical data)
# inputs: 
#     land_temp: .nc file location with annual average temperature weighted by percent of grid that is land
#     ocean_temp:.nc file location with annual average temperature weighted by percent of grid that is ocean
#     land_warming: .nc file location that will hold land warming over each timestep
#     ocean_warming: .nc file location that will hold the ocean warming over each timestep
#     ratio: .nc file location that will hold land-ocean warming constant for each timestep
#output: 
#     land_warming.nc, ocean_warming.nc, and ratio.nc as specified above - saved at path_name

get_warming_constant = function(land_temp, ocean_temp, land_warming, ocean_warming, ratio){
  nc_open(land_temp) %>% ncvar_get("tas") -> land
  nc_open(ocean_temp) %>% ncvar_get("tas") -> ocean
  land_base <- land[1]
  ocean_base <- ocean[1]
  
  land_warming <- land - land_base
  ocean_warming <- ocean - ocean_base
  warming_ratio <- land_warming/ocean_warming
}



#getting variables
nc_open(land_temp) %>% ncvar_get("tas") -> land_tas
nc_open(ocean_temp) %>% ncvar_get("tas") -> ocean_tas
nc_open(global_temp) %>% ncvar_get("tas") -> global_tas

nc_open(land_temp) %>% ncvar_get("time") %>% as.Date('1850-01-01') -> time

#make data frame (same code as above in R section)
temp_frame <- data.frame(Data = rep(c("Land", "Ocean", "Global"), each = dim(time)),
                         Time = rep(time, 3),
                         Temp = c(land_tas, ocean_tas, global_tas))

#graphing
ggplot(temp_frame, aes(x = Time, y = Temp, group = Data)) + geom_line(aes(linetype=Data, color=Data))+
  ggtitle("Average Surface Temperature") + 
  theme(plot.title = element_text(hjust = 0.5)) + xlab("Time (year)") + ylab("Temp (K)") 



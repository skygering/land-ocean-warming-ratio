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
  land_base <- land[1] *-1
  ocean_base <- ocean[1] *-1
  
  #It doesn't like that I am adding variables..... might need to do in R?
  #Not 3D data anymore -> since 2D use R
  #extract and save as a csv file
  system2(cdo_path, args = c('addc,', land_base, land_temp, land_warming))
  system2(cdo_path, args = c('addc,', ocean_base, ocean_temp, ocean_warming))
  system2(cdo_path, args = c('div', land_warming, ocean_warming, ratio))
}

#land_warming <- file.path(path_name, 'land_warming.nc')
#ocean_warming <- file.path(path_name, 'ocean_warming.nc')
#ratio <- file.path(path_name, 'ratio.nc')

#get_warming_constant(land_temp, ocean_temp, land_warming, ocean_warming, ratio)
#Using R with netcdf files

library(ncdf4)
library(ggplot2)

#open the document
f = nc_open("Documents/learning_r/tas_annual_ipsl-cm5a-lr_rcp8p5_xxx_2006-2099.nc")

#see what is in the doc
print(f)

lat = ncvar_get(f, "lat")
lon = ncvar_get(f, "lon")
tm = ncvar_get(f, "time")
tas = ncvar_get(f, "tas")
dtm = ncvar_get(f, "time_bnds")

#details on lat, lon, time, and tas
ncatt_get(f, "lat")
ncatt_get(f, "lon")
ncatt_get(f, "time")
ncatt_get(f, "time_bnds")


#dimensions of longitude, latitude, and time respectively
dim(tas)

#total number of data points for surface temperature
toString(length(tas))

#the file is class
class(f)

#the other variables are class
class(lat)
class(lon)
class(tm)
class(tas)


#getting the mean temp over time - unweighted
uw_mean_tas<- apply(tas, 3, function(x) mean(x, na.rm = TRUE)) #I used apply bc it let me split

#making data into a data frame and plotting
uw_mean_tas_df <- data.frame(time = tm, value = uw_mean_tas)
ggplot(uw_mean_tas_df, aes(time, value)) + geom_point() + 
  ggtitle("Unweighted Annual Average Surface Temperature") + theme(plot.title = element_text(hjust = 0.5))


#loading weighted data from CDO
w_mean_tas = nc_open("Documents/learning_r/tas_annual_mean.nc")
tm_w = ncvar_get(w_mean_tas, "time")
tas_w = ncvar_get(w_mean_tas, "tas")


#Make data frame and plot
w_mean_tas <- data.frame(time = tm_w, value = tas_w)
ggplot(w_mean_tas, aes(time, value)) + geom_point() +
  ggtitle("Weighted Annual Average Surface Temperature") + theme(plot.title = element_text(hjust = 0.5))

#Needs to be an array so it can be compared to w_tas
uw_mean_tas_arr <- array(uw_mean_tas, dim = 94) #w_tas has dimension of 94

identical(uw_mean_tas_arr, tas_w) #returns FASLE
all.equal(uw_mean_tas_arr, tas_w)

tm <- round(tm/10000)
tm_w <- round(tm_w/10000)

#making the lines on the same graph
df2 <- data.frame(Data = rep(c("Weighted", "Unweighted"), each=94), 
                  Time = c(tm_w, tm), 
                  Temp = c(tas_w, uw_mean_tas))

ggplot(df2, aes(x = Time, y = Temp, group = Data)) + geom_line(aes(linetype=Data, color=Data))+
  geom_point(aes(shape=Data, color=Data)) + ggtitle("Annual Average Surface Temperature Over Land") + 
  theme(plot.title = element_text(hjust = 0.5)) + xlab("Time (year)") + ylab("Temp (K)")

#calling CDO using R
cdo_path = '../../usr/local/Cellar/cdo/1.9.8/bin/cdo'
input_file <- 'Documents/land-ocean-warming-ratio/scratch/tas_annual_ipsl-cm5a-lr_rcp8p5_xxx_2006-2099.nc'
output_file <- 'Documents/land-ocean-warming-ratio/scratch/r_tas_annual_mean.nc'
system(paste(cdo_path, ' fldmean ', input_file, " ", output_file, sep = ""))


r_w_mean_tas <- nc_open(output_file)
r_tm_w = ncvar_get(r_w_mean_tas, "time")
r_tas_w = ncvar_get(r_w_mean_tas, "tas")

#checking if this is the same as when I called it in terminal
identical(r_tas_w, tas_w) #returns TRUE
all.equal(r_tas_w, tas_w) #returns TRUE

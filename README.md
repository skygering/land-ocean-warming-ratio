# land-ocean-warming-ratio
Code to parameterize the land-ocean warming ration within the HECTOR simple climate model using CMIP6 data.

avg_temp_script.R and average_temp_cdo.R can be used calculate the annual average land, ocean, and global average annual temperature from historical CMIP6 data. In order to analyize the data using these scripts, a model must have tas, areacalla, and sftlf data. The scripts will help identify usable models given proper data organization. These two scripts were can using avg_temp_job.txt on PNNL's super comptuer PIC. The path_name and cdo_path variables at the top of avg_temp_script.R will need to be adapted to the local machine, as well as the code to identify the file placement of the temperature and area data as these are specific to the file system and organization of PIC. 

The above files will output a .csv file with the average annual land, ocean, and global temperature for each model organized as well as a folder for each model that will hold a .csv for the model's data as well as intermediate filed if the cleanup variable is false.

The data can then be ran through cleaning_temp_data.R (again need to change global variables to fit your local machine and data) to get an updated .csv file with the cleaned data without any outliers from bad data. This data can now be used for further investigations. 

# land-ocean-warming-ratio
Code to parameterize the land-ocean warming ration within the HECTOR simple climate model using CMIP6 data.

All of the code and data outputs referenced in this paper can be found within this repository and the Hector code can be found at <https://github.com/JGCRI/hector>.

`avg_temp_script.R` and `average_temp_cdo.R` can be used calculate the annual average land, ocean, and global temperatures from CMIP6 data. In order to analyze the data using these scripts, a model must have `tas`, `areacalla`, and `sftlf` data.  `avg_temp_script.R` identifies usable models depending on the parameters input and given proper data organization and then `average_temp_cdo.R` will use CDO commands to analyze the data. These two scripts can be run using `sbatch avg_temp_job.txt` on PNNL's super computer PIC. The `cdo_path` variable at the top of `avg_temp_script.R` will need to be adapted to the local machine, as well as the code to identify the file placement of the temperature and area data as these are specific to the file system and organization of PIC. The `path_name` variable should be set to the top level of the project.

The above files will output a CSV file with the average annual land, ocean, and global temperature for each model, as well as a folder for each model that will hold a CSV of the model's data as well as intermediate files if the `cleanup` variable is set to false.

The data can then be run through `cleaning_temp_data.R` (again need to change global variables to fit your local machine and data) to get an updated CSV file with the cleaned data. This data can now be used for further investigations.

The cleaned data can then be run through the script `warming_ratio.R`, which will output a CSV file containing the warming ratio for each model. Once the above data has been created (all three of the CSV file outputs mentioned above are also saved in this repository), the .Rmd file can be run to analyze the data and the create graphs of major trends. 

The .Rmd file will require use of the Hector Package. If my work has been merged to the Hector master branch, this will simply be the normal Hector package. If not, the package will need to be built using the code from the branch `land_ocean_warming_ratio` in the Hector repository.


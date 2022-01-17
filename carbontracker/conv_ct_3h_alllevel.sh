#!/bin/bash
### convert carbontracker data into 1 ,0.25 or 0.1 degree
### run : bash conv_ct_3h_alllevel.sh 
### zhendong.wu@nateko.lu.se

HOME_PATH=$(cd .. && pwd)
SCRIPT_PATH=$HOME_PATH/script
IN_PATH=$HOME_PATH/CTE2020
CO2_PATH=${HOME_PATH}/CTE2020co2
GPH_PATH=${HOME_PATH}/CTE2020gph
OUT_PATH=${HOME_PATH}

GRIDFILE_100=$SCRIPT_PATH/mygrid_100deg.txt

mkdir -p $CO2_PATH
mkdir -p $GPH_PATH

cd $IN_PATH

for file in 3d_molefractions_*.nc
do
    echo $file
    day=$(echo $file | cut -d _ -f 4 )
    # co2
    cdo -O remapcon,${GRIDFILE_100} -selvar,co2 $file tempfile_CO2.nc
        # mol mol-1 to ppm
    cdo -z zip_6 -O expr,'co2=co2*1000000' tempfile_CO2.nc ${CO2_PATH}/CO2_${day}_3h.nc
    ncatted -a units,co2,o,c,"ppm" ${CO2_PATH}/CO2_${day}_3h.nc
    # gph, geopotential_height
    # geopotential_height_at_level_boundaries
    cdo -z zip_6 -O remapcon,${GRIDFILE_100} -selvar,gph $file ${GPH_PATH}/gph_${day}_3h.nc
done

# fix the first day, and interpolate into hourly

YEAR=2019

cd $CO2_PATH
PREFIX=CT_CO2
cdo -z zip_6 -O shifttime,-1day CO2_20190101_3h.nc CO2_20181231_3h.nc
cdo -z zip_6 -O mergetime CO2_*_3h.nc tempfile_merge.nc
cdo -z zip_6 -O setreftime,2019-01-01,00:00:00,hours -selyear,${YEAR} -inttime,$((YEAR-1))-12-31,1:30:00,1hour tempfile_merge.nc conv_${PREFIX}_global_1deg_${YEAR}.nc
cdo -z zip_6 -O selmonth,1/6 conv_${PREFIX}_global_1deg_${YEAR}.nc conv_${PREFIX}_global_1deg_${YEAR}_firsthalf.nc

cd $GPH_PATH
PREFIX=CT_gph
cdo -z zip_6 -O shifttime,-1day gph_20190101_3h.nc gph_20181231_3h.nc
cdo -z zip_6 -O mergetime gph_*_3h.nc tempfile_merge.nc
cdo -z zip_6 -O setreftime,2019-01-01,00:00:00,hours -selyear,${YEAR} -inttime,$((YEAR-1))-12-31,1:30:00,1hour tempfile_merge.nc conv_${PREFIX}_global_1deg_${YEAR}.nc
cdo -z zip_6 -O selmonth,1/6 conv_${PREFIX}_global_1deg_${YEAR}.nc conv_${PREFIX}_global_1deg_${YEAR}_firsthalf.nc

# ----------------------------- test --------------------------------

# interpolate time
# PREFIX=CT_CO2_alllv
# YEAR=2019
# cdo -O shifttime,-1day CO2_20190101_3h.nc CO2_20181231_3h.nc
# cdo -O mergetime CO2_20190101_3h.nc CO2_20181231_3h.nc tempfile_merge.nc
# cdo -O inttime,2018-12-31,22:30:00,1hour tempfile_merge.nc int.nc
# 
# cdo -O setreftime,2019-01-01,00:00:00,hours -selyear,${YEAR} -settaxis,$((YEAR-1))-12-15,00:00:00,1hour -inttime,$((YEAR-1))-12-17,00:00:00,1hour tempfile_merge.nc tempfile_100_${YEAR}.nc
# 
# cdo -z zip_6 -f nc4c -O mergetime tempfile_100_*.nc conv_${PREFIX}_global_1deg_2019_fake.nc
# 
# cdo -z zip_6 -O selmonth,1/6 conv_${PREFIX}_global_1deg_2019_fake.nc conv_${PREFIX}_global_1deg_2019_firsthalf_fake.nc
# 
# PREFIX=CT_gph_alllv
# YEAR=2019
# cdo -O shifttime,-1year -selmon,12 gph_2019_monthly_fake.nc tempfile_mon12.nc
# cdo -O shifttime,1year -selmon,1 gph_2019_monthly_fake.nc tempfile_mon1.nc
# cdo -O mergetime tempfile_mon1.nc gph_2019_monthly_fake.nc tempfile_mon12.nc tempfile_merge.nc
# cdo -O setreftime,2019-01-01,00:00:00,hours -selyear,${YEAR} -settaxis,$((YEAR-1))-12-15,00:00:00,1hour -inttime,$((YEAR-1))-12-17,00:00:00,1hour tempfile_merge.nc tempfile_100_${YEAR}.nc
# 
# cdo -z zip_6 -f nc4c -O mergetime tempfile_100_*.nc conv_${PREFIX}_global_1deg_2019_fake.nc
# 
# 
# cdo -z zip_6 -O selmonth,1/6 conv_${PREFIX}_global_1deg_2019_fake.nc conv_${PREFIX}_global_1deg_2019_firsthalf_fake.nc
# 


# cdo mergetime *.nc ${OUTPUT_DIR}/CT2018_2000_2017_monthly.nc
# cdo selvar,co2 ${OUTPUT_DIR}/CT2018_2000_2017_monthly.nc ${OUTPUT_DIR}/CT2018_co2_2000_2017_monthly.nc
# cdo sellevel,1 ${OUTPUT_DIR}/CT2018_co2_2000_2017_monthly.nc ${OUTPUT_DIR}/CT2018_co2_2000_2017_monthly_level1.nc





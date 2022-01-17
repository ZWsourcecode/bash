#!/bin/bash
### convert carbontracker data into 1 ,0.25 or 0.1 degree
### run : bash conv_ct_3h_cams.sh 
### zhendong.wu@nateko.lu.se

HOME_PATH=$(cd .. && pwd)
SCRIPT_PATH=$HOME_PATH/script
IN_PATH=$HOME_PATH/raw
CO2_PATH=${HOME_PATH}/CAMSco2
HARE_PATH=${HOME_PATH}/CAMShare
OUT_PATH=${HOME_PATH}

GRIDFILE_100=$SCRIPT_PATH/mygrid_100deg.txt

mkdir -p $CO2_PATH
mkdir -p $HARE_PATH

cd $IN_PATH

for file in cams73_latest_*2020*.nc
do
    echo $file
    day=$(echo $file | cut -d _ -f 7 | cut -d . -f 1)
    # co2
    cdo -O -f nc4c -P 4 remapcon,${GRIDFILE_100} -selvar,CO2 $file tempfile_CO2.nc
    # mol mol-1 to ppm
    cdo -z zip_6 -O expr,'CO2=CO2*1000000' tempfile_CO2.nc ${CO2_PATH}/CO2_${day}_3h.nc
    ncatted -a units,CO2,o,c,"ppm" ${CO2_PATH}/CO2_${day}_3h.nc
    # height_above_reference_ellipsoid
    # Altitude of layer interfaces above the reference ellipsoid
    cdo -O -f nc4c -P 4 remapcon,${GRIDFILE_100} -selvar,height_above_reference_ellipsoid $file ${HARE_PATH}/hare_${day}_3h.nc
done

# fix the first day, and interpolate into hourly


YEARSTART=2018
YEAREND=2020
for YEAR in $(seq $YEARSTART $YEAREND)
do
    echo ================== $YEAR is processing ==================
    PREFIX=CAMS_CO2
    cd $CO2_PATH
    
    cdo -z zip_6 -O mergetime CO2_$((YEAR-1))11_3h.nc CO2_$((YEAR-1))12_3h.nc CO2_${YEAR}*_3h.nc tempfile_merge.nc
    cdo -z zip_6 -O setreftime,${YEAR}-01-01,00:00:00,hours -seldate,$((YEAR-1))-12-01T00:00:00,$((YEAR+1))-01-01T00:00:00 -inttime,$((YEAR-1))-11-30,1:30:00,1hour tempfile_merge.nc conv_${PREFIX}_global_1deg_${YEAR}_$((YEAR-1))12.nc

    rm tempfile_*.nc
    
    PREFIX=CAMS_hare
    cd $HARE_PATH
    cdo -O ensmean hare_${YEAR}*.nc conv_${PREFIX}_global_1deg_${YEAR}avg.nc
done

# ----------------------------- test --------------------------------

#     cdo -z zip_6 -O mergetime conv_${PREFIX}_global_1deg_$((YEAR-1))_dec.nc conv_${PREFIX}_global_1deg_${YEAR}.nc conv_${PREFIX}_global_1deg_${YEAR}_$((YEAR-1))12.nc

    
#     # interpolate december 
#     cdo -O mergetime CO2_${YEAR}1*_3h.nc tempfile_merge.nc
#     cdo -O selmonth,11/12 tempfile_merge.nc tempfile_merge_${YEAR}_1112.nc
#     cdo -z zip_6 -O setreftime,${YEAR}-01-01,00:00:00,hours -selmonth,12 -inttime,${YEAR}-11-30,1:30:00,1hour tempfile_merge_${YEAR}_1112.nc conv_${PREFIX}_global_1deg_${YEAR}_dec.nc
#         
#     if (($YEAR > $YEARSTART )); then
#         # interplate whole year, and mergetime with last december
#         cdo -z zip_6 -O mergetime CO2_$((YEAR-1))12_3h.nc CO2_${YEAR}*_3h.nc tempfile_merge.nc
#         cdo -z zip_6 -O setreftime,${YEAR}-01-01,00:00:00,hours -selyear,${YEAR} -inttime,$((YEAR-1))-12-31,1:30:00,1hour tempfile_merge.nc conv_${PREFIX}_global_1deg_${YEAR}.nc
#         cdo -z zip_6 -O mergetime conv_${PREFIX}_global_1deg_$((YEAR-1))_dec.nc conv_${PREFIX}_global_1deg_${YEAR}.nc conv_${PREFIX}_global_1deg_${YEAR}_$((YEAR-1))12.nc
#     fi
#     
#     rm conv_${PREFIX}_global_1deg_${YEAR}.nc
    
    
#     cdo -z zip_6 -O selmonth,12 conv_${PREFIX}_global_1deg_${YEAR}.nc conv_${PREFIX}_global_1deg_${YEAR}_dec.nc
#     cdo -z zip_6 -O selmonth,1 conv_${PREFIX}_global_1deg_${YEAR}.nc conv_${PREFIX}_global_1deg_${YEAR}_jan.nc
#     cdo -z zip_6 -O selmonth,1/6 conv_${PREFIX}_global_1deg_${YEAR}.nc conv_${PREFIX}_global_1deg_${YEAR}_firsthalf.nc
    


# cdo -z zip_6 -O shifttime,-1day CO2_20190101_3h.nc CO2_20181231_3h.nc

# cdo -z zip_6 -O sellevel,0,1,2,3 conv_${PREFIX}_global_1deg_${YEAR}_firsthalf.nc conv_${PREFIX}_global_1deg_${YEAR}_firsthalf_lv0-3.nc







# cdo -z zip_6 -O shifttime,-1day gph_20190101_3h.nc gph_20181231_3h.nc
# cdo -z zip_6 -O mergetime gph_*_3h.nc tempfile_merge.nc
# cdo -z zip_6 -O setreftime,2019-01-01,00:00:00,hours -selyear,${YEAR} -inttime,$((YEAR-1))-12-31,1:30:00,1hour tempfile_merge.nc conv_${PREFIX}_global_1deg_${YEAR}.nc
# cdo -z zip_6 -O selmonth,1/6 conv_${PREFIX}_global_1deg_${YEAR}.nc conv_${PREFIX}_global_1deg_${YEAR}_firsthalf.nc


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





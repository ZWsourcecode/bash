#!/bin/bash
HOME_PATH=$(cd .. && pwd)
SCRIPT_PATH=$HOME_PATH/script
CO2_PATH=${HOME_PATH}/CAMSco2

declare -a arr_lon=("5.5" "19" "13.56" )
declare -a arr_lat=("58" "57.5" "45.62")

for i in ${!arr_lon[@]}; do
    echo $i ${arr_lon[i]} ${arr_lat[i]}
    
    cdo remapnn,lon=${arr_lon[i]}-lat=${arr_lat[i]} ${CO2_PATH}/CO2_daily_2017_2020.nc ${CO2_PATH}/extract_daily_co2_${arr_lon[i]}E_${arr_lat[i]}N_CAMS_2017_2020.nc
    
    cdo outputtab,name,date,lev,lon,lat,value ${CO2_PATH}/extract_daily_co2_${arr_lon[i]}E_${arr_lat[i]}N_CTE_2017_2020.nc > ${CO2_PATH}/extract_daily_co2_${arr_lon[i]}E_${arr_lat[i]}N_CAMS_2017_2020.txt
done


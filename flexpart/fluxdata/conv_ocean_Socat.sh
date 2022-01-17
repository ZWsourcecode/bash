#!/bin/bash
### convert emission data into 1 , 0.25 or 0.1 degree
### run : bash conv_ocean.sh 
### zhendong.wu@nateko.lu.se

HOME_PATH=$(cd .. && pwd)
SCRIPT_PATH=$HOME_PATH/script
IN_PATH=$HOME_PATH/ocean/SOCAT
OUT_PATH=$HOME_PATH/ocean/SOCAT

GRIDFILE_010=$SCRIPT_PATH/mygrid_010deg.txt
GRIDFILE_025=$SCRIPT_PATH/mygrid_025deg.txt
GRIDFILE_100=$SCRIPT_PATH/mygrid_100deg.txt

SOURCE=SOCAT

LON1=-25
LON2=60
LAT1=10
LAT2=75

YEARSTART=2017      
YEAREND=2020 

cd $IN_PATH

# ncks -O -v co2flux_ocean oc_v2021_daily.nc co2flux.nc

cdo -O selyear,${YEARSTART}/${YEAREND}/1 co2flux.nc ${SOURCE}_ocean_${YEARSTART}_${YEAREND}.nc
ncrename -v co2flux_ocean,flux ${SOURCE}_ocean_${YEARSTART}_${YEAREND}.nc
ncrename -v mtime,time ${SOURCE}_ocean_${YEARSTART}_${YEAREND}.nc

# Pg C /yr to micromol/m2/s
cdo -O expr,'flux=flux*1e15/12.011*1000000/365/24/3600/277500/222000' ${SOURCE}_ocean_${YEARSTART}_${YEAREND}.nc tempfile_unit.nc
ncatted -a units,flux,o,c,"micromol/m2/s" tempfile_unit.nc

PREFIX=$SOURCE

#remap
cdo -f nc4c -O -P 4 remapcon,${GRIDFILE_100} tempfile_unit.nc tempfile_100.nc
cdo -f nc4c -O -P 4 remapcon,${GRIDFILE_010} tempfile_unit.nc tempfile_010.nc

# crop nest domain
cdo -O sellonlatbox,$LON1,$LON2,$LAT1,$LAT2 tempfile_010.nc tempfile_010nest.nc

PREFIX=$SOURCE
# interpolate time
cdo -O shifttime,-1year -selmon,12 -selyear,${YEARSTART} tempfile_100.nc tempfile_mon12.nc
cdo -O shifttime,1year -selmon,1 -selyear,${YEAREND} tempfile_100.nc tempfile_mon1.nc
cdo -O mergetime tempfile_mon1.nc tempfile_100.nc tempfile_mon12.nc tempfile_merge.nc
cdo -z zip_6 -O setreftime,${YEARSTART}-01-01,00:00:00,hours -selyear,${YEARSTART}/${YEAREND}/1 -settaxis,$((YEARSTART-1))-12-15,00:00:00,1hour -inttime,$((YEARSTART-1))-12-15,00:00:00,1hour -setcalendar,standard tempfile_merge.nc conv_${PREFIX}_merge_global_1deg_${YEARSTART}_${YEAREND}.nc

cdo -O shifttime,-1year -selmon,12 -selyear,${YEARSTART} tempfile_010nest.nc tempfile_mon12.nc
cdo -O shifttime,1year -selmon,1 -selyear,${YEAREND} tempfile_010nest.nc tempfile_mon1.nc
cdo -O mergetime tempfile_mon1.nc tempfile_010nest.nc tempfile_mon12.nc tempfile_merge.nc
cdo -z zip_6 -O setreftime,${YEARSTART}-01-01,00:00:00,hours -selyear,${YEARSTART}/${YEAREND}/1 -settaxis,$((YEARSTART-1))-12-15,00:00:00,1hour -inttime,$((YEARSTART-1))-12-15,00:00:00,1hour -setcalendar,standard tempfile_merge.nc conv_${PREFIX}_merge_nest_0.10deg_${YEARSTART}_${YEAREND}.nc


# for file in $SOURCE*.nc
# do
#     echo $file
#     YEAR=$(echo $file | cut -d . -f 1 | cut -d _ -f 3)
#     cdo -O selvar,flux $file tempfile_flux.nc
#     
#     # mol/m2/yr to micromol/m2/s
#     cdo -O expr,'flux=flux*1000000/365/24/3600' tempfile_flux.nc tempfile_unit.nc
#     ncatted -a units,flux,o,c,"micromol/m2/s" tempfile_unit.nc
#     
#     # remap
#     cdo -f nc4c -O -P 4 remapcon,${GRIDFILE_100} tempfile_unit.nc tempfile_100.nc
# #     cdo -f nc4c -O -P 4 remapcon,${GRIDFILE_025} ${file} tempfile.nc
#     cdo -f nc4c -O -P 4 remapcon,${GRIDFILE_010} tempfile_unit.nc tempfile_010.nc
#     
#     # crop nest domain
# #     cdo -O sellonlatbox,$LON1,$LON2,$LAT1,$LAT2 tempfile.nc temp025nest_${file}
#     cdo -O sellonlatbox,$LON1,$LON2,$LAT1,$LAT2 tempfile_010.nc tempfile_010nest.nc
#     
#     # interpolate time
#     cdo -O shifttime,-1year -selmon,12 tempfile_100.nc tempfile_mon12.nc
#     cdo -O shifttime,1year -selmon,1 tempfile_100.nc tempfile_mon1.nc
#     cdo -O mergetime tempfile_mon1.nc tempfile_100.nc tempfile_mon12.nc tempfile_merge.nc
#     cdo -O setreftime,2019-01-01,00:00:00,hours -selyear,${YEAR} -settaxis,$((YEAR-1))-12-15,00:00:00,1hour -inttime,$((YEAR-1))-12-15,00:00:00,1hour tempfile_merge.nc tempfile_100_${YEAR}.nc
#     
#     cdo -O shifttime,-1year -selmon,12 tempfile_010nest.nc tempfile_mon12.nc
#     cdo -O shifttime,1year -selmon,1 tempfile_010nest.nc tempfile_mon1.nc
#     cdo -O mergetime tempfile_mon1.nc tempfile_010nest.nc tempfile_mon12.nc tempfile_merge.nc
#     cdo -O setreftime,2019-01-01,00:00:00,hours -selyear,${YEAR} -settaxis,$((YEAR-1))-12-15,00:00:00,1hour -inttime,$((YEAR-1))-12-15,00:00:00,1hour tempfile_merge.nc tempfile_010_${YEAR}.nc
#     
# done
# 
# PREFIX=$(echo $file | cut -d _ -f -2)
# 
# cdo -z zip_6 -O mergetime tempfile_100_*.nc conv_${PREFIX}_global_1deg_2019.nc
# # cdo -z zip_6 -O mergetime temp025nest_*.nc conv_${PREFIX}_nest_0.25deg_2019.nc
# cdo -z zip_6 -O mergetime tempfile_010_*.nc conv_${PREFIX}_nest_0.10deg_2019.nc

#!/bin/bash
### convert emission data into 1 , 0.25 or 0.1 degree
### run : bash conv_fire.sh 
### zhendong.wu@nateko.lu.se

# nccopy GFED4.1s_2019_beta.hdf5 GFED4.1s_2019_beta.nc

HOME_PATH=$(cd .. && pwd)
SCRIPT_PATH=$HOME_PATH/script
IN_PATH=$HOME_PATH/fire
OUT_PATH=$HOME_PATH/fire

GRIDFILE_010=$SCRIPT_PATH/mygrid_010deg.txt
GRIDFILE_025=$SCRIPT_PATH/mygrid_025deg.txt
GRIDFILE_100=$SCRIPT_PATH/mygrid_100deg.txt

SOURCE=GFED4.1s

LON1=-25
LON2=60
LAT1=10
LAT2=75

cd $IN_PATH

cdo -O mergetime ${SOURCE}*beta_C.nc tempfile_merge_beta_C.nc

file=tempfile_merge_beta_C.nc
echo $file
YEARSTART=2017
YEAREND=2020
PREFIX=$SOURCE
FILENAME=$(echo $file | cut -d . -f -2)
NEWFILENAME=${FILENAME}_refine.nc

ncap2 -O -s 'time=int(time)' $file $NEWFILENAME
ncatted -O -a standard_name,latitude,c,c,latitude $NEWFILENAME
ncatted -O -a standard_name,longitude,c,c,longitude $NEWFILENAME
ncatted -O -a long_name,fireC,o,c,"fire carbon emission" $NEWFILENAME
# 	ncatted -a standard_name,dswrf,c,c,surface_downwelling_shortwave_flux $file
ncatted -O -a units,latitude,o,c,degrees_north $NEWFILENAME
ncatted -O -a units,longitude,o,c,degrees_east $NEWFILENAME

# g C m-2 month-1 to micromol/m2/s
cdo -O expr,'fireC=fireC*1000000/12.011/30/24/3600' $NEWFILENAME tempfile_unit.nc
ncatted -a units,fireC,o,c,"micromol/m2/s" tempfile_unit.nc
rm $NEWFILENAME

# remap
cdo -f nc4c -O -P 4 remapcon,${GRIDFILE_100} tempfile_unit.nc tempfile_100.nc
#     cdo -f nc4c -O -P 4 remapcon,${GRIDFILE_025} ${file} tempfile.nc
cdo -f nc4c -O -P 4 remapcon,${GRIDFILE_010} tempfile_unit.nc tempfile_010.nc
rm tempfile_unit.nc

# crop nest domain
#     cdo -O sellonlatbox,$LON1,$LON2,$LAT1,$LAT2 tempfile.nc temp025nest_${file}
cdo -O sellonlatbox,$LON1,$LON2,$LAT1,$LAT2 tempfile_010.nc tempfile_010nest.nc

# interpolate time
cdo -O shifttime,-1year -selmon,12 -selyear,${YEARSTART} tempfile_100.nc tempfile_mon12.nc
cdo -O shifttime,1year -selmon,1 -selyear,${YEAREND} tempfile_100.nc tempfile_mon1.nc
cdo -O mergetime tempfile_mon1.nc tempfile_100.nc tempfile_mon12.nc tempfile_merge.nc
cdo -z zip_6 -O setreftime,${YEARSTART}-01-01,00:00:00,hours -selyear,${YEARSTART}/${YEAREND}/1 -settaxis,$((YEARSTART-1))-12-15,00:00:00,1hour -inttime,$((YEARSTART-1))-12-15,00:00:00,1hour -setcalendar,standard tempfile_merge.nc conv_${PREFIX}_merge_global_1deg_${YEARSTART}_${YEAREND}.nc

cdo -O shifttime,-1year -selmon,12 -selyear,${YEARSTART} tempfile_010nest.nc tempfile_mon12.nc
cdo -O shifttime,1year -selmon,1 -selyear,${YEAREND} tempfile_010nest.nc tempfile_mon1.nc
cdo -O mergetime tempfile_mon1.nc tempfile_010nest.nc tempfile_mon12.nc tempfile_merge.nc
cdo -z zip_6 -O setreftime,${YEARSTART}-01-01,00:00:00,hours -selyear,${YEARSTART}/${YEAREND}/1 -settaxis,$((YEARSTART-1))-12-15,00:00:00,1hour -inttime,$((YEARSTART-1))-12-15,00:00:00,1hour -setcalendar,standard tempfile_merge.nc conv_${PREFIX}_merge_nest_0.10deg_${YEARSTART}_${YEAREND}.nc

rm tempfile_010.nc tempfile_010nest.nc tempfile_100.nc tempfile_merge_beta_C.nc
    




# cdo -z zip_6 -O mergetime tempfile_100_*.nc conv_${PREFIX}_global_1deg_2019.nc
# cdo -z zip_6 -O mergetime temp025nest_*.nc conv_${PREFIX}_nest_0.25deg_2019.nc
# cdo -b f32 -z zip_6 -O mergetime tempfile_010_*.nc conv_${PREFIX}_nest_0.10deg_2019.nc

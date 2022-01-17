#!/bin/bash
### convert emission data into 1 ,0.25 or 0.1 degree
### run : bash conv_emis.sh 
### zhendong.wu@nateko.lu.se

HOME_PATH=$(cd .. && pwd)
SCRIPT_PATH=$HOME_PATH/script
IN_PATH=$HOME_PATH/emission/GridFED
OUT_PATH=$HOME_PATH/emission/GridFED

GRIDFILE_010=$SCRIPT_PATH/mygrid_010deg.txt
GRIDFILE_025=$SCRIPT_PATH/mygrid_025deg.txt
GRIDFILE_100=$SCRIPT_PATH/mygrid_100deg.txt

SOURCE=GridFED

YEARSTART=2017      
YEAREND=2020 

LON1=-25
LON2=60
LAT1=10
LAT2=75

cd $IN_PATH

for file in GCP*${YEAR}*.nc
do
    echo $file
    
    ncks -O -G : -g CO2 $file tempfile_co2.nc
    cdo -O expr,'emission=GAS+COAL+CEMENT+OIL+BUNKER' tempfile_co2.nc tempfile_emission.nc
    # kg CO2 month-1 to micromol/m2/s
    cdo -O expr,'emission=emission*1000000*1000/44.01/30/24/3600/11100/11100' tempfile_emission.nc tempfile_unit.nc
    ncatted -a units,emission,o,c,"micromol/m2/s" tempfile_unit.nc
    
    ncatted -O -a standard_name,lat,c,c,latitude tempfile_unit.nc
	ncatted -O -a standard_name,lon,c,c,longitude tempfile_unit.nc
	ncatted -O -a units,lat,o,c,degrees_north tempfile_unit.nc
	ncatted -O -a units,lon,o,c,degrees_east tempfile_unit.nc

    #PREFIX=$(echo $file | rev | cut -d _ -f 1 | rev | cut -d . -f 1)
    
    cdo -f nc4c -O -P 4 remapcon,${GRIDFILE_100} tempfile_unit.nc temp100_${file}
    cdo -f nc4c -O -P 4 remapcon,${GRIDFILE_010} tempfile_unit.nc tempfile2.nc
    
    # crop nest domain
    
    cdo -O sellonlatbox,$LON1,$LON2,$LAT1,$LAT2 tempfile2.nc temp010nest_${file}
done

PREFIX=$SOURCE

cdo -z zip_6 -O mergetime temp100_*.nc tempfile_100.nc
cdo -z zip_6 -O mergetime temp010nest_*.nc tempfile_010nest.nc
# rm temp100_*.nc temp010nest_*.nc

# interpolate time
cdo -O shifttime,-1year -selmon,12 -selyear,${YEARSTART} tempfile_100.nc tempfile_mon12.nc
cdo -O shifttime,1year -selmon,1 -selyear,${YEAREND} tempfile_100.nc tempfile_mon1.nc
cdo -O mergetime tempfile_mon1.nc tempfile_100.nc tempfile_mon12.nc tempfile_merge.nc
cdo -z zip_6 -O setreftime,${YEARSTART}-01-01,00:00:00,hours -selyear,${YEARSTART}/${YEAREND}/1 -settaxis,$((YEARSTART-1))-12-15,00:00:00,1hour -inttime,$((YEARSTART-1))-12-15,00:00:00,1hour -setcalendar,standard tempfile_merge.nc conv_${PREFIX}_merge_global_1deg_${YEARSTART}_${YEAREND}.nc

cdo -O shifttime,-1year -selmon,12 -selyear,${YEARSTART} tempfile_010nest.nc tempfile_mon12.nc
cdo -O shifttime,1year -selmon,1 -selyear,${YEAREND} tempfile_010nest.nc tempfile_mon1.nc
cdo -O mergetime tempfile_mon1.nc tempfile_010nest.nc tempfile_mon12.nc tempfile_merge.nc
cdo -z zip_6 -O setreftime,${YEARSTART}-01-01,00:00:00,hours -selyear,${YEARSTART}/${YEAREND}/1 -settaxis,$((YEARSTART-1))-12-15,00:00:00,1hour -inttime,$((YEARSTART-1))-12-15,00:00:00,1hour -setcalendar,standard tempfile_merge.nc conv_${PREFIX}_merge_nest_0.10deg_${YEARSTART}_${YEAREND}.nc

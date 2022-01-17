#!/bin/bash
### convert emission data into 1 ,0.25 or 0.1 degree
### run : bash conv_emis.sh 
### zhendong.wu@nateko.lu.se

HOME_PATH=$(cd .. && pwd)
SCRIPT_PATH=$HOME_PATH/script
IN_PATH=$HOME_PATH/emission
OUT_PATH=$HOME_PATH/emission

GRIDFILE_010=$SCRIPT_PATH/mygrid_010deg.txt
GRIDFILE_025=$SCRIPT_PATH/mygrid_025deg.txt
GRIDFILE_100=$SCRIPT_PATH/mygrid_100deg.txt

SOURCE=EDGARv4.3

YEAR=2018                                                                                                                                                                                                                                                                

LON1=-25
LON2=60
LAT1=10
LAT2=75

cd $IN_PATH

for file in $SOURCE*${YEAR}*.nc
do
    echo $file
    #PREFIX=$(echo $file | rev | cut -d _ -f 1 | rev | cut -d . -f 1)
    
    cdo -f nc4c -O -P 4 remapcon,${GRIDFILE_100} ${file} temp100_${file}
    
    cdo -f nc4c -O -P 4 remapcon,${GRIDFILE_010} ${file} tempfile2.nc
    
    # crop nest domain
    
    cdo -O sellonlatbox,$LON1,$LON2,$LAT1,$LAT2 tempfile2.nc temp010nest_${file}
done

PREFIX=$(echo $file | cut -d . -f -2)

cdo -z zip_6 -O mergetime temp100_*.nc conv_${PREFIX}_global_1deg_${YEAR}.nc
cdo -z zip_6 -O mergetime temp010nest_*.nc conv_${PREFIX}_nest_0.10deg_${YEAR}.nc
rm temp100_*.nc temp010nest_*.nc

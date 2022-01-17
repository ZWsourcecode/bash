#!/bin/bash
### convert biospheric flux data into 1 , 0.25 or 0.1 degree
### run : bash conv_lpj.sh 
### zhendong.wu@nateko.lu.se


HOME_PATH=$(cd .. && pwd)
SCRIPT_PATH=$HOME_PATH/script
IN_PATH=$HOME_PATH/biospheric/lpj
OUT_PATH=$HOME_PATH/biospheric/lpj

GRIDFILE_010=$SCRIPT_PATH/mygrid_010deg_lpj.txt
GRIDFILE_025=$SCRIPT_PATH/mygrid_025deg.txt
GRIDFILE_100=$SCRIPT_PATH/mygrid_100deg.txt

SOURCE=lpj

LON1=-25
LON2=60
LAT1=10
LAT2=75

cd $IN_PATH

for file in $SOURCE*hgpp*.nc
do
    echo $file
    PREFIX=$(echo $file | cut -d _ -f -2)
    YEAR=$(echo $file | cut -d _ -f 3 | cut -d . -f 1)
    FILENAME=$(echo $file | cut -d . -f -1)
    NEWFILENAME=refine_${FILENAME}.nc
    
    ncap2 -O -s 'time=int(time)' $file $NEWFILENAME
    ncatted -O -a standard_name,lat,c,c,latitude $NEWFILENAME
	ncatted -O -a standard_name,lon,c,c,longitude $NEWFILENAME
	ncatted -O -a long_name,gpp,o,c,"gross primary productivity" $NEWFILENAME
# 	ncatted -a standard_name,dswrf,c,c,surface_downwelling_shortwave_flux $file
	ncatted -O -a units,lat,o,c,degrees_north $NEWFILENAME
	ncatted -O -a units,lon,o,c,degrees_east $NEWFILENAME
	
    # kg C m-2 hour-1 to micromol/m2/s
    cdo -O expr,'gpp=gpp*1000*1000000/12.011/3600' $NEWFILENAME tempfile_unit.nc
    ncatted -a units,gpp,o,c,"micromol/m2/s" tempfile_unit.nc
    
    rm $NEWFILENAME
    # remap
    cdo -f nc4c -O -P 4 remapcon,${GRIDFILE_100} tempfile_unit.nc tempfile_100.nc
    cdo -f nc4c -O -P 4 remapcon,${GRIDFILE_010} tempfile_unit.nc tempfile_010.nc
    
    # crop nest domain
    cdo -O sellonlatbox,$LON1,$LON2,$LAT1,$LAT2 tempfile_010.nc tempfile_010nest.nc
    
    rm tempfile_010.nc
    if (($YEAR == 2020 )); then
        cdo -O seldate,${YEAR}-02-28 tempfile_100.nc tempfile_100_${YEAR}0208.nc
        cdo -O shifttime,1day tempfile_100_${YEAR}0208.nc tempfile_100_${YEAR}0209.nc
        cdo -O mergetime tempfile_100_${YEAR}0209.nc tempfile_100.nc tempfile_100_leap.nc
        cdo -z zip_6 -O setcalendar,standard tempfile_100_leap.nc conv_${PREFIX}_global_1deg_${YEAR}.nc
        
        cdo -O seldate,${YEAR}-02-28 tempfile_unit.nc tempfile_unit_${YEAR}0208.nc
        cdo -O shifttime,1day tempfile_unit_${YEAR}0208.nc tempfile_unit_${YEAR}0209.nc
        cdo -O mergetime tempfile_unit_${YEAR}0209.nc tempfile_unit.nc tempfile_unit_leap.nc
        cdo -z zip_6 -O setcalendar,standard tempfile_unit_leap.nc conv_${PREFIX}_global_0.50deg_${YEAR}.nc
        
        cdo -O seldate,${YEAR}-02-28 tempfile_010nest.nc tempfile_010nest_${YEAR}0208.nc
        cdo -O shifttime,1day tempfile_010nest_${YEAR}0208.nc tempfile_010nest_${YEAR}0209.nc
        cdo -O mergetime tempfile_010nest_${YEAR}0209.nc tempfile_010nest.nc tempfile_010nest_leap.nc
        cdo -z zip_6 -O setcalendar,standard tempfile_010nest_leap.nc conv_${PREFIX}_nest_0.10deg_${YEAR}.nc
    else
        cdo -z zip_6 -O setcalendar,standard tempfile_100.nc conv_${PREFIX}_global_1deg_${YEAR}.nc
        cdo -z zip_6 -O setcalendar,standard tempfile_unit.nc conv_${PREFIX}_global_0.50deg_${YEAR}.nc
        cdo -z zip_6 -O setcalendar,standard tempfile_010nest.nc conv_${PREFIX}_nest_0.10deg_${YEAR}.nc
    fi
    
done
# rm tempfile_010.nc tempfile_010nest.nc tempfile_100.nc

PREFIX=lpj_hgpp
cdo -z zip_6 -O mergetime conv_${PREFIX}_global_1deg_*.nc conv_${PREFIX}_merge_global_1deg_2017_2020.nc
cdo -b f32 -z zip_6 -O mergetime conv_${PREFIX}_nest_0.10deg_*.nc conv_${PREFIX}_merge_nest_0.10deg_2017_2020.nc

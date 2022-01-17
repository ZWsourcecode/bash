#!/bin/bash
### harmonize LPJ-GUESS and VPRM
# 
### zhendong.wu@nateko.lu.se

HOME_PATH=$(cd .. && pwd)
SCRIPT_PATH=$HOME_PATH/script
LPJ_PATH=$HOME_PATH/biospheric/lpj
VPRM_PATH=$HOME_PATH/biospheric/vprm

GRIDFILE_010=$SCRIPT_PATH/mygrid_010deg_eu.txt
GRIDFILE_050=$SCRIPT_PATH/mygrid_050deg_eu.txt

# nee,gpp,rtot
FLUX_LPJ='rtot'
# NEE,GEE,RESP
FLUX_VPRM='RESP'

LON1=-15
LON2=35
LAT1=33
LAT2=73

# LON1=-25
# LON2=60
# LAT1=10
# LAT2=75

# crop nest domain
# cd $LPJ_PATH
# for year in {2018..2020}
# do
#     cdo -z zip_6 -O sellonlatbox,$LON1,$LON2,$LAT1,$LAT2 conv_lpj_hnee_nest_0.10deg_${year}.nc conv_lpj_hnee_eu_0.10deg_${year}.nc
# done
# 
# cd $VPRM_PATH
# for year in {2018..2020}
# do
#     file=$(ls *_NEE_${year}*.nc)
#     PREFIX=$(echo $file | cut -d _ -f -4)
#     cdo -z zip_6 -f nc4c -O -P 4 remapcon,${GRIDFILE_010} $file ${PREFIX}_0.10deg.nc
# done


# crop nest domain
cd $LPJ_PATH
for year in {2018..2020}
do
    cdo -z zip_6 -O sellonlatbox,$LON1,$LON2,$LAT1,$LAT2 conv_lpj_h${FLUX_LPJ}_nest_0.10deg_${year}.nc conv_lpj_h${FLUX_LPJ}_eu_0.10deg_${year}.nc
    cdo -z zip_6 -f nc4c -O -P 4 remapcon,${GRIDFILE_050} conv_lpj_h${FLUX_LPJ}_eu_0.10deg_${year}.nc conv_lpj_h${FLUX_LPJ}_eu_0.50deg_${year}.nc 
done

cd $VPRM_PATH
for year in {2018..2020}
do
    file=$(ls *_${FLUX_VPRM}_${year}_CP.nc)
    PREFIX=$(echo $file | cut -d _ -f -4)
    cdo -z zip_6 -f nc4c -O -P 4 remapcon,${GRIDFILE_010} $file ${PREFIX}_0.10deg.nc
    cdo -z zip_6 -f nc4c -O -P 4 remapcon,${GRIDFILE_050} $file ${PREFIX}_0.50deg.nc
done

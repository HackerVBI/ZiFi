#!/bin/sh
cp ../zifi.asm zifi.asm
cp zifi.asm zifi_rs.asm
sed -i 's/cable_zifi=0/cable_zifi=1/g' zifi_rs.asm
cd ..
wine sjasmplus _spg/zifi.asm
wine sjasmplus _spg/zifi_rs.asm
cd _spg
wine spgbld.exe -b spgbld.ini zifi.spg
wine spgbld.exe -b spgbld_rs.ini zifi_rs.spg
cp zifi.spg ../_Current_version_executable/zifi.spg
cp zifi_rs.spg ../_Current_version_executable/zifi_rs.spg
rm -rf zifi.asm
rm -rf zifi_rs.asm

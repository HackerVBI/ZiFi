@echo off
set PROJNAME=wifi

rem --- SPG builder - https://zx-evo-fpga.googlecode.com/hg/pentevo/tools/spgbld/spgbld.exe
spgbld.exe -b spgbld.ini %PROJNAME%.spg -c 0
if exist %PROJNAME%.spg goto ok

:err
echo * ERROR! *

:ok
set ASMDIR=
set PROJNAME=

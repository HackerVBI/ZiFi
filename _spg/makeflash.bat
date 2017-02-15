@echo off

mkdir ZIFI
del /s /q ZIFI\*.*
xcopy /Y zifi_rs.spg ZIFI\
xcopy /Y zifi.spg ZIFI\
xcopy /Y zifi.ini ZIFI\

SET IName="H:\speccy\_Emul\UnrealEvo_zifi\wc.img"

rem robimg.exe -p=%IName% -a=1 -f=1 -o=2048 -s=262144
rem robimg.exe -p=%IName% -a=1 -f=1 -s=131072

rem robimg.exe -p=%IName% -M="Test\InOne\InTwo\InThre1"
robimg.exe -p=%IName% -C="ZIFI",\ZIFI

del /s /q ZIFI\*.*
rmdir /s /q "ZIFI"



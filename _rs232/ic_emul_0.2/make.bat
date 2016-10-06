@echo off

set TOOLS_PATH=D:\proj\zx\floppy-disk-ripper\_tools

set GCC_PATH=%TOOLS_PATH%\mingw\bin;%TOOLS_PATH%\mingw\msys\1.0\bin
set PATH=%GCC_PATH%;%PATH%

gcc -Wall -Wno-pointer-sign -c ic_main.c -o ic_main.o
gcc -Wall -Wno-pointer-sign -c ic_cmds.c -o ic_cmds.o 
gcc -Wall -Wno-pointer-sign -c log.c -o log.o
gcc -Wall -Wno-pointer-sign -c uart_win.c -o uart.o
gcc ic_main.o ic_cmds.o log.o uart.o  -lws2_32 -o ic.exe
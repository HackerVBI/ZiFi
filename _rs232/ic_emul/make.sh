#!/bin/bash

gcc -Wall -Wno-pointer-sign -c ic_main.c -o ic_main.o
gcc -Wall -Wno-pointer-sign -c ic_cmds.c -o ic_cmds.o
gcc -Wall -Wno-pointer-sign -c log.c -o log.o
gcc -Wall -Wno-pointer-sign -c uart_lin.c -o uart.o

gcc ic_main.o ic_cmds.o log.o uart.o  -o ic

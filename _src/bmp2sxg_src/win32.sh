#!/bin/sh

mingw32-gcc -o bmp2sxg.exe -std=c99 bmp2sxg.c
upx -9 bmp2sxg.exe

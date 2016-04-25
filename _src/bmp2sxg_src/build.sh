#!/bin/sh

gcc -o bmp2sxg -std=c99 bmp2sxg.c
upx -9 bmp2sxg

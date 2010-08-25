#!/bin/sh
cl65 -Oirs --cpu 65C02 -t bbc --listing file.c -o prog
pasta splitpal.s -o splitp
# adfs disk.adl .
cp splitp splitp.inf prog prog.inf clouds clouds.inf "$OUTPUTDISK"

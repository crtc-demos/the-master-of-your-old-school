#!/bin/sh
. ../joeys/load_cc65.shlib
set -e
set -x
cl65 -Oirs --cpu 65C02 -t bbc --listing file.c -o prog
pasta splitpal.s -o splitp
# adfs disk.adl .
# prog prog.inf
cp splitp splitp.inf clouds2 clouds2.inf "$OUTPUTDISK"

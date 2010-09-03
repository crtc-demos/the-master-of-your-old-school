#!/bin/sh
set -e
set -x
# cl65 -Oirs --cpu 65C02 -t bbc --listing file.c -o prog
pasta -a end.s -o end
# adfs disk.adl .
cp end end.inf endscr endscr.inf "$OUTPUTDISK"

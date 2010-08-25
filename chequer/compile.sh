#!/bin/sh
cl65 -Oirs --cpu 65C02 -t bbc --listing file.c -o prog
~/code/pasta/pasta splitpal.s -o splitp
~/code/adfs/adfs disk.adl .

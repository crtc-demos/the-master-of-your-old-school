#!/bin/sh
set -e
set -x
# cl65 -Oirs --cpu 65C02 -t bbc --listing file.c -o prog
~/code/pasta/pasta -a crtc-logo.s -o logo
~/code/adfs/adfs disk.adl .

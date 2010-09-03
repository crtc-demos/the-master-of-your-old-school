#!/bin/sh
set -e
set -x
# cl65 -Oirs --cpu 65C02 -t bbc --listing file.c -o prog
pasta -a demo.s -o !boot
# adfs disk.adl .
cp '!boot' '!boot.inf' "$OUTPUTDISK"


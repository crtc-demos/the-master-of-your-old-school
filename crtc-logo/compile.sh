#!/bin/sh
set -e
set -x
# cl65 -Oirs --cpu 65C02 -t bbc --listing file.c -o prog
pasta -a crtc-logo.s -o logo
# adfs disk.adl .
cp b2crle b2crle.inf blkrle blkrle.inf c2rrle c2rrle.inf logo logo.inf r2trle r2trle.inf t2crle t2crle.inf "$OUTPUTDISK"

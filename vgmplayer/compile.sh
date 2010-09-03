#!/bin/sh
set -e
set -x
pasta -a vgmp.s -o vgmp
cp vgmp vgmp.inf tune tune.inf "$OUTPUTDISK"

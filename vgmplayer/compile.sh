#!/bin/sh
set -e
set -x
pasta -a vgmp.s -o vgmp
cp vgmp vgmp.inf track track.inf music music.inf "$OUTPUTDISK"

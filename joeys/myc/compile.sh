#!/bin/sh

. ../load_cc65.shlib

## This combination does not work!
# cc65 test.c &&
# ca65 -l -t bbc test.s &&
# ld65 -t bbc -o test test.o bbc.lib

cl65 -t bbc -o test test.c
cc65 test.c ## generate the .s for interest

## Deploy
cp -f ./test ../mycode.conv/test


#!/bin/sh
#xa mult.a65 -l mult.l -o mult
pasta -a cube.s -o mult
#ophis -65c02 flim.oph flim
#../pasta/pasta -o flim ../pasta/tests/flimsy.s
#adfs mydisc.adl .
cp mult mult.inf exptab exptab.inf logtab logtab.inf sintab sintab.inf sqtab sqtab.inf "$OUTPUTDISK"

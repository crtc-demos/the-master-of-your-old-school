10000 MODE 7
10020 :
10040 PROCinitGrid
10060 :
10080 FOR time%=1 TO 1000
10100   C%=255 : PROCgridFrame
10120   C%=0 : PROCgridFrame
10140 gridx=gridx+0.1243
10160 gridy=gridy+0.242
10180 gridspacing=gridspacing+0.044
10200 gridshear = gridshear + 0.01
10220 NEXT
10240 :
10260 END

10300 REM Grid
10320 :
10340 DEF PROCinitGrid
10360   gridspacing=7.239
10380   gridzoom=1.0
10400   gridx=0.0
10420   gridy=0.0
10440   gridrotation=0.0
10460   gridpitch=0.0
10480   gridshear=0.01
10500 ENDPROC
10520 :
10540 DEF PROCgridFrame
10560 FOR Y%=0 TO 24
10580   L%=&7C00+Y%*40
10600   X%=0
10620   REM IF RND(2)<1 THEN C%=0
10640   REM Sequence 2 + n*gridspacing
11111   LSTEP%=gridspacing+Y%*gridshear+0.5
11111   IF LSTEP%<2 THEN LSTEP%=2
10660   N%=1
10680   REPEAT
REM 10700     HIT%=gridx+N%*gridspacing
10700     HIT%=X%+LSTEP%
REM 10720     IF HIT% <= X% THEN GOTO 10640
10740     REM WHILE HIT% > X% DO
10760       X%=HIT%
REM 10780       C%=(255-C%)
REM 10800       PRINTTAB(X%,Y%)CHR$(C%)
10820       ?(L%+X%)=C%
10860     : REM endgoto
10880     N%=N%+1
10900   UNTIL X%>=30
10920   ?(L%+39)=ASC("0")+N%
10940 NEXT
10960 ENDPROC
10980 
11000 
11020 

11060 

RUN



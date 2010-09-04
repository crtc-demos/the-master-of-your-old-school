REM I want to make a fractal mount and then make it do fast parallalex scrolling in MODE 7.
REM First of all though I'm going to make a BASIC fractal mountain.

10040 MODE 1
10050 REM ON ERROR DO PRINT ERRLN
10060 :
10070 REM Generating mountain data options
10080 maxDepth%=3
10090 monWidth%=2^maxDepth%
10100 monDepth%=2^maxDepth%
10110 zScale = 0.2 : REM Height vs width
10120 :
10130 DIM z(monWidth%,monDepth%)
10140 :
10150 REM Drawing options
10160 scrcenx% = 640 : scrceny% = 512 - 240
10170 spaceLeft%=-600 : spaceRight%=+600
10180 monTop%=500 : monBottom%=-500
10190 angle=2*PI/11
10190 elev=2*PI/21
10200 :
10210 scaleNow = 0.1
10220 :
10230 REM Main
10240 PROCgenerate
10250 PROCdrawMountain
10250 GCOL 1,1 : angle = angle + PI/39 : scrceny%=scrceny%+240 : PROCdrawMountain
10250 GCOL 1,2 : angle = angle + PI/39 : scrceny%=scrceny%+240 : PROCdrawMountain
10260 END
10270 :
10280 DEF PROCgenerate
10290   dummy = RND(-TIME)
10290   z(0,0) = monBottom% + RND(1)*(monTop% - monBottom%)
10300   z(monWidth%,0) = monBottom% + RND(1)*(monTop% - monBottom%)
10310   z(0,monDepth%) = monBottom% + RND(1)*(monTop% - monBottom%)
10320   z(monWidth%,monDepth%) = monBottom% + RND(1)*(monTop% - monBottom%)
10330   PROCgenerateSub(0,0,monWidth%,monDepth%)
10340 ENDPROC
10350 
10360 DEF PROCgenerateSub(left%,top%,right%,bottom%)
10370   REM LOCAL left%,right%,top%,bottom%,midx%,midy%
10380   LOCAL midx%,midy%
REM 10390   PRINTTAB(0,0),left%,right%;
REM 10400   PRINTTAB(0,1),top%,bottom%;
10410   scaleNow = (right%-left%) * (monTop%-monBottom%)/(monWidth%) * zScale
10420   midx% = (left%+right%)/2
10430   midy% = (top%+bottom%)/2
REM 10440   PRINTTAB(0,2),midx%,midy%;
REM 10450   PRINTTAB(0,3);"       ";
10460   z(left%,midy%) = FNperturb(z(left%,top%),z(left%,bottom%),scaleNow)
10470   z(right%,midy%) = FNperturb(z(right%,top%),z(right%,bottom%),scaleNow)
10480   z(midx%,top%) = FNperturb(z(left%,top%),z(right%,top%),scaleNow)
10490   z(midx%,bottom%) = FNperturb(z(left%,bottom%),z(right%,bottom%),scaleNow)
10500   z(midx%,midy%) = FNperturb4(z(left%,top%),z(right%,top%),z(left%,bottom%),z(right%,bottom%),scaleNow)
10510   IF (midx%-left%)>1 OR (midy%-top%)>1 THEN PROCgenerateSub(left%,top%,midx%,midy%)
10520   IF (right%-midx%)>1 OR (midy%-top%)>1 THEN PROCgenerateSub(midx%,top%,right%,midy%)
10530   IF (midx%-left%)>1 OR (bottom%-midy%)>1 THEN PROCgenerateSub(left%,midy%,midx%,bottom%)
10540   IF (right%-midx%)>1 OR (bottom%-midy%)>1 THEN PROCgenerateSub(midx%,midy%,right%,bottom%)
REM 10550   PRINTTAB(0,3);"LEAVING";
10560 ENDPROC
10570 :
10580 DEF FNperturb(za,zb,scaleNow)
10590 = (za+zb)/2 + scaleNow*2*(RND(1)-0.5)
10600 :
10610 DEF FNperturb4(za,zb,zc,zd,scaleNow)
10620 = (za+zb+zc+zd)/4 + scaleNow*2*(RND(1)-0.5)
10630 :
10640 DEF PROCdrawMountain
10650   FOR x%=0 TO monWidth%
10660   FOR y%=0 TO monDepth%
10000     PROCgetScrPos(x%,y%)
10750     IF y%MOD2=0 THEN MOVE scrx%,scry% ELSE DRAW scrx%,scry% : MOVE scrx%,scry%
10770   NEXT y%
10780   NEXT x%
10650   FOR y%=0 TO monDepth%
10660   FOR x%=0 TO monWidth%
10000     PROCgetScrPos(x%,y%)
10750     IF x%MOD2=0 THEN MOVE scrx%,scry% ELSE DRAW scrx%,scry% : MOVE scrx%,scry%
10770   NEXT x%
10780   NEXT y%
10790 ENDPROC
10800 :
10800 DEF PROCgetScrPos(x%,y%)
10690   z = z(x%,y%)
10670   x = spaceLeft% + (x%/monWidth%) * (spaceRight%-spaceLeft%)
10680   y = spaceLeft% + (y%/monDepth%) * (spaceRight%-spaceLeft%)
10700   REM Rotate x,y
10710   rotx = x*COS(angle) - y*SIN(angle)
10720   roty = x*SIN(angle) + y*COS(angle)
10730   scrx% = scrcenx% + rotx + roty/32.0
10740   scry% = scrceny% + z + roty/24.0
10740 ENDPROC

RUN


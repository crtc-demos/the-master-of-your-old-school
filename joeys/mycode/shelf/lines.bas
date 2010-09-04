

##### TOOD: test theory about using simpler-than-bresenham line algorithm for small gfx
also consider, using double-resolutions point mapping to screen points





10180 :
10200 REM Problem with elev%, rather than delev%, is that it affects part of track we are on, but it should only affect track ahead!
10220 REM TODO: draw backwards?  Deep /low/ lines are appearing over the nearer ones!
10240 :
10260 MODE 7
10280 VDU 23,1,0,0,0,0,0,0,0,0
10300 :
10320 DUMMY% = RND(TIME)
10340 :
10360 visdepth%=7
10380 framespersection%=3
10400 horizon%=10
10420 totalnumframes%=250
10440 spaceAllocatedForVideo% = 1024*12
10460 displayHeight% = 22
10480 :
10500 DIM dang%(visdepth%),elev%(visdepth%),left_wall%(visdepth%),right_wall%(visdepth%)
10520 DIM COLS%(2)
10540 :
10560 REM FP1 = OPENOUT "temp"
10580 REM PRINT# FP1, 1, 2, 3
10600 REM PRINT# FP1, "hello", "world"
10620 REM PRINT# FP1, -3, -2, -1
10640 REM CLOSE #FP1
10660 :
10680 FP = OPENIN "t.1def"
10700 FOR depth%=1 TO visdepth%
10720   REM INPUT# FP, dang%(depth%), elev%(depth%), left_wall%(depth%), right_wall%(depth%)
10740   REM INPUT# FP, dang%(depth%)
10760   REM PRINT dang%(depth%), elev%(depth%), left_wall%(depth%), right_wall%(depth%)
10780   PROCparseSegmentOfTrackInto(depth%)
10800 NEXT
10820 trackpos=0
10840 REM END
10860 :
10880 REM COLS%(1)=131 : REM yellow
10900 REM COLS%(2)=130 : REM green
10920 COLS%(1)=129 : REM red
10940 COLS%(2)=131 : REM cyan
10960 :
10980 PROCinitEncoding
11000 PROCassemble
11020 D%=1
11040 REM REPEAT
11060 FOR framenum%=1 TO totalnumframes%
11080   OLDY%=22
11100   CLS
11120   PROCdrawsky
11140   mid=20
11160   FOR Z=1 TO visdepth% STEP 1
11180     depth%=Z
11200     horizonHere% = horizon% : REM - elev%(depth%) - 1
11220     Y%= 1 + horizonHere% + displayHeight%/(1+2*Z)
11240     IF Y%>displayHeight% THEN Y%=displayHeight%
11260     IF OLDY%<=Y% THEN OLDY% = Y% : REM Ideally we would skip the whole loop here, because we have already drawn a line at this depth.
11280     FOR N%=OLDY% TO Y% STEP -1
11300       REM This PRINT;STRING$ deals with problems caused by multiple deep lines overwriting each other.
11320       REM Really we shouldn't have overwriting and shouldn't need this.
11340       PRINTTAB(0,N%);STRING$(40," ");
11360       IF OLDY%=Y% THEN realdepth=depth% ELSE realdepth = depth% + 1 - (N%-Y%)/(OLDY%-Y%)
11380       SCENERY$=CHR$(COLS%(1+((trackpos + realdepth)/1.5 DIV framespersection%) MOD 2))+CHR$(157)
11400       ROAD$=CHR$(156)
11420       LEFT%=mid-(1.7*20-left_wall%(depth%))*(N%-horizonHere%)/20 : REM +1 removed although both LEFT% and RIGHT% will round down
11440       RIGHT%=mid+1.7*(20-right_wall%(depth%))*(N%-horizonHere%)/20
11460       IF LEFT%<1 THEN PRINTTAB(0,N%);ROAD$ ELSE PRINTTAB(0,N%);SCENERY$; : REM dont print scenery if left=0 , cos 1byte road then make white!
11480       IF LEFT%>=0 AND LEFT%<38 THEN PRINT TAB(LEFT%,N%);ROAD$;
11500       IF RIGHT%<1 THEN RIGHT%=1
11520       IF RIGHT%<40 THEN PRINTTAB(RIGHT%-1,N%);SCENERY$;
11540       REM &7C00!(40*N%)=SCENERY
11560       mid = mid + dang%(depth%)*7/(N%-horizonHere%+1)
11580     NEXT
11600     OLDY%=Y%-1
11620   NEXT

RUN

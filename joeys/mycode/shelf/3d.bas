10000 MODE 7

10040 maxlines% = 20
10060 DIM endx%(maxlines%,2)
10080 DIM endy%(maxlines%,2)
10100 DIM linec%(maxlines%)

## we want to refer to vertices but they are shared by edges
## should we use pointer dereferencing when building the list of lines-to-render, or copy the values over?
## or should we do it all on the fly, no need to build the list!

10220 REM A pyramid:
10240 REM endy(i,0) is always lower on the screen (higher in value) than endy(i,1)
10260 lines%=5
10280 endx%(0,0)=20 : endy%(0,0)=23 : endx%(0,1)=12 : endy%(0,1)=18 : linec%(1)=6
10300 endx%(1,0)=12 : endy%(1,0)=18 : endx%(1,1)=18 : endy%(1,1)=4 : linec%(1)=6
10320 endx%(2,0)=20 : endy%(2,0)=23 : endx%(2,1)=18 : endy%(2,1)=4 :linec%(2)=4
10340 endx%(3,0)=34 : endy%(3,0)=19 : endx%(3,1)=18 : endy%(3,1)=4 :linec%(3)=0
10360 endx%(4,0)=20 : endy%(4,0)=23 : endx%(4,1)=34 : endy%(4,1)=19 :linec%(4)=0

10400 PROCdrawscene

10400 END

10440 DEF PROCdrawscene
10460 FOR Y%=0 TO 24
10480   PROCdrawLine
10500 NEXT
10520 ENDPROC

10560 DEF PROCdrawLine
# 10580   X%=0
# 10600   REM for each intersection-point on this line, in order from left to right
# 10620   REM # actually it doesn't matter what order we print them in, as long as no two overlap
# 10640   REM # although if we had a "default" screen char, we could peek to see whether we are overlapping something
# 10660   REM   if NextLine is too close to current
# 10680   REM     dealWithTooCloseCase
# 10700   REM   else
# 10720   REM     change bg at this point
# 10740   REM next
10760   FOR line%=0 TO lines%-1
10000     PRINTTAB(0,0)line%
10780     IF Y%>=endy%(line%,1) AND Y%<=endy%(line%,0) THEN PROChitLine
10800   NEXT
10820 ENDPROC
10840 DEF PROChitLine
REM 10860   Line is defined as (x,y) = (x0,y0) + thru*((x1,y1)-(x0,y0))
REM 11111   TODO: too much dereferencing!
10880   thru%=Y%-endy%(line%,1)
10900   X% = endx%(line%,1) + thru%*(endx%(line%,0)-endx%(line%,1))/(endy%(line%,0)-endy%(line%,1))
REM 10920   ?(&7C00+X%+40*Y%) = 254 + 0.5
REM 10920   PRINTTAB(0,line%)X%,Y%
10920   ?(&7C00+X%+40*Y%) = ASC("0")+line%
10940 ENDPROC

10980 DATA "Object Pyramid1"
11000 DATA "  Offset 64,64,0"
11020 DATA "  V a 0,0,75"
11040 DATA "  V b -32,+32,0"
11060 DATA "  V c 0,-45,0"
11080 DATA "  V d +32,+32,0"
11100 DATA "  S 4 c b a"
11120 DATA "  S 0 c a d"
11140 DATA "  L 4 cb  L 4 ba   L 0 ca  L -1 da  L -1 dc"

11180 DATA "Object Cylinder1"
11200 DATA "  Col 0"
11220 DATA "  Offset 32,82,0"
11240 DATA "  Bottom 0 Top 92 Radius 22"

RUN


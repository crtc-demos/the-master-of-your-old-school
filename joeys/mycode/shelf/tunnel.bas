REM vim: noexpandtab ts=2 sw=2 wrap listchars=tab:| ,trail:% showbreak=::::::::

REM We might want to ensure every char is returned to 0 after it has been used.
REM But in this case, our default char doesn't have to be 0.  We could make it
REM 255, or the alternating paattern 160+1+8+16, 160+2+4+64

10080 MODE 7
10090 VDU 23,1,0,0,0,0,0,0,0,0
10100 :
10110 nearDepth% = 4
10120 farDepth% = 160
10130 squareWidth% = 60
10140 squareHeight% = 40
10150 :
REM 10740 FOR Y%=0 TO 24
REM 10750 : ?(&7C00+Y%*40) = 147
REM 10760 NEXT
10190 :
10190 depth% = farDepth%
10190 col% = 0
10190 REPEAT
10200 : deltax% = -100 * SIN(PI*1.4*depth%/farDepth%)
10210 : deltay% = deltax% * 25/40
10220 : scale = nearDepth%/depth%
10220 : scrx% = deltax%*scale
10230 : scry% = deltay%*scale
REM 10200 : CLS
10240 : PROCplotSquare(20+scrx%-squareWidth%*scale,20+scrx%+squareWidth%*scale,12+scry%-squareHeight%*scale,12+scry%+squareHeight%*scale,col%)
10260 : PRINTTAB(0,0);depth%;"   ",scale
REM 10250 : depth% = depth% - 1
REM 10260 : IF depth% < 1 THEN depth% = farDepth% : col% = col% EOR 255
10250 : depth% = depth% + 1
10260 : IF depth% > farDepth% THEN depth% = nearDepth% : col% = col% EOR 255
10270 UNTIL FALSE
10280 :
10290 END

10310 DEF PROCplotSquare(left%,right%,top%,bottom%,col%)
10310 : IF left%<0 THEN left%=0
10310 : IF top%<0 THEN top%=0
10310 : IF right%>39 THEN right%=39
10310 : IF bottom%>25 THEN bottom%=25
10320 : topleftloc% = &7C00 + left% + top%*40
10330 : toprightloc% = &7C00 + right% + top%*40
10340 : bottomleftloc% = &7C00 + left% + bottom%*40
10350 : bottomrightloc% = &7C00 + right% + bottom%*40
10360 : FOR loc%=topleftloc% TO toprightloc% : ?loc% = col% : NEXT
10370 : FOR loc%=bottomleftloc% TO bottomrightloc% : ?loc% = col% : NEXT
10380 : FOR loc%=topleftloc% TO bottomleftloc% STEP 40 : ?loc% = col% : NEXT
10390 : FOR loc%=toprightloc% TO bottomrightloc% STEP 40 : ?loc% = col% : NEXT
10400 ENDPROC
REM 10890 : ?(&7C00 + x% + y%*40) = 255

RUN

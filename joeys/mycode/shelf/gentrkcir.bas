REM vim: expandtab ts=2 sw=2

#define MAX 16

10140 MODE 4
10180 :
10180 DIM amp%(MAX)
10200 DIM freq(MAX)
10220 DIM phase(MAX)
10240 REM Place of peaking
10260 REM Width of peak
10280 :
10300 FOR i%=1 TO MAX
10320 	amp%(i%) = 420*RND(1) / i%
10360 	freq(i%) = (RND(1)*i% + 1) DIV 1
10340 	phase(i%) = 2*PI * RND(1)
10340 	PRINT i%;" ";amp%(i%);" ";freq(i%);" ";phase(i%)
10380 NEXT
10400 :
REM 10420 MOVE 640,480
REM 10420 PLOT 4,640,480
10440 :
11111 first%=TRUE
10460 FOR t=0 TO 2*PI STEP PI/8
10480 	x% = 640 : y% = 512
10500 	FOR i%=1 TO MAX
10520 		x% = x% + amp%(i%) * SIN(phase(i%) + t*freq(i%))
10540 		y% = y% + amp%(i%) * COS(phase(i%) + t*freq(i%))
10560 	NEXT
REM 10580 DRAW x%,y%
10580 	IF first% THEN MOVE x%,y% : first%=FALSE ELSE PLOT 5,x%,y%
10600 NEXT
10620 :
10640 END
10660 :
10660 
10660 

RUN


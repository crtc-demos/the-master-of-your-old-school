REM Wander real and take the sine.  wander another sine using the previous.
REM and again.  we creat we created a very nice smoothly wobbling curve with
REM changing period.  plot it vertically in mode 7 like yum :)

REM Use a simple horizontal per-line grid pattern to make this value the
REM depth/distance rather than width

0000 MODE 7
0000 :
0000 angle=0
0000 :
0000 REPEAT
0000   angle=angle+2*PI/137.0
0000   x% = 20+18*SIN(angle)
0000   PRINTTAB(x%,24);"#"
0000 UNTIL FALSE
0000 

RUN


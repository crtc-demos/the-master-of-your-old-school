  10010 REM MODE 4 pixel scroller
  10020 :
  10030 MODE 7
  10040 numlines%=2
  10050 PROCassemble
  10060 K$=GET$
  10070 MODE 4
  10080 FOR line%=0 TO numlines%-1
  10090 PRINTTAB(0,line%);CHR$(141);"Hello this is Joey's scroller"
  10100 NEXT
  10110 *FX 14,4
  10120 !framecounter=0
  10130 starttime=TIME
  10140 CALL start
  10150 REPEAT
REM 10300   CALL event : CALL event : CALL event : CALL event : REM For jbeeb, which doesn't handle interrupts!
REM 10320   CALL event : CALL event : CALL event : CALL event : REM For jbeeb, which doesn't handle interrupts!
  10180   spenttime=TIME-starttime
  10190   frames=!framecounter
  10200   REM IF spenttime>0 THEN PRINT TAB(0,numlines%); "spenttime="; spenttime; " frames="; frames; " fps="; frames/(spenttime/100)
  10210   IF spenttime>0 THEN PRINT TAB(0,numlines%); "fps="; frames/(spenttime/100)
  10220 UNTIL FALSE
  10230 END
  10240 :
  10250 DEF PROCassemble
  10260 DIM code 2400
  10270 eventlo=0 : eventhi=0
REM &70,71 unused
REM &72,73 we save the original event address here so we can call it when our event is done.
  10300 framecounter=&74+numlines%
  10310 FOR I%=1 TO 3 STEP 2
  10320 P%=code
  10330 [OPT I%
  10340 .start
  10350 LDA &220        ; redirect the event vector
  10360 STA &72
  10370 LDA &221
  10380 STA &73
  10390 LDA #eventlo
  10400 STA &220
  10410 LDA #eventhi
  10420 STA &221
  10430 RTS
  10440 .event
  10450 PHP ; save registers; not sure if this really needed
  10460 PHA
  10470 TXA
  10480 PHA
  10490 TYA
  10500 PHA
  10510 ]
  10640 FOR line%=0 TO numlines%-1
  REM This is the largest batch, pretty daft to be on the outside.
  REM 10650 FOR row%=0 TO 7
  10650 left=&5800+40*8*line% : REM +row%
  10660 [OPT I%
  10670 LDX #7
  10670 .loop
  10670 LDA left,X           ; get the
  10670 ROL A                ; lead bit
  10670 ]
REM Nasty but fast method.  Create a lot of code!
  10670 FOR char%=39 TO 0 STEP -1
  10660 [OPT I%
  10670 ROL left+char%*8,X
REM Now that we have started using ,X we may as well have a pointer for the current batch :P
REM Is there any point dynamically updating the location bytes which get assembled here?
REM Or would (&80),X be just as fast as &7C00,X ?
  10690 ]
  10700 NEXT
  10660 [OPT I%
  10670 DEX
  10670 BPL loop
  10660 ]
REM This produces a 40 command block which we call 8 times.
REM But if we want to produce less code, we could loop X 256 times.  Then another 64, to do the same.
  REM 10700 NEXT
  10700 NEXT
  10830 [OPT I%
  10840 LDX framecounter     ; frame count - accumulator snubbed
  10850 INX
  10860 STX framecounter
  10870 CPX #0
  10880 BNE leave
  10890 LDX framecounter+1
  10900 INX
  10910 STX framecounter+1
  10920 .leave
  10930 PLA
  10940 TAY
  10950 PLA
  10960 TAX
  10970 PLA
  10980 PLP
  11010 JMP (&72)
  11020 ]
  11030 eventlo=event MOD 256
  11040 eventhi=event DIV 256
  11050 NEXT I%
  11060 ENDPROC

RUN

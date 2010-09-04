  10010 REM Four line scroller on screen refresh interrupt
  10020 :
  10030 MODE 7
  10040 numlines%=20
  10050 PROCassemble
  10060 K$=GET$
  10070 MODE 7
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
  10260 DIM code 400
  10270 eventlo=0 : eventhi=0
REM &70,71 unused
REM &72,73 we save the original event address here so we can call it when our event is done.
  10300 framecounter=&74+numlines%
  10310 FOR I%=0 TO 3 STEP 3
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
  10520 FOR line%=0 TO numlines%-1
  10530 left=&7C00+40*line%
  10540 [OPT I%
  10550 LDA left+1   ; copy the leftmost chars somewhere temporary
  10560 STA &74+line%
  10570 ]
  10580 NEXT
  10590 [OPT I%
REM 10780 LDA #65
  10610 LDX #1
  10620 .loop
  10630 ]
  10640 FOR line%=0 TO numlines%-1
  10650 left=&7C00+40*line%
  10660 [OPT I%
  10670 LDA left+1,X   ; move the char back one
  10680 STA left,X
  10690 ]
  10700 NEXT
  10710 [OPT I%
  10720 INX
  10730 CPX #39
  10740 BNE loop
  10750 ]
  10760 FOR line%=0 TO numlines%-1
  10770 left=&7C00+40*line%
  10780 [OPT I%
  10790 LDA &74+line%              ; put the temporary chars on the right
  10800 STA left+39
  10810 ]
  10820 NEXT
  10830 [OPT I%
  10840 LDX framecounter     ; frame count!
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

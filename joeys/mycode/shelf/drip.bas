REM vim: noexpandtab ts=2 sw=2 wrap listchars=tab:| ,trail:% showbreak=::::::::

REM FIXED: Occasionally some text chars get displayed as gfx for a moment.
REM Added nasty fix to deal with DIV3 and -1 problem.
REM This fixed problems occurring with the top line, because neighbours DIV3
REM appear to be at 0, not negative!
REM An alternative fix would be to add+1 before doing any comparisons with DIV3.
REM Anyway there is still a control-char bug!
REM OK all gone.  It wasn't really a plotting bug, just the frame was blitting
REM while BASIC was only halfway through the update.
REM Don't you think it's cruel to kill a bug without at least fully documenting
REM it's behaviour?

REM cx%,cy% are screen/char coords (1-39,0-24).  (We must reserve the 0th char
REM         for gfx-control-char.)
REM dx%,dy% are in drip space (0-77,0-74)
REM tdy% is the top drip y in our char
REM px% is "partner drip", the drip we share our char with
REM bx% is "brother drip" or "neighbouring drip"

REM It looks a bit odd that text can touch the drips vertically but never
REM horizontally (due to the mode-switching char spacing them).
REM We could clear vertical chars unneccessarily early, to make vertical
REM spacing of text from drip look similar to horizontal spacing.

REM TODO: We have not dealt with end-case.  We should not target the trailing
REM drips directly, but wait for them to fall at the same speed they were
REM before.  (This might require stalling when not doing a finished drip,
REM rather than returning immediately, to simulate the time that would have
REM passed had we needed to calculate it.  If we do a set number of calcs per
REM interrupt, then np that's already solved.)

REM We could reduce the number of neighbour comparisons, if we stored and updated
REM a second half-size array containing max(pair).  This only needs to be updated
REM when we moved into a new row.  rowReached%(39)

REM The loc and leftloc in asm are daft.  Nicest way might be lineLoc and vary
REM Y for column.

REM one solution to the -1 problem.  start all drips at 2, calc loc using
REM 7c00-1line+...  This will let us remove all the daft CMP #255s.
REM Too bad I didn't realise this solution *before* porting to asm.  :P

REM VDU 21

10370 MODE 7
10380 VDU 23,1,0,0,0,0,0,0,0,0
REM Nearly not awful (1-line recursion for beginners): 10150 ON ERROR VDU 23,1,1,0,0,0,0,0,0,0 : PRINT ERR$;" at line ";ERRNUM
10400 :
10410 DIM bits%(2,3)
10420 DIM dys%(78)
10430 :
10440 DIM code 2048
10450 DIM bits 6
10460 DIM dys 78
10470 animEntry=0 : REM Will be set later.
10480 getrandom = 0 : REM Will be set later.
10490 myseed=&8A
10500 PROCassemble
10510 CLS
10520 ?myseed = 9
10530 FOR I%=0 TO 10
10540 : CALL getrandom
10550 : PRINT A%,?myseed
10560 NEXT
10570 :
10580 bits%(0,0) = 32+128 + 1
10590 bits%(1,0) = 32+128 + 2
10600 bits%(0,1) = 32+128 + 4
10610 bits%(1,1) = 32+128 + 8
10620 bits%(0,2) = 32+128 + 16
10630 bits%(1,2) = 32+128 + 64
10640 bits?0 = 160+1
10650 bits?1 = 160+2
10660 bits?2 = 160+4
10670 bits?3 = 160+8
10680 bits?4 = 160+16
10690 bits?5 = 160+64
10700 FOR i%=0 TO 77
10710 : dys%(i%) = -1 : REM -5 : REM For left/right comparisons for the first row only, -1 was not enough, when using DIV3 turns it into 0!
10720 : dys?i% = 255
10730 NEXT i%
10740 :
REM 10740 FOR Y%=0 TO 24
REM 10750 : REM ?(&7C00+Y%*40) = 149
REM 10760 : FOR X%=0 TO 39
REM 10770 : : IF RND(1)<0.7 THEN ?(&7C00+Y%*40+X%) = 65+RND(1)*61
REM 10780 : NEXT X%
REM 10790 NEXT Y%
10810 :
10820 REPEAT
10830 : REM PROCanimoneBasic
10840 : PROCanimoneMachine
10850 UNTIL FALSE
10860 END

10880 DEF PROCanimoneMachine
10890 : FOR rep%=1 TO 16
10890 : : CALL animEntry
10890 : NEXT rep%
10890 : PRINTTAB(0,15);"dx=";?dx;" dy=";?dy;"    "
10890 : PRINTTAB(0,16);"cy=";?cy;" tdy=";?tdy;" cyr=";?cyr;"    "
10890 : PRINTTAB(0,17);"loc=";(((!locLO AND &FFFF)-&7C00)MOD40);",";(((!locLO AND &FFFF)-&7C00)DIV40);"    "
10890 : PRINTTAB(0,18);"numA=";?numA;" numB=";?numB;" numC=";?numC;"    "
10900 ENDPROC

10920 DEF PROCanimoneBasic
REM 10870 : dx% = RND(1)*78
10940 : REPEAT
10950 : : CALL getrandom
10960 : : dx% = (?myseed AND 127)
10970 : UNTIL dx%<78
10980 : dy% = dys%(dx%)
REM 10380 : IF dy%=-5 THEN dy%=-1 : REM Needed for the naff fix for the DIV3 problem :P
11000 : dy% = dy%+1
11010 : dys%(dx%) = dy%
11020 : REM PRINTTAB(dx%/2,dy%/3);"#";
11030 : REM IF (dx% MOD 2)=0 THEN PRINTTAB(1+dx%/2,dy%/3);"#";
11040 : cy% = dy% DIV 3 : REM cy% is re-used little
11050 : tdy% = cy% * 3 : REM tdy% is re-used a lot for neighbour comparisons
11060 : loc% = (&7C01 + (dx% DIV 2) + 40*cy%)
11070 : bit% = bits%(dx% MOD 2, dy% MOD 3)
REM : Our partner drop may be above us or already here.
11090 : pdx% = dx% EOR 1
11100 : pdy% = dys%(pdx%)
REM : We are about to change the screen.  Let's get some spare time!
REM : This doesn't solve the bug, which shouldn't appear anyway since we now
REM : prepare checkRight first.
REM 10485 : *FX 19
REM : If we have now entered a new char, we should clear it to 0.
REM : If we are one of the first drips to enter this row, we may need to set
REM : gfx-control-char on our left, and back-to-txt control char on our right.
11180 : IF (dy% MOD 3) = 0 AND pdy%<dy% THEN PROCcheckRight : PROCcheckLeft : ?loc% = 0 :
REM NOTE: I initially put the clear to 0 at the start, but those PROCs are
REM slow, so the clear happens closer to the other changes if it comes last!
REM This produces a tiny risk of showing the un-cleared char in gfx mode before
REM we return and clear.  But when it was at the start, the slowness made the
REM risk greater, and the effect was very occasionally clearing a 149 (breaking
REM a large chunk of the row!) before adding the new 149 with checkLeft.
11250 : ?loc% = (?loc%) OR bit%
11260 ENDPROC

13150 DEF PROCcheckLeft
13160 : IF dx% < 2 THEN ?(loc%-1) = 149 : ENDPROC
13170 : REM : Get the two drips in the char before ours.
13180 : bx% = ((dx% DIV 2) - 1)*2
13190 : REM : Has a drip in the char before us already dealt with gfx-control-char?
13200 : IF dys%(bx%) >= tdy% THEN ENDPROC
13210 : IF dys%(bx%+1) >= tdy% THEN ENDPROC
13220 : ?(loc%-1) = 149
13230 ENDPROC
13240 DEF PROCcheckRight
REM : We must check all 4 drips in the next 2 chars, to avoid overwriting
REM : existing drip, or existing 149 needed for drips in second char.
13270 : IF dx% >= 76 THEN ENDPROC
REM : Let's look at the next char after ours.
13290 : bx% = ((dx% DIV 2) + 1)*2
REM : Is there a drip immediately after us?
13310 : IF dys%(bx%) >= tdy% THEN ENDPROC
13320 : IF dys%(bx%+1) >= tdy% THEN ENDPROC
REM : If we are on char 38, We can't check our second next char, so we clear.
13340 : IF dx% >= 74 THEN ?(loc%+1) = 135 : ENDPROC
REM : Is there a drip in char after that, who needs his gfx-control-char left alone?
13360 : IF dys%(bx%+2) >= tdy% THEN ENDPROC
13370 : IF dys%(bx%+3) >= tdy% THEN ENDPROC
REM : No. OK then let's switch back to text mode
13390 : ?(loc%+1) = 135
13400 ENDPROC

11280 DEF PROCassemble
11290 FOR I%=0 TO 3 STEP 3
11300 P%=code
11310 dx=&80 : dy=&81 : cy=&82 : tdy=&83 : cyr=&84
11320 locLO=&86 : locHI=&87
11330 numA=&88 : numB=&89 : numC=&85
11340 myseed=&8A
11320 leftlocLO=&8B : leftlocHI=&8C
11350 [OPT I%

11370 .animEntry
11380 JSR getrandom   ; loop until we get a nice random number
REM 11390               RTS      ; DEBUGGING
11400 AND #127
11410 CMP #78
11420 BCS animEntry
11430 STA dx
11440 TAX
11450 INC dys,X
11460 LDA dys,X
11470 STA dy
11490 STA numA
11500 LDA #3
11510 STA numB
11520 JSR divide8
11530 STA cyr
11540 LDA numA
11550 STA cy
11560 STA numA
REM TODO: make quick fn multiply8_by_3
REM 11500 LDA #3
REM 11510 STA numB
11580 JSR multiply8
11590 STA tdy
REM Location bad not finished
REM 11530 LDA #&7C
REM 11540 STA locHI
REM 11550 LDA #&01
REM 11560 STA locLO
REM 11570 LDA dx
REM 11580 ROR A
REM 11590 CLC
REM 11600 ADC locLO
REM 11600 STA locLO
REM 11610 BCC animSkip0
REM 11620 INC locHI
REM 11630 .animSkip0
REM Location better but still not finished
REM 11111 LDA dx
REM 11111 ROR A
REM 11111 CLC
REM 11111 ADC #&01
REM 11111 STA locLO
REM 11111 LDA #0
REM 11111 ADC #&7C
REM 11111 STA locHI
REM Location might work
11830 LDA dx
11840 CLC
11840 ROR A
11850 CLC
11860 ADC #&01
11870 STA locLO
11880 LDA #40
11890 STA numA
11900 LDA cy
11910 STA numB
11920 JSR multiply8to16
11930 CLC
11940 ADC locLO
11950 STA locLO
11960 LDA #&7C
11970 ADC numC
11980 STA locHI
REM dy MOD 3 = 0 ?
12070 LDA cyr
12080 CMP #0
12090 BNE updateDripChar
REM leftloc
11111 SEC
11111 LDA locLO
11111 SBC #2
11111 STA leftlocLO
11111 LDA locHI
11111 SBC #0
11111 STA leftlocHI
REM pdy<dy ?
12000 LDA dx
12010 EOR #1
12020 TAX
12030 LDA dys,X           ; pdy
REM This was causing crash before we fixed leftloc
12040 CMP #255
12040 BEQ processNewChar
12040 CMP dy
12050 BCC processNewChar
12050 JMP updateDripChar
REM The conquest of a new char!
12100 .processNewChar
12100 JSR checkRight
12110 JSR checkLeft
12120 LDA #0
12130 LDY #0
12140 STA (locLO),Y
12150 .updateDripChar
REM get bitmask
12170 LDA dx
12180 AND #1
12190 ROR A
12200 LDA cyr             ; dy MOD 3
12210 ROL A
12220 TAX
12230 LDA bits,X
12240 LDY #0
12250 ORA (locLO),Y
12260 STA (locLO),Y
12270 .animLeave
12280 JMP animEntry
12280 RTS

12300 .checkLeft
11111 LDA dx
11111 CMP #2
11111 BCC skipLeft
REM 11111 LDA dx
11111 CLC
11111 ROR A
11111 SEC
11111 SBC #1
11111 CLC
11111 ROL A
REM This is bx
11111 TAX
11111 LDA dys,X
11111 CMP #255
11111 BEQ tooFatLeft1
11111 CMP tdy
11111 BCS leaveLeft
11111 .tooFatLeft1
11111 LDA dys+1,X
REM 11111 INX
REM 11111 LDA dys,X
11111 CMP #255
11111 BEQ tooFatLeft2
11111 CMP tdy
11111 BCS leaveLeft
11111 .tooFatLeft2
11111 .skipLeft
11111 LDA #149
11111 LDY #1
11111 STA (leftlocLO),Y
11111 .leaveLeft
12310 RTS

12320 .checkRight
11111 LDA dx
11111 CMP #76
11111 BCS leaveRight
REM won't be: 11111 CLC
11111 ROR A
11111 CLC
11111 ADC #1
REM won't be: 11111 CLC
11111 ROL A
REM This is bx
11111 TAX
11111 LDA dys,X
11111 CMP #255
11111 BEQ tooFatRight1
11111 CMP tdy
11111 BCS leaveRight
11111 .tooFatRight1
11111 LDA dys+1,X
11111 CMP #255
11111 BEQ tooFatRight2
11111 CMP tdy
11111 BCS leaveRight
11111 .tooFatRight2
11111 TXA
11111 CMP #74
11111 BCS skipRight
11111 LDA dys+2,X
11111 CMP #255
11111 BEQ tooFatRight3
11111 CMP tdy
11111 BCS leaveRight
11111 .tooFatRight3
11111 LDA dys+3,X
11111 CMP #255
11111 BEQ tooFatRight4
11111 CMP tdy
11111 BCS leaveRight
11111 .tooFatRight4
11111 .skipRight
11111 LDA #135
11111 LDY #3
11111 STA (leftlocLO),Y
11111 .leaveRight
12330 RTS

12350 .getrandom
12360 LDA myseed
REM 11190 AND #3
REM 11200 TAX
REM 11210 ROR A           ; get a random carry for the ROR later
REM 11220 LDA &FE64,X
12410 LDA &FE64
REM 11220 EOR &FE65           ; a bit extra, but can be skipped
12430 EOR myseed
REM 11240 ROR A
12450 STA myseed
12460 RTS

12480 .multiply8
REM numA and numB are the numbers, numA will be destroyed
12500 LDA #0
12510 LDX #8
12520 .multLoop0
12530 ROL numA                 ; efficiency hack
12540 BCS multJumpIn
12550 DEX
12560 BNE multLoop0
12570 JMP multOut
12580 .multLoop
12590 ROL A
12600 ROL numA
12610 BCC skip
12620 .multJumpIn
12630 CLC
12640 ADC numB
12650 .skip
12660 DEX
12670 BNE multLoop
12680 .multOut
REM 12690 STA result
REM A contains the multiple
12710 RTS

12730 .multiply8to16
REM numA and numB are the numbers, numA will be destroyed
12750 LDA #0
12760 STA numC
12770 LDX #8
12780 .m816Loop
12790 CLC
12790 ROL numC
REM numC can't overflow so this isn't needed: 12790 CLC
12790 ROL A
12810 BCC skipm816a
12810 CLC
12810 INC numC
12810 .skipm816a
12800 ROL numA
12810 BCC skipm816b
12820 CLC
12830 ADC numB
12840 BCC skipm816b
12850 INC numC
12860 .skipm816b
12870 DEX
12880 BNE m816Loop
REM A=lo, hi is in numC tidy huh? :P
REM 12890 STA numB
12910 RTS

12930 .divide8
REM Will calculate numA/numB, numA will be destroyed
12950 LDA #0
12960 LDX #8
12970 ASL numA
12980 .divLoop
12990 ROL A
13000 CMP numB
13010 BCC divSkip
13020 SBC numB
13030 .divSkip
13040 ROL numA
13050 DEX
13060 BNE divLoop
REM numA contains result, A containers remainder
13080 RTS

13100 ]
13110 NEXT I%
REM 13020 K$=GET$
13130 ENDPROC

VDU 0,0,0,0,0,0,0,0
VDU 6
VDU 0,0,0,0,0,0,0,0
PRINT
PRINT
PRINT
PRINT
PRINT
PRINT
PRINT
PRINT

RUN


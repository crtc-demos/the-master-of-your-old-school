> MODE 7
; : PRINT "Loading..." : VDU 21

MODE 0

DIM envparams%(14+4)
editingKeys$="12QWEASDZXCVFGRTYU"

X%=RND(TIME)
FOR X%=1 TO 14+4
REM 10160   envparams%(X%)=0
  envparams%(X%)=RND(256)
NEXT

/*
*/
envparams%(1)=1
envparams%(2)=1
:
envparams%(3)=+1
envparams%(4)=-2
envparams%(5)=0
envparams%(6)=18
envparams%(7)=24
envparams%(8)=99
envparams%(9)=+8
envparams%(10)=-1
envparams%(11)=012
envparams%(12)=-4
:
envparams%(13)=126
envparams%(14)=90
envparams%(15)=1
envparams%(16)=1
envparams%(17)=140
envparams%(18)=20

PROCdrawParams

REPEAT

  *SPOOL LAST
  PRINT "ENVELOPE ";envparams%(1);",";envparams%(2);",";envparams%(3);",";envparams%(4);",";envparams%(5);",";envparams%(6);",";envparams%(7);
  PRINT ",";envparams%(8);",";envparams%(9);",";envparams%(10);",";envparams%(11);",";envparams%(12);",";envparams%(13);",";envparams%(14)
  PRINT "SOUND ";envparams%(15);",";envparams%(16);",";envparams%(17);",";envparams%(18)
  *SPOOL

  ENVELOPE envparams%(1), envparams%(2), envparams%(3), envparams%(4), envparams%(5), envparams%(6), envparams%(7), envparams%(8), envparams%(9), envparams%(10), envparams%(11), envparams%(12), envparams%(13), envparams%(14)

  ; SOUND &1000+envparams%(15),0,0,0   ; Flush current sound
  ; Flush all currently playing sounds
  SOUND &1000,0,0,0
  SOUND &1001,0,0,0
  SOUND &1002,0,0,0
  SOUND &1003,0,0,0
  SOUND envparams%(15), envparams%(16), envparams%(17), envparams%(18)

  K=GET

  row%=1
  REM Is user asking to change a param?
  REM PRINT "You typed "; K; " = "; N%; " "
  N%=INSTR(editingKeys$,CHR$(K))
  IF N%<>-1 AND N%<>0 THEN PRINT "Value[";envparams%(N%);"] "; : INPUT newvalue% : envparams%(N%)=newvalue% : PROCdrawParams

  REM Is user asking to do something else?
  IF CHR$(K)="8" THEN PROCdrawGraph(0)
  IF CHR$(K)="9" THEN PROCdrawGraph(1)
  IF CHR$(K)="3" THEN PROCrandomiseEnvelope : PROCdrawParams
  IF CHR$(K)="4" THEN PROCrandomiseSound : PROCdrawParams

UNTIL FALSE
END

:

DEF PROCdrawParams
  CLS : REM PRINTTAB(0,0);
  @%=3
  PRINT

  REM broken
  ;   PRINT "ENVELOPE ";envparams%(1);",";envparams%(2);", ";envparams%(3);",";envparams%(4);",";envparams%(5);", ";envparams%(6);",";envparams%(7);",";envparams%(8);", ";envparams%(9);",";envparams%(10);",";envparams%(11);", ";envparams%(12);",";envparams%(13);",";envparams%(14)
  ;   PRINT "SOUND ";envparams%(15);", ";envparams%(16);", ";envparams%(17);", ";envparams%(18)
  ;   PRINT"ENVELOPE:",envparams%(1),envparams%(2),envparams%(3),envparams%(4),envparams%(5),envparams%(6),envparams%(7),envparams%(8),envparams%(9),envparams%(10),envparams%(11),envparams%(12),envparams%(13),envparams%(14)
  ;   PRINT"SOUND:",envparams%(15),envparams%(16),envparams%(17),envparams%(18)
  ;   PRINT

  PRINT "ENVELOPE"
  REM PRINT "  ["; MID$(editingKeys$,1,2);  "]  " , envparams%(1);"," , envparams%(2)
  PRINT "            "; FNshowparam(1,"#");"  ";FNshowparam(2,"speed")
  PRINT "  dpitch:   "; FNshowparam(3,"section1");"   ";FNshowparam(4,"section2");"   ";FNshowparam(5,"section3")
  PRINT "  duratn:   "; FNshowparam(6,"section1");"   ";FNshowparam(7,"section2");"   ";FNshowparam(8,"section3")
  PRINT "  damplt:   "; FNshowparam(9,"attk");"   ";FNshowparam(10,"decy");"   ";FNshowparam(11,"sust");"   ";FNshowparam(12,"rels")
  PRINT "  target:   "; FNshowparam(13,"endattk");"   ";FNshowparam(14,"enddecay")
  PRINT
  PRINT "SOUND"
  PRINT "            "; FNshowparam(15,"channel");"   ";FNshowparam(16,"env/vol");"   ";FNshowparam(17,"pitch");"   ";FNshowparam(18,"duration")
  PRINT
  PRINT "  [8]=DrawPitch [9]=DrawAmplitude"
  PRINT
ENDPROC

DEF PROCrandomiseEnvelope
  FOR i%=3 TO 14
    envparams%(i%)=RND(256)-128
  NEXT i%
ENDPROC

DEF PROCrandomiseSound
  FOR i%=15 TO 18
    envparams%(i%)=RND(256)-128
  NEXT i%
ENDPROC

DEF FNshowparam(N%,S$)
= "[" + MID$(editingKeys$,N%,1) + "] " + S$ + " " + STR$(envparams%(N%))

DEF PROCdrawGraph(drawMode%)
; drawMode% will be one of:
#define PLOT_PITCH drawMode%=0
#define PLOT_AMPLT drawMode%=1
  pitch%=128 : amplitude%=0
  curSection%=1 : curStage%=1
  sectionDone%=0 : sustDone%=0
  FOR X%=0 TO 1280 STEP 4
    t% = X%/4
    IF PLOT_PITCH THEN Y%=256+pitch% ELSE Y%=0+amplitude%
    IF X%=0 THEN MOVE X%,Y%
    IF X%>0 THEN DRAW X%,Y%
    IF PLOT_PITCH THEN pitch% = ( pitch% + envparams%(3+curSection%-1) ) MOD 256 : sectionDone%=sectionDone%+1
    IF PLOT_PITCH THEN IF sectionDone%=envparams%(6+curSection%-1) THEN curSection%=1+(curSection% MOD 3) : sectionDone%=0
    IF PLOT_AMPLT THEN IF curStage%=4 THEN amplitude%=amplitude%+envparams%(12) : IF amplitude%<=0 THEN curStage%=5
    IF PLOT_AMPLT THEN IF curStage%=3 THEN sustDone%=sustDone%+1 : IF sustDone%>envparams%(11) THEN curStage%=4
    IF PLOT_AMPLT THEN IF curStage%=2 THEN amplitude%=amplitude%+envparams%(10) : IF amplitude%=envparams%(14) THEN curStage%=3
    IF PLOT_AMPLT THEN IF curStage%=1 THEN amplitude%=amplitude%+envparams%(9) : IF amplitude%>=envparams%(13) THEN curStage%=2 : amplitude%=envparams%(13)
  NEXT
#undef PLOT_PITCH
#undef PLOT_AMPLT
ENDPROC

; > VDU 6

> *SPOOL

> FOR x%=1 TO 50 : CLS : MODE 7 : PRINT STRING$(40,".");CHR$(6) : NEXT
MODE 7 : PRINT "Running..."

RUN


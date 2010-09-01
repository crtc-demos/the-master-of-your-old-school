REM TODO: "Control codes" atm are unknown.
REM       Therefore we should allow between 0 and inf ControlStrings at any point in the song.
REM       Either in global song, or attached to current bank.
REM       ControlStrings can be any length!  So they can also be used just for comments.

MODE 3

DIM seqBank$(64,3)   : REM the raw note banks

DIM chanPitch%(3)

DIM buffer%(20)

chanPitch%(0)=0
chanPitch%(1)=54 - 12*4
chanPitch%(2)=54 - 12*4
chanPitch%(3)=6

tempo%=3

KEYORDER$="zsxdcvgbhnjmZSXDCVGBHNJMQ2W3ER5T6Y7UI9O0P[=]" : REM This is PC keyboard layout, not Beeb layout!
DRUMSORDER$="+!._#*$@" : REM This is PC keyboard layout, not Beeb layout!

ENVELOPE 1,1, +1,-2,0, +18,+24,+99, +8,-1,+12, -3,126,90

REM Read data
totalBars%=0
READ line$
REPEAT
  FOR chan%=0 TO 3
    seqBank$(totalBars%,chan%)=line$
    READ line$
  NEXT chan%
  totalBars%=totalBars%+1
UNTIL line$ = "#ENDBANKS"

encoding = TRUE
PROCplayBar
PRINT
PRINT "Now testing asm playback ..."
PRINT
OSCLI "EXEC PLAYER"
END

#define ENCODING_ONLY IF encoding THEN

DEF PROCplayBar
  REM Play score
  REM pitch% = 0
  ENCODING_ONLY FH = OPENOUT("M.TRACK")
  FOR bar%=0 TO totalBars%-1
    FOR chan%=0 TO 3
      PRINT seqBank$(bar%,chan%)
    NEXT chan%
    PRINT
    FOR note%=1 TO LEN(seqBank$(bar%,0))
      VDU ASC(".")
      ENCODING_ONLY CB%=0 : bufI%=0
      FOR chan%=0 TO 3
        k$ = MID$(seqBank$(bar%,chan%),note%,1)
        IF k$="" THEN pitch%=-1 ELSE pitch% = INSTR(KEYORDER$,k$) - 1
        IF pitch%<0 THEN vol%=0 ELSE vol%=15 : pitch% = chanPitch%(chan%) + 4*pitch%
        IF chan%=0 THEN pitch%=INSTR(DRUMSORDER$,k$)-1 : vol%=15
        IF chan%=0 AND pitch%<0 THEN vol%=0
        REM SOUND chan%,-vol%,pitch%,2
        REM DONE: Really we should NOT play a sound, to let the previous sound release.  But then how will we keep the timing?
        REM SOUND &HOFC Hold,0,Flush,Channel
        REM If not playing anything, continue playing last note
        IF vol%=0 THEN SOUND &1000+chan%,0,0,0 ELSE SOUND chan%,-vol%,pitch%,tempo%
        ENCODING_ONLY IF pitch%>=0 THEN CB%=CB% OR (2^chan%) : buffer%(bufI%)=pitch% : bufI%=bufI%+1
      NEXT chan%
      ENCODING_ONLY PRINT "Outputting CB=";CB%
      ENCODING_ONLY BPUT #FH,CB%
      ENCODING_ONLY FOR i%=0 TO bufI%-1
        ENCODING_ONLY REM PRINT "Outputting ";buffer%(i%)
        ENCODING_ONLY IF bufI%>0 THEN BPUT #FH,buffer%(i%)
      ENCODING_ONLY NEXT i%
    NEXT note%
    VDU 13
  NEXT bar%
  ENCODING_ONLY CLOSE #FH
ENDPROC

DEF PROCtestSound
 ON ERROR ENDPROC
 REPEAT
   PRINT "Pitch? ";
   INPUT pitch%
   SOUND channel%,-10,pitch%,tempo%
 UNTIL "ESCAPE"="pressed"
ENDPROC

; DATA ".   .   .   .   .   .   .   .   "
; DATA "Z X C V B N M Q Q M N B V C X Z "
; DATA "Q Q Q Q B   B   ZZZZ            "

DRUMSORDER$="+!._#*$@" : REM This is PC keyboard layout, not Beeb layout!

; DATA ".   # . .   #   .   # . .   #   "
DATA ".   # . .   #   .   # . .   #   "
DATA "                                "
DATA "                                "
DATA "                                "
; DATA "                                "

; DATA "#   #   @        #  #   @       "
; DATA "c   c   z c z c   . .           "
; DATA "                                "
; DATA "                                "

; DATA ".   .   !       .   .   !       "
; DATA "Z X C V B N M Q Q M N B V C X Z "
; DATA "c   c   z c z c   . .  "
; DATA "  c c zczc      "

DATA "#ENDBANKS"


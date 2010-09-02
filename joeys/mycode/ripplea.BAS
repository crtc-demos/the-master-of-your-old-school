; Whirlpool effect
; Each dot will have two angles, theta (around), phi (out)

MODE 4

; Double height+width dots?
; #define DOUBLE

#define KEEP_INTERRUPTS
; #define LOOP_IN_FOREGROUND
#define USE_NEW_GETPIXEL
#define KEEP_OLD_LOCS

;; Too slow to be visually recognisable, without sacrificing framerate
; #define MOVE_UPWARDS

#include "asm_common.jpp"
#include "sinLookup.dims"
#include "bitLookup.dims"
#include "lookupLogs2.dims"

; #include "lookupLogs2.calc"   ; Does not work - needs FNchop from phase.BAS
fail%=0
ON ERROR REPORT:PRINT " #";ERR;" at line ";ERL:fail%=1
  IF fail%=0 THEN OSCLI "LOAD L.LOGS "+STR$~(lookupLog)
IF fail% THEN MODE 7:PRINT "Failed to load lookups!":END
ON ERROR REPORT:PRINT " (#";ERR;") at line ";ERL:END

; VDU 19,0,4,0;0;
; VDU 19,1,7,0;0;
; VDU 23,1,0;0;0;0;

PROCassemble

!framecounter=0 : starttime=TIME

CALL init
*FX 14,4

REPEAT
  i% = ?rowI
  PRINTTAB(1,1);maxParts%;" particles  ";
  PRINTTAB(1,2);(TIME-starttime) DIV 100;" s  ";
  PRINTTAB(1,3);(!framecounter)*100 DIV (TIME-starttime);" fps  ";
  PRINTTAB(1,4);maxParts%*(!framecounter)*100 DIV (TIME-starttime);" dps  ";
  PRINTTAB(1,5);" i=";i%;"  theta=";partTheta?i%;"  phi=";partPhi?i%;"   ";
  PRINTTAB(1,6);" wr=";?wr;"  wz=";?wz;"   ";
  PRINTTAB(1,7);" wx=";FNgetSignedByte(?wx);"  wy=";FNgetSignedByte(?wy);"   ";
  PRINTTAB(1,8);" x=";?x;"  y=";?y;"   ";
  REM PRINTTAB(1,5);i%;"/";maxParts%;"  ";
  REM PRINTTAB(1,9);"u=";partU?i%;"  v=";partV?i%;"   ";
UNTIL FALSE

END

DEF PROCassemble

consta=25
topScrpos=&8000 - 40*8*rowsFromBottom% + 4*8
rippleRows% = 16
rowsFromBottom% = 6
scrTop=&5800 + (320-256)/8*8/2
rowI=&80
scrLocLO=&81 : scrLocHI=&82
numA=&83 : numB=&84
delta=&85   ; and &86 HI byte not used but maybe written to!
amp=&87
#ifdef KEEP_INTERRUPTS
  alreadyRunning=&8B
  ?alreadyRunning=0
#endif

FOR I%=0 TO 2 STEP 2
P%=&4000
_resetLabelCounters
[OPT I%

.oldVector
  EQUB 0 : EQUB 0

.framecounter
  EQUB 0 : EQUB 0
  EQUB 0 : EQUB 0

.currentLineDelta
  _repeat(EQUB 0,rippleRows%)

.init
  LDA #22 : JSR OSASCI
  LDA #4 : JSR OSASCI   ; mode 4
  JSR plotMoon
  LDX #0 : STX rowI
  .initLoop
    .spawnParticle
      ; EOR &FE64 : STA partTheta,X
      ; EOR &FE65 : AND #63 : STA partPhi,X
      JSR cacheParticleData
  INC rowI : LDA rowI : CMP rippleRows% : BNE initLoop
  LDA #0 : STA rowI
  .setupIntercept
    _interceptEvent(4,&220,oldVector,myEvent)
RTS

.stop
  LDA #13 : LDX #4 : JSR &FFF4
  _removeEvent(4,&220,oldVector,myEvent)
RTS

.plotMoon
  _print("blah blah test")
RTS

.myEvent

#ifdef KEEP_INTERRUPTS
  LDA alreadyRunning : CMP #1 : BNE doEvent
  JMP skipEvent
  .doEvent
  LDA #1 : STA alreadyRunning
  CLI
#endif

.loopInFg

INC framecounter : BNE skip3 : INC framecounter+1 : .skip3

LDA #0 : STA rowI

LDA #topScrpos MOD 256 : STA scrLocLO
LDA #topScrpos DIV 256 : STA scrLocHI

.mainLoop

  ; TODO
  ; Where should this row be?
  ; delta = (numlines+2-line)*0.3 * SIN(line*consta-parama)
    LDA #rippleRows% : CLC : ADC #2 : SEC : SBC rowI
    STA numA : _multiply8to16(numA,#(255*0.3),null,amp)
    LDX amp : LDA lookupLog,X
    _multiply8to16(rowI,#consta,delta,delta+1)
    CLC : ADC parama   ; got the angle
    TAX : LDA lookupLogOfSin,X
    CLC : ADC logofamp
    TAX : LDA lookupUnlog2,X
    STA delta

  ; Has this row moved?
  ; Left or right?
  ; How many spaces?
  ; OK let's shift it.

  .progress
    INC rowI
    ; BNE mainLoop
    LDA rowI : CMP rippleRows% : BEQ mainLoopOut
    JMP mainLoop
    .mainLoopOut
    LDA #0 : STA rowI

; JMP mainLoop
.outLoop

  #ifdef LOOP_IN_FOREGROUND
    ;; We still make occasional dropouts to allow BASIC to run
    LDA &FE64 : AND #31 : CMP #17 : BEQ dropOutThisOnce
    JMP loopInFg
    .dropOutThisOnce
  #endif

  #ifdef KEEP_INTERRUPTS
    SEI
    LDA #0 : STA alreadyRunning
    .skipEvent
  #endif

RTS

.shiftrowleft
  CLC
  ]
  FOR x%=31 TO 0 STEP -1
  [OPT I%
  LDY #(x%*8)
  ROL (scrLocLO),Y
  ]
  NEXT x%
  [OPT I%
RTS

.shiftrowright
  CLC
  ]
  FOR x%=0 TO 31 STEP +1
  [OPT I%
  LDY #(x%*8)
  ROR (scrLocLO),Y
  ]
  NEXT x%
  [OPT I%
RTS

;; TODO: Throw a bunch of lookups at this

; Given rowI, generate appropriate scrLoc, and return with A=bit to plot there

#ifdef USE_NEW_GETPIXEL

.getpixel
  #include "getPixelMode4.asm"
RTS

#else

.getpixel
  ; A dummy test: LDA #&00 : STA scrLocLO : LDA #&60 : STA scrLocHI
  ; 320x256 pixels available on screen
  ; 25 lines, each 8x40
  ; Y character:
     LDX rowI
     LDA y : TAY : AND #255-7
     ; we could do a lookup of loc here, after dividing by 8
     STA numA : _multiply8to16(numA,#40,numB,numA)
     _add16(#scrTop DIV 256,#scrTop MOD 256,numB,numA,scrLocHI,scrLocLO)
     LDX rowI
  ; Y bar
     ; LDA y : AND #7
     TYA : AND #7
     CLC : ADC scrLocLO : STA scrLocLO
     ;; I believe this skip is guaranteed
     ; BCC skip9 : INC scrLocHI : .skip9
  ; X character:
     LDA x : TAY : AND #255-7       ; Go this far from line-start to reach the right character
     #ifdef KEEP_OLD_LOCS
       CLC : ADC scrLocLO : STA scrLocLO : STA oldLocLO,X
       LDA scrLocHI : ADC #0 : STA scrLocHI : STA oldLocHI,X
     #else
       CLC : ADC scrLocLO : STA scrLocLO : BCC skip8 : INC scrLocHI : .skip8
     #endif
  ; X bit
     ; LDX rowI : LDA x : AND #7
     TYA : AND #7
     TAY   ; Y now contains bit number
     ; CLC : LDA #128 : .bitLoop : DEX : BMI bitLoopOut : ROR A : JMP bitLoop : .bitLoopOut
     ;; Faster as a lookup
     LDA bitLookup,Y
     #ifdef KEEP_OLD_LOCS
       STA oldBit,X
     #endif
RTS

#endif

]
NEXT I%
ENDPROC

DEF FNgetSignedByte(byte%) IF byte%<128 THEN =byte% ELSE =byte%-256

DEF FNrndSign IF RND(1)<0.5 THEN =-1 ELSE =+1


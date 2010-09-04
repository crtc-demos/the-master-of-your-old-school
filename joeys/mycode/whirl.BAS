; Whirlpool effect
; Each dot will have two angles, theta (around), phi (out)

>PAGE=&3000
; >LOMEM=&4000
>NEW

; WARNING: If we compile in MODE 7 then we get the silly bug with crap appearing in the bottom right
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
; #include "sinLookup.dims"
; OSCLI "SAVE L.SIN "+STR$~sinLookup+" +100"
sinLookup = &1A00   ; to &1B00
OSCLI "LOAD L.SIN "+STR$~sinLookup

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

maxParts%=128

PROCassemble

; !framecounter=0
starttime=TIME

CALL init
; *FX 14,4

REPEAT
  i% = ?particleI
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

code=&2500
scrTop=&5800 + (320-256)/8*8/2
particleI=&80
scrLocLO=&81 : scrLocHI=&82
numA=&83 : numB=&84
x=&85 : y=&86
wr=&87 : wz=&88
logwr=&87   ; does not overlap, relabelled for clarity
; wx=x : wy=y   ; since they are never used concurrently
wx=&89 : wy=&8A
#ifdef KEEP_INTERRUPTS
  alreadyRunning=&8B
#endif
numParts=&8C
particleJ=&8D : loopI=&7F
oldVector=&70 ; and &71

FOR I%=0 TO 2 STEP 2
P%=code
_resetLabelCounters
[OPT I%

; .oldVector
  ; EQUB 0 : EQUB 0

#include "bitLookup.asm"

.partTheta
  _repeat(EQUB RND(256),maxParts%)

.partPhi
  #ifdef MOVE_UPWARDS
    _repeat(EQUB RND(256),maxParts%)
  #else
    _repeat(EQUB RND(256)*RND(1)*RND(1),maxParts%)   ; put more particles around the top than the stalk
  #endif

.partSpeed
  _repeat(EQUB 3,maxParts%)   ; +RND(4)

.part_logwr
  _repeat(EQUB RND(256),maxParts%)
.part_wz
  _repeat(EQUB RND(256),maxParts%)

#ifdef KEEP_OLD_LOCS
  .oldLocLO
    _repeat(EQUB 0,maxParts%)
  .oldLocHI
    _repeat(EQUB &80,maxParts%)
  .oldBit
    _repeat(EQUB 0,maxParts%)
#endif

.framecounter
  EQUB 0 : EQUB 0
  EQUB 0 : EQUB 0

.init
  LDA #22 : JSR OSASCI
  LDA #4 : JSR OSASCI
  ; hide cursor
    LDA #23 : JSR OSASCI
    LDA #1 : JSR OSASCI
    LDA #0 : JSR OSASCI
             JSR OSASCI
             JSR OSASCI
             JSR OSASCI
             JSR OSASCI
             JSR OSASCI
             JSR OSASCI
             JSR OSASCI
  LDA #maxParts% : STA numParts
  LDX #0 : STX particleI
  .initLoop
    .spawnParticle
      ; EOR &FE64 : STA partTheta,X
      ; EOR &FE65 : AND #63 : STA partPhi,X
      JSR cacheParticleData
      LDX particleI : LDA #0
      STA oldLocLO,X : STA oldLocHI,X
      STA oldBit,X
  INC particleI : LDA particleI : CMP numParts : BNE initLoop
  LDA #0 : STA particleI
           STA framecounter
           STA framecounter+1
           STA framecounter+2
           STA framecounter+3
  #ifdef KEEP_INTERRUPTS
    LDA #0 : STA alreadyRunning
  #endif
  .setupIntercept
    _interceptEvent(4,&220,oldVector,myEvent)
  LDA #14 : LDX #4 : JSR &FFF4
RTS

.stop
  LDA #13 : LDX #4 : JSR &FFF4
  _removeEvent(4,&220,oldVector,myEvent)
RTS

.cacheParticleData
  ; wr = 120 - 110*sin(partPhi)
    LDX particleI : LDA partPhi,X
    TAY : LDA sinLookup,Y
    STA numA : _multiply8to16(numA,#110,wr,numA)
     LDA #120 : SEC : SBC wr
     ; STA wr
     ; LDY particleI : STA part_wr,Y
     TAX : LDA lookupLog,X : LDY particleI : STA part_logwr,Y
  ; wz = -100 + 110*cos(partPhi)
    LDX particleI : LDA partPhi,X
    CLC : ADC #64   ; do a cos lookup
    TAY : LDA sinLookup,Y
    STA numA : _multiply8to16(numA,#110,wz,numA)
    LDA #100 : SEC : SBC wz
    ; STA wz
    LDY particleI : STA part_wz,Y
RTS

.myEvent

    JSR &0E06

#ifdef KEEP_INTERRUPTS
  LDA alreadyRunning : CMP #1 : BNE doEvent
  JMP skipEvent
  .doEvent
  LDA #1 : STA alreadyRunning
  CLI
#endif

#ifdef MOVE_UPWARDS
LDA #15 : STA loopI
.moveupLoop
  LDA particleJ : STA particleI
  TAX
  DEC partPhi,X
  ; DEC partPhi,X
  ; DEC partPhi,X
  LDA partPhi,X : AND #63 : STA partPhi,X
  JSR cacheParticleData
  INC particleJ
  LDA particleJ : CMP numParts : BNE moveupDone
    LDA #0 : STA particleJ
  .moveupDone
  DEC loopI : BNE moveupLoop
#endif

.loopInFg

INC framecounter : BNE skip3 : INC framecounter+1 : .skip3

LDA #0 : STA particleI

.mainLoop

  .unplot
    #ifdef KEEP_OLD_LOCS
      LDX particleI
      LDA oldLocLO,X : STA scrLocLO
      LDA oldLocHI,X : STA scrLocHI
      LDA oldBit,X
      ; .dounplot
        ; EOR #255   ; get mask = everything except bit
        #ifdef DOUBLE
          TAX
        #endif
        LDY #0 : EOR (scrLocLO),Y : STA (scrLocLO),Y
        #ifdef DOUBLE
          LDA scrLocLO : EOR #1 : STA scrLocLO
          TXA : AND (scrLocLO),Y : STA (scrLocLO),Y
        #endif
    #else
      JSR getpixel   ; BUG: _print("Will not work - must use KEEP_OLD_LOCS")
    #endif

  ; .move
  ; Move particleI
  ; X=particleI right now
    ; INC partTheta,X
    ; INC partTheta,X
    ; INC partTheta,X
    LDA partTheta,X : CLC : ADC partSpeed,X : STA partTheta,X
    ; DEC partPhi,X : BPL noChange
      ; LDA #63 : STA partPhi,X : .noChange

  #define _divideBy2 CLC : ROR A
  #define _invertIfYHigh CPY #128 : BCC P%+7 : SEC : SBC #1 : EOR #255
  #define _postProcessSinLookup _divideBy2 : _invertIfYHigh
  ; Given partTheta,partPhi, determine x,y
    ; NOTE: wr and wz are kinda constants per particle, provided we don't change its partPhi
    LDY particleI : LDA part_logwr,Y : STA logwr
                    LDA part_wz,Y : STA wz
    ; wx = wr * sin(partTheta)
      LDX particleI : LDA partTheta,X
      ; TAY : LDA sinLookup,Y
      ; STA numA : _multiply8to16(numA,wr,wx,numA)
      ; LDA wx : _invertIfYHigh : STA wx
      TAY : LDA lookupLogOfSin,Y
      CLC : ADC logwr : BCS nonZeroX
        LDA #0 : STA wx : JMP resultZeroX
      .nonZeroX
      TAX : LDA lookupUnlog2,X : _invertIfYHigh : STA wx : .resultZeroX
    ; sx = 128 + wx
      LDA wx : CLC : ADC #128 : STA x
    ; wy = wr * cos(partTheta)
      LDX particleI : LDA partTheta,X
      CLC : ADC #64   ; do a cos lookup
      ; TAY : LDA sinLookup,Y
      ; STA numA : _multiply8to16(numA,wr,wy,numA)
      ; LDA wy : CLC : ROR A : CLC : ROR A : STA wy   ; we must divide by 4 prematurely, before we invert
      ; LDA wy : _invertIfYHigh : STA wy
      TAY : LDA lookupLogOfSin,Y
      CLC : ADC logwr : BCS nonZeroY
        LDA #0 : STA wy : JMP resultZeroY
      .nonZeroY
      TAX : LDA lookupUnlog2,X
      CLC : ROR A : CLC : ROR A
      _invertIfYHigh : STA wy : .resultZeroY
    ; ; sy = 128 + wy/4 + wz
      ; LDA wy : CLC : ROR A : CLC : ROR A : CLC : ADC wz : CLC : ADC #128 : STA y
    ; sy = 128 - wy/4 + wz
      LDA #128
      SEC : SBC wy
      ; CLC : ADC wy
      CLC : ADC wz : STA y

  .plot
    #ifdef KEEP_OLD_LOCS
    LDX particleI
    #endif
    JSR getpixel
    #ifdef DOUBLE
      TAX
    #endif
    LDY #0 : EOR (scrLocLO),Y : STA (scrLocLO),Y
    #ifdef DOUBLE
      LDA scrLocLO : EOR #1 : STA scrLocLO
      TXA : EOR (scrLocLO),Y : STA (scrLocLO),Y
    #endif

  .progress
    INC particleI
    ; BNE mainLoop
    LDA particleI : CMP numParts : BEQ mainLoopOut
    JMP mainLoop
    .mainLoopOut
    LDA #0 : STA particleI

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

;; TODO: Throw a bunch of lookups at this

; Given particleI, generate appropriate scrLoc, and return with A=bit to plot there

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
     LDX particleI
     LDA y : TAY : AND #255-7
     ; we could do a lookup of loc here, after dividing by 8
     STA numA : _multiply8to16(numA,#40,numB,numA)
     _add16(#scrTop DIV 256,#scrTop MOD 256,numB,numA,scrLocHI,scrLocLO)
     LDX particleI
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
     ; LDX particleI : LDA x : AND #7
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
  OSCLI "SAVE O.WHIRL "+STR$~code+" "+STR$~P%+" "+STR$~init
  OSCLI "SPOOL I.WHIRL"
  PRINT "start=&";~code;" end=&";~P%;" init=&";~init;" and stop=&";~stop
  OSCLI "CLOSE"
ENDPROC

DEF FNgetSignedByte(byte%) IF byte%<128 THEN =byte% ELSE =byte%-256

DEF FNrndSign IF RND(1)<0.5 THEN =-1 ELSE =+1


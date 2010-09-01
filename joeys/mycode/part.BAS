REM vim: ft=basic expandtab ts=2 sw=2 wrap listchars=tab\:|\ ,trail\:% showbreak=::::::::

; USE THESE SOMEWHERE:
; plot exp( log(x) + log(sin(x)) )
; plot [-10:10] exp( log(1/x) + log(sin(x)) ) 

; #define DOUBLE
#define SPAWN_LEFT
;; SPAWN_MIDDLE looks pretty naff due to integer velocities
; #define SPAWN_MIDDLE

#define KEEP_OLD_LOCS

#define KEEP_INTERRUPTS
#define LOOP_IN_FOREGROUND

MODE 4
VDU 19,0,4,0;0;
VDU 19,1,7,0;0;
VDU 23,1,0;0;0;0;

maxParts%=32

DIM partX maxParts%
DIM partY maxParts%
DIM partU maxParts%
DIM partV maxParts%

#ifdef KEEP_OLD_LOCS
  DIM oldLocLO maxParts%
  DIM oldLocHI maxParts%
  DIM oldBit maxParts%
  FOR i%=0 TO maxParts%-1
    oldLocLO?i% = &00
    oldLocHI?i% = &80
    oldBit?i% = 0
  NEXT
#endif

#include "bitLookup.dims"
#include "asm_common.jpp"

PROCassemble

!framecounter=0 : starttime=TIME

CALL init
*FX 14,4

REPEAT
  i% = ?particleI
  PRINTTAB(1,1);maxParts%;" particles  ";
  PRINTTAB(1,3);(!framecounter)*100 DIV (TIME-starttime);" fps  ";
  PRINTTAB(1,5);maxParts%*(!framecounter)*100 DIV (TIME-starttime);" dps  ";
  PRINTTAB(1,7);(TIME-starttime) DIV 100;" s  ";
  REM PRINTTAB(1,5);i%;"/";maxParts%;"  ";
  REM PRINTTAB(1,7);"i=";i%;"  x=";partX?i%;"  y=";partY?i%;"   ";
  REM PRINTTAB(1,9);"u=";partU?i%;"  v=";partV?i%;"   ";
UNTIL FALSE

END

DEF PROCassemble

scrTop=&5800 + (320-256)/8*8
particleI=&80
scrLocLO=&81 : scrLocHI=&82
numA=&83 : numB=&84
oldVector=&85 : REM and &86
framecounter=&87 : REM and &88,89,8A
#ifdef KEEP_INTERRUPTS
  alreadyRunning=&8B
  ?alreadyRunning=0
#endif
numParts=&8C : ?numParts = maxParts%

FOR I%=0 TO 2 STEP 2
P%=&4000
_resetLabelCounters
[OPT I%

.init
  LDX #0 : STX particleI
  .initLoop
    ; JSR spawnParticle
    LDX particleI
    LDA &FE64 : STA partX,X
    LDA &FE65 : AND #15 : STA partY,X
    LDA #0
    STA partU,X : STA partV,X
  INC particleI : LDA particleI : CMP numParts : BNE initLoop
  LDA #0 : STA particleI
  .setupIntercept
    _interceptEvent(4,&220,oldVector,myEvent)
RTS

.stop
  LDA #13 : LDX #4 : JSR &FFF4
  _removeEvent(4,&220,oldVector,myEvent)
RTS

.spawnParticle
  LDX particleI
  ; LDA #0 : STA partX,X
  ; LDA #230 : STA partY,X
  #ifdef SPAWN_LEFT
    LDA &FE66 : ROR A : ROR A : AND #3 : STA partX,X
    LDA &FE67 : ROR A : ROR A : AND #3 : ADC #240 : STA partY,X
    LDA &FE64 : AND #7 : CLC : ADC #3 : STA partU,X
    LDA &FE65 : AND #15 : ORA #128+64+32+16 : SBC #5 : STA partV,X
  #endif
  #ifdef SPAWN_MIDDLE
    LDA &FE66 : ROR A : ROR A : AND #3 : ADC #126 : STA partX,X
    LDA &FE67 : ROR A : ROR A : AND #3 : ADC #240 : STA partY,X
    LDA &FE64 : AND #3 : CLC : ADC #3 : STA partU,X
    ; 50% of the time we must make the number negative
    LDA &FE64 : ROL A : BCC spawnPositive
    .spawnNegative : LDA partU,X : EOR #255 : STA partU,X : .spawnPositive
    LDA &FE65 : AND #15 : ORA #128+64+32+16 : SBC #5 : STA partV,X
  #endif
  #ifdef KEEP_OLD_LOCS
    LDA #0 : STA oldBit,X   ; We mustn't unplot this particle - next pass will be it's first plot
  #endif
RTS

.myEvent
; CMP #4 : BNE outLoop

  #ifdef KEEP_INTERRUPTS
    LDA alreadyRunning : CMP #1 : BEQ skipEvent
    LDA #1 : STA alreadyRunning
    CLI
  #endif

.loopInFg

INC framecounter : BNE skip3 : INC framecounter+1 : .skip3

.mainLoop

  .unplot
    #ifdef KEEP_OLD_LOCS
      LDX particleI
      LDA oldLocLO,X : STA scrLocLO
      LDA oldLocHI,X : STA scrLocHI
      LDA oldBit,X
    #else
      JSR getpixel
    #endif
    ; EOR #255   ; get mask = everything except bit
    #ifdef DOUBLE
      TAX
    #endif
    LDY #0 : EOR (scrLocLO),Y : STA (scrLocLO),Y
    #ifdef DOUBLE
      LDA scrLocLO : EOR #1 : STA scrLocLO
      TXA : AND (scrLocLO),Y : STA (scrLocLO),Y
    #endif

  ; Move particleI
  .move
    #ifdef DOUBLE
      LDX particleI   ; otherwise redundant
    #endif

    ; test
    ; INC partX,X : INC partY,X : JMP plot

    LDA partX,X : CLC : ADC partU,X : STA partX,X
    #ifdef SPAWN_LEFT
      BCC ok1 : JSR spawnParticle : JMP progress : .ok1
    #endif

    LDA partY,X : CLC : ADC partV,X : STA partY,X
    ; CMP #240 : BCC ok2 : JSR spawnParticle : JMP progress : .ok2
    BCC ok2 : LDA partV,X : BMI ok2 : JSR spawnParticle : JMP progress : .ok2

    ; LDA partV,X : CLC : ADC #1 : STA partV,X
    INC partV,X

  .plot
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
    LDA particleI : CMP numParts : BNE mainLoop
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
; NOTE: This was copied to getPixelMode4 but the ,X optimized version is retained here
.getpixel
  ; A dummy test: LDA #&00 : STA scrLocLO : LDA #&60 : STA scrLocHI
  ; 320x256 pixels available on screen
  ; 25 lines, each 8x40
  ; Y character:
     LDX particleI
     LDA partY,X : TAY : AND #255-7
     ; we could do a lookup of loc here, after dividing by 8
     STA numA : _multiply8to16(numA,#40,numB,numA)
     _add16(#scrTop DIV 256,#scrTop MOD 256,numB,numA,scrLocHI,scrLocLO)
     LDX particleI
  ; Y bar
     ; LDA partY,X : AND #7
     TYA : AND #7
     CLC : ADC scrLocLO : STA scrLocLO
     ;; I believe this skip is guaranteed
     ; BCC skip9 : INC scrLocHI : .skip9
  ; X character:
     LDA partX,X : TAY : AND #255-7       ; Go this far from line-start to reach the right character
     #ifdef KEEP_OLD_LOCS
       CLC : ADC scrLocLO : STA scrLocLO : STA oldLocLO,X
       LDA scrLocHI : ADC #0 : STA scrLocHI : STA oldLocHI,X
     #else
       CLC : ADC scrLocLO : STA scrLocLO : BCC skip8 : INC scrLocHI : .skip8
     #endif
  ; X bit
     ; LDX particleI : LDA partX,X : AND #7
     TYA : AND #7
     TAY   ; Y now contains bit number
     ; CLC : LDA #128 : .bitLoop : DEX : BMI bitLoopOut : ROR A : JMP bitLoop : .bitLoopOut
     ;; Faster as a lookup
     LDA bitLookup,Y
     #ifdef KEEP_OLD_LOCS
       STA oldBit,X
     #endif
RTS

]
NEXT I%
ENDPROC


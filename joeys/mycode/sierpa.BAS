REM vim: ft=basic expandtab ts=2 sw=2 wrap listchars=tab\:|\ ,trail\:% showbreak=::::::::

; CONSIDER TODO: Instead of random-step algorithm, we could recursively plot
; traingle corners, to get the same picture each frame.

; TODO TEST: We could do all removes for this frame before the adds.  Might
; leave us with more pixels!

; #define BASIC
#define ASSEMBLY
#define PLOT_XOR

MODE 7
VDU 23,1,0;0;0;0;
:
#include "teletext_bits.dim"
:
plotLoops% = 255
rotationSlowdown% = 1 + 0
trailLen% = 510
REM It appears the whole fractal takes around 900 pixels.  Well it might cover
REM more but then it starts looking over-bloated.
:

#ifdef BASIC
DIM cornerx%(3),cornery%(3)
DIM oldx%(trailLen%),oldy%(trailLen%)
:
cornerx%(0)=2+76/2
cornery%(0)=0
cornerx%(1)=2+76
cornery%(1)=75
cornerx%(2)=2+0
cornery%(2)=75
:
FOR Y%=0 TO 24
: ?(&7C00+Y%*40) = 148
NEXT
i% = 0
x%=0 : y%=0
REPEAT
: IF (i% MOD 32) = 0 THEN PROCmoveCorners
: PROCunplotTelexel(oldx%(i%),oldy%(i%))
: corner% = RND(1) * 3
: x% = (1 + x% + cornerx%(corner%)) / 2
: y% = (1 + y% + cornery%(corner%)) / 2
: PROCplotTelexel(x%,y%)
: oldx%(i%) = x%
: oldy%(i%) = y%
: i% = (i%+1) MOD trailLen%
UNTIL FALSE
:
END

DEF PROCmoveCorners
: FOR corner%=0 TO 2
: : angle = 2*PI*TIME/1000/150 + corner%*2*PI/3
: : cornerx%(corner%) = 40 + 38*SIN(angle)
: : cornery%(corner%) = 36 - 36*COS(angle)
: NEXT
ENDPROC

#include "plot_telexel.fns"
#endif

#ifdef ASSEMBLY
  PRINT
  PRINT "revolving..."
  PROCassemble
  CLS
  FOR line%=0 TO 23 : PRINTTAB(0,i%);CHR$(148);STRING$(39,CHR$(160)); : NEXT line%
  CALL init
  ; *FX 14,4
  REPEAT
    PRINTTAB(0,0);"rot=";(?rotation);"  ";
  UNTIL FALSE
END

DEF PROCassemble
  :
  #include "asm_common.jpp"
  :
  DIM code 2400
  DIM corners 6                   : REM 3 x, 3 y
  corners?0 = 2+76/2 : corners?1 = 2+76 : corners?2 = 2+0
  corners?3 = 0      : corners?4 = 75   : corners?5 = 75
  :
#define PLOT_TELEXEL_SAVE_OLD
#define PLOT_TELEXEL_SKIPIFSET
#define UNPLOT_TELEXEL_INCREMENTALLY
#define UNPLOT_TELEXEL_XOR
#include "plotTelexel.dims"
  x=&83 : y=&84
  charx=&85 : chary=&86
  bitx=&87 : bity=&88
  plotLoc=&89 : REM and &8A
  plotBit=&8B
  oldIndexLO=&81
  oldIndexHI=&82
  :
  DIM cornerxLookup 256  ; BUG: If I go up to 255 then all the 160s die!  O_o
  DIM corneryLookup 256  ; To reproduce the bug, move DIM oldData above div3Lookup.
  REM THIS IS WELL SLOW LOL
  scaleItoPI = 2*PI/256
  FOR i%=0 TO 127
    sin = SIN(i%*scaleItoPI)
    cos = COS(i%*scaleItoPI)
    ?(cornerxLookup+i%) = 40 + 38*sin
    ?(corneryLookup+i%) = 37 + 36*cos
    ?(cornerxLookup+i%+128) = 40 - 38*sin
    ?(corneryLookup+i%+128) = 37 - 36*cos
  NEXT i%
  :
  framecounter=&70
  rotateCounter=&71
  oldEvent=&72 : REM and &73
  loopCounter=&74
  rotation=&75
  :
  FOR I%=1 TO 3 STEP 2
  P%=code
  _resetLabelCounters
  [OPT I%
  ; #include "mult8.asm"
  .init
  LDX #0
  STX rotation
  STX x : STX y
  LDA #1 : STA rotateCounter
  LDA #oldData MOD 256 : STA oldIndexLO
  LDA #oldData DIV 256 : STA oldIndexHI
  ;
  _interceptEvent(4,&220,oldEvent,event)
  LDA #14 : LDX #4 : JSR &FFF4
  RTS
  .stop
  LDA #13 : LDX #4 : JSR &FFF4
  _removeEvent(4,&220,oldEvent,event)
  RTS
  .event
  DEC rotateCounter : BNE noRotate
  LDA #rotationSlowdown% : STA rotateCounter
  .rotate
    INC rotation
    LDA rotation : TAX
    LDA cornerxLookup,X : STA corners
    LDA corneryLookup,X : STA corners+3
    TXA : CLC : ADC #256/3 : TAX
    LDA cornerxLookup,X : STA corners+1
    LDA corneryLookup,X : STA corners+4
    TXA : CLC : ADC #256/3 : TAX
    LDA cornerxLookup,X : STA corners+2
    LDA corneryLookup,X : STA corners+5
  .noRotate
  .main

  #ifndef UNPLOT_TELEXEL_INCREMENTALLY
    ; Clear the last frame
    #include "plotTelexelUnplotAll.asm"
  #endif

  LDA #0 : STA loopCounter
  .plotLoop
  .getRandom         ; choose a corner
    ; ROR and EORs help make the numbers more random,
    ; but they are still not as good as BASIC's RND().
    LDA &FE64 : ROR A : EOR &FE65
    AND #3 : CMP #3 : BNE gotRandom
    LDA &FE65 : ROR A : EOR &FE66
    AND #3 : CMP #3 : BNE gotRandom
    LDA &FE66 : ROR A : EOR &FE67
    AND #3 : CMP #3 : BNE gotRandom
    LDA &FE67 : ROR A : EOR &FE64
    AND #3 : CMP #3 : BEQ getRandom
  .gotRandom
  TAX               ; move x,y halfway to the corner
  LDA corners,X
  CLC
  ADC x
  ROR A
  STA x
  LDA corners+3,X
  CLC
  ADC y
  ROR A
  STA y

#include "plotTelexel.asm"

  ; end of plot loop
  .plotLoopOut
  INC loopCounter : LDA loopCounter : CMP #plotLoops% : BEQ out : JMP plotLoop
  .out
  PLA : TAY
  PLA : TAX
  PLA
  PLP
  ; 10600 RTS
  JMP (oldEvent)
  ]
  NEXT I%
  PRINT "init is at &";~init;" and stop is at &";~stop
  OSCLI "SAVE O.SIERPA "+STR$~code+" "+STR$~P%+" "+STR$~init+" "+STR$~init
ENDPROC

#endif

RUN



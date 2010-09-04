; vim: ft=basic

>PAGE=&3800
>NEW

MODE 7

#define INTERPOLATE

; #define KEEP_INTERRUPTS

#define ASSEMBLY
#include "sinLookup.dims"
OSCLI "SAVE L.SIN "+STR$~sinLookup+" +100"
#include "lookupLogs2.dims"
#include "asm_common.jpp"

OSCLI "LOAD L.LOGS "+STR$~(lookupLog)

maxLines% = 25

; DIM curRotList maxLines%

; DIM lastLeft maxLines%
; DIM lastMiddle maxLines%
; DIM lastRight maxLines%

PROCassemble
CLS
startTime=TIME-1
CALL init
REM *FX 14,4
REPEAT
  PRINTTAB(0,0);
  PRINT "";(!frameCounter * 100 DIV (TIME-startTime));"  "
  PRINT "";?phase;"  "
  PRINT "";(?tension);"  "
  PRINT "";TIME;"  "
  PRINT "";!frameCounter;"  "
  PRINT "";?line;"  "
  PRINT "";curRotList?0;"  "
  PRINT "";curRotList?1;"  "
  PRINT "";curRotList?2;"  "
  ; PRINT "lastLeft.0=";lastLeft?0;"  "
  ; PRINT "lastLeft.1=";lastLeft?1;"  "
  ; ?tension = 160 + 95*COS(!frameCounter*2*PI/1500)
UNTIL FALSE
END

DEF PROCassemble

  ; DIM code 2400
  code=&2C00

  ; Rarely change (inter-frame)
  oldEvent=&70 ; and &71
  frameCounter=&72 ; and &73,74,75
  ; !frameCounter = 0
  tension=&76
  rotation=&77
  counterA=&78

  ; Often change (per-frame)
  line=&79
  lineStart=&7A ; and &7B

  #ifdef KEEP_INTERRUPTS
    alreadyRunning=&7C
  #endif
  phase=&7D

  ; Earlier
  numHI=&80
  numLO=&81
  numU=&82 ; and &83
  numV=&84 ; and &85
  lhs=&86
  ; Later
  leftFace=&80
  rightFace=&81
  sin=&82
  cos=&83
  firstx=&84
  secondx=&85
  thirdx=&86

  FOR I%=0 TO 2 STEP 2
  P%=code
  _resetLabelCounters
  [OPT I%

  .init
    LDA #22 : JSR OSASCI
    LDA #7 : JSR OSASCI
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
    LDA #192 : STA rotation
    LDA #0 : STA counterA
    #ifdef KEEP_INTERRUPTS
      LDA #0 : STA alreadyRunning
    #endif
    LDA #251 : STA tension
    LDA #255 : STA counterA
    LDA #0 : STA frameCounter
             STA frameCounter+1
             STA frameCounter+2
             STA frameCounter+3
    LDA #56 : STA phase
    _interceptEvent(4,&220,oldEvent,event)
    LDA #14 : LDX #4 : JSR &FFF4
  RTS

  .stop
    LDA #13 : LDX #4 : JSR &FFF4
    _removeEvent(4,&220,oldEvent,event)
  RTS

  .curRotList
    _repeat(EQUB 0,maxLines%)

  .lastLeft
    _repeat(EQUB 0,maxLines%)
  .lastMiddle
    _repeat(EQUB 0,maxLines%)
  .lastRight
    _repeat(EQUB 0,maxLines%)

  ]
  FOR i%=0 TO maxLines%-1
    curRotList?i% = 32/3
    lastLeft?i% = 255
    lastMiddle?i% = 255
    lastRight?i% = 255
  NEXT
  [OPT I%

  .event

    #ifdef KEEP_INTERRUPTS
      LDA alreadyRunning : CMP #0 : BEQ okEvent
        JMP leaveEvent
      .okEvent
        LDA #1 : STA alreadyRunning
        CLI
    #endif

    INC frameCounter : BNE frameCounterNoOverflow
      INC frameCounter+1
    .frameCounterNoOverflow

    ; ?tension = 160 + 95*COS(!frameCounter*255/1500)
    LDA frameCounter : CMP #11 : BNE skipPhase
      INC phase
      ; LDA frameCounter : STA numLO
      ; _multiply16to16(numLO,#255,phase,numLO)
      LDX phase
      LDA sinCharge,X : STA postInvertA-1
      AND #1 : STA postInvertAsub-1
      LDA sinLookup,X
      CLC : ADC #212   ; my guess at log 95
      BCS nonZero
        LDA #0 : JMP asdasd
      .nonZero
      TAX : LDA lookupUnlog2,X
      SEC : SBC #123 : .postInvertAsub
      EOR #123 : .postInvertA
      .asdasd
      CLC : ADC #160
      STA tension
      LDA #0 : STA frameCounter   ; bastardised frameCounter
    .skipPhase

    INC counterA
    ; LDA #2 : STA counterA

    LDA #2 : BIT counterA : BNE noRotate
      INC rotation
    .noRotate

    LDA #1 : BIT counterA : BNE noSpin

      ; We rotate the top of the whirl by 1/16th of a sin lookup in rotation
      .moveTop
        ; First prepare sine quadrant:
          ;; sinSgnLookup is not loaded !
          ; LDA rotation : ROL A : ROL A : ROL A : AND #3
          ; TAX : LDA sinSgnLookup,X : STA postSignA-1
          LDA rotation
          TAX : LDA sinCharge,X : STA postSignA-1
        LDX rotation
        LDA sinLookup,X
        ; divide by 16, otherwise too fast!
        ROR A : ROR A : ROR A : ROR A : AND #15
        ; now 64 O_o
        ; ROR A : ROR A : ROR A : ROR A : ROR A : ROR A : AND #3
        ; bah this often comes out 0, where instead it should come out: rotate 1 every few frames
        EOR #123 : .postSignA
        CLC : ADC curRotList : STA curRotList

    .noSpin

    LDY #0 : STY line
    LDA #&7C : STA lineStart+1
    LDA #&00 : STA lineStart
    .loopLines

      ; LDY line

      .undoLastPlot
        ]
        PROCmaybeUndo(lastLeft)
        PROCmaybeUndo(lastMiddle)
        PROCmaybeUndo(lastRight)
        [OPT I%

      LDY line : CPY #0 : BNE moveLine : JMP skipMoveLine
        .moveLine

        ; curRotList,Y =  curRotList,Y-1 * tension + curRotList,Y * (1-tension)

        LDY line
        LDA curRotList,Y : STA numV
        DEY : LDA curRotList,Y : STA numU

        ; Can we really interpolate this way, or are they too far apart (wrapped around)
        ; TODO: I think we have neglected to do the -1 usually required when inverting a signed byte.
        ; If we got a negative number then we invert numU and numV
        LDA #0 : STA doTheFix-1
        LDA numV : SEC : SBC numU
        BCS positive : EOR #255 : .positive
        CMP #127 : BCC smallEnough
          LDA numU : EOR #128 : STA numU
          LDA numV : EOR #128 : STA numV
          LDA #128 : STA doTheFix-1
        .smallEnough

        #ifdef INTERPOLATE

          LDA tension : STA numLO
          _multiply8to16(numLO,numU,numHI,numLO)
          ; numHI contains lhs
          STA numU
          LDA numHI : STA numU+1

          LDA #0 : SEC : SBC tension : STA numLO
          _multiply8to16(numLO,numV,numHI,numLO)
          ; numHI contains rhs
          STA numV
          LDA numHI : STA numV+1

          ; LDA numHI : CLC : ADC lhs
          ; CLC : ADC #1

          ;; These were attempts at rounding up:
          LDA numU : CLC : ADC #128 : STA numU
          LDA numU+1 : ADC #0 : STA numU+1
          ; LDA numV : CLC : ADC #127 : STA numV
          ; LDA numV+1 : ADC #0 : STA numV+1
          LDA numU : CLC : ADC numV
          LDA numU+1 : ADC numV+1
          ; CLC : ADC #1

        #else

          LDA numU : CLC : ADC numV : ROR A

        #endif

        ; Undo the invert of numU and numV
        EOR #123 : .doTheFix
        LDY line
        ; CLC : ADC #1   ; rounding?
        STA curRotList,Y

      .skipMoveLine

      .plotLine
        #define _divide_by_16 ROR A : ROR A : ROR A : ROR A : AND #15

        ; divide by 64, aka get top 2 bits
        LDA curRotList,Y
        ROL A : ROL A : ROL A
        AND #3 : STA leftFace
        CLC : ADC #1
        AND #3 : STA rightFace

        ; get sin and cos from angle of left edge
        LDA curRotList,Y
        AND #63 : CLC : ADC #32 : TAX
        LDA sinLookup,X : _divide_by_16 : STA sin
        TXA : CLC : ADC #64 : TAX
        LDA sinLookup,X : _divide_by_16 : STA cos
        ; cos might be negative - check the quadrant
        ; TXA : ROL A : ROL A : ROL A : AND #3 : TAX
        ; LDA sinSgnLookup,X : EOR cos : STA cos
        LDA sinCharge,X : EOR cos : STA cos

        ; calculate firstx,secondx,thirdx
        LDA #21 : SEC : SBC sin : STA firstx
        LDA #22 : CLC : ADC cos : STA secondx
        LDA #23 : CLC : ADC sin : STA thirdx

        LDX line

        ; Plot first edge?
        LDA #255 : STA lastLeft,X
        LDA firstx : CLC : ADC #2
        CMP secondx : BCS skipFirst
          LDY firstx
          LDA #129 : CLC : ADC leftFace
          STA (lineStart),Y
          INY
          LDA #157
          STA (lineStart),Y
          TYA
          STA lastLeft,X
        .skipFirst

        ; Plot middle edge?
        LDA #255 : STA lastMiddle,X
        LDA secondx : CLC : ADC #2
        CMP thirdx : BCS skipSecond
          LDY secondx
          LDA #129 : CLC : ADC rightFace
          STA (lineStart),Y
          INY
          LDA #157
          STA (lineStart),Y
          TYA
          STA lastMiddle,X
        .skipSecond

        ; We always plot right edge, but at +1
        ; which is ok cos we always clear 2 ;p
        LDA #255 : STA lastRight,X
        LDA thirdx : CLC : ADC #2
          LDY thirdx
          LDA #156
          STA (lineStart),Y
          TYA
          STA lastRight,X

      .donePlotLine

      ; Advance around the loop

      LDA lineStart : CLC : ADC #40 : STA lineStart
      LDA lineStart+1 : ADC #0 : STA lineStart+1

      LDY line
      INY : STY line
      CPY #maxLines%
      BEQ outLoopLines
      JMP loopLines
    .outLoopLines

    ; LDA #13 : LDX #4 : JSR &FFF4

    #ifdef KEEP_INTERRUPTS
      SEI
      LDA #0 : STA alreadyRunning
    #endif

  .leaveEvent

    JSR &0E06

  RTS

  ]
  NEXT I%

  OSCLI "SAVE O.ROTA "+STR$~code+" "+STR$~P%+" "+STR$~init

  OSCLI "SPOOL I.ROTA"
  PRINT "start=&";~code;" end=&";~P%;" init=&";~init;" and stop=&";~stop
  OSCLI "CLOSE"

ENDPROC

DEF PROCmaybeUndo(table)
  [OPT I%
    LOAD_LABEL(skipUndo)

    LDY line
    LDA table,Y
    CMP #255 : BEQ skipUndo
      TAY
      LDA #32
      STA (lineStart),Y
      INY
      STA (lineStart),Y
    .skipUndo

    SAVE_LABEL(skipUndo)
  ]
ENDPROC


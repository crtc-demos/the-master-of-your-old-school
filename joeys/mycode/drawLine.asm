
; @requires PLOT_POINT
; @requires input-var x1,x2,y1,y2
; @requires temp-var x,y,x_dist,y_dist,fraction

LOAD_LABEL(bresLoopX)
LOAD_LABEL(bresLoopY)

;; When x,y are ZP:
#define _inc &E6
#define _dec &C6

.drawLine

  ; Draws a line from [x1,y1 to x2,y2) which are expressed in coords 0-255,0-255 from top-left

  LDA x2 : SEC : SBC x1 : STA x_dist
  BCS posxdiff   ; .negxdiff
    EOR #&FF : STA x_dist : INC x_dist : LDA #_dec : STA xdir : STA xdir2 : JMP donexdiff
  .posxdiff
    LDA #_inc : STA xdir : STA xdir2
  .donexdiff
  LDA y2 : SEC : SBC y1 : STA y_dist
  BCS posydiff   ; .negydiff
    EOR #&FF : STA y_dist : INC y_dist : LDA #_dec : STA ydir : STA ydir2 : JMP doneydiff
  .posydiff
    LDA #_inc : STA ydir : STA ydir2
  .doneydiff

  LDA x1 : STA x
  LDA y1 : STA y

  ; PLOT_POINT(x,y)
  ; JMP drawLineOut

  LDA x_dist : SEC : SBC y_dist : BCC bresDoY

  ] : numA=fraction : [OPT I%

  .bresDoX
    ; LDA x_dist : STA delta
    ; _divide8to8(delta,y_dist)

    LDA x_dist
    CMP #0 : BEQ drawLineOut
    LSR A : STA fraction

  .bresLoopX

    ; @todo Plot point x,y

    PLOT_POINT(x,y)

    ; so each step we will advance x by one
    ; we should advance y by x_dist / y_dist

    LDA fraction : SEC : SBC y_dist
    BCS noAdvanceY
    ; .advanceY
      .ydir2 INC y
      CLC : ADC x_dist
    .noAdvanceY
    STA fraction

    .xdir2 DEC x
    LDA x : CMP x2

  BNE bresLoopX

  JMP drawLineOut

  .bresDoY
    ; LDA y_dist : STA delta
    ; _divide8to8(delta,x_dist)

    LDA y_dist
    CMP #0 : BEQ drawLineOut
    LSR A : STA fraction

  .bresLoopY

    ; @todo Plot point x,y

    PLOT_POINT(x,y)

    ; so each step we will advance Y by one
    ; we should advance x by x_dist / y_dist

    LDA fraction : SEC : SBC x_dist
    BCS noAdvanceX
    ; .advanceX
      .xdir INC x
      CLC : ADC y_dist
    .noAdvanceX
    STA fraction

    .ydir DEC y
    LDA y : CMP y2

  BNE bresLoopY

.drawLineOut

SAVE_LABEL(bresLoopX)
SAVE_LABEL(bresLoopY)


; @required plotTelexel.dims
; @related plotTelexel.asm
; @expected oldData, oldDataEnd
; @expected oldIndexLO, oldIndexHI

LOAD_LABEL(unplotOldLoop)
LOAD_LABEL(unplotOldContinue)
LOAD_LABEL(unplotOldOut)
LOAD_LABEL(skip)

#ifdef OLDDATA_SUPERFAST

  LDX oldIndex
  #ifndef TRAILLEN_IS_256
    CPX #0 : BEQ unplotOldOut   ; There were no pixels last frame
    ;; BUG: If trailLen% IS 256, then we are kinda screwed if we plot a frame with 0 pixels.  We will proceed to unplot the 256 pixels in history unneccessarily!
  #endif
  LDY #0
  .unplotOldLoop
    DEX
    ; LDA oldPlotBits,X : STA plotBit
    ; #define plotBit oldPlotBits,X
    LDA oldPlotLocLO,X : STA plotLoc
    LDA oldPlotLocHI,X : STA plotLoc+1
    LDA oldPlotBits,X
    #ifdef UNPLOT_TELEXEL_XOR
      EOR (plotLoc),Y : STA (plotLoc),Y
    #else
      EOR #255 : AND (plotLoc),Y : ORA #160 : STA (plotLoc),Y
    #endif
    ; #undef plotBit
  CPX #0 : BNE unplotOldLoop
  STX oldIndex
  .unplotOldOut

#else

  .unplotOldLoop
    LDA oldIndexLO : CMP #oldData MOD 256 : BNE unplotOldContinue
    LDA oldIndexHI : CMP #oldData DIV 256 : BEQ unplotOldOut
    .unplotOldContinue
    LDA oldIndexLO : SEC : SBC #3 : STA oldIndexLO : BCS skip : DEC oldIndexHI : .skip
    LDY #0 : LDA (oldIndexLO),Y : STA plotBit
    INY : LDA (oldIndexLO),Y : STA plotLoc
    INY : LDA (oldIndexLO),Y : STA plotLoc+1
    LDY #0
    #ifdef UNPLOT_TELEXEL_XOR
      LDA (plotLoc),Y : EOR plotBit : STA (plotLoc),Y
    #else
      LDA plotBit : EOR #255 : AND (plotLoc),Y : ORA #160 : STA (plotLoc),Y
    #endif
    JMP unplotOldLoop
  .unplotOldOut

#endif

SAVE_LABEL(unplotOldLoop)
SAVE_LABEL(unplotOldContinue)
SAVE_LABEL(unplotOldOut)
SAVE_LABEL(skip)


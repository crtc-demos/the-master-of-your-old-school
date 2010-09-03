  ; TODO: We could require getPixelMode4.dims to provides a pre-defined lookup of
  ; screen line start locations

  ; Given x,y, generates appropriate scrLocLO/HI, and completes with A=bit to plot there
  ; If KEEP_OLD_LOCS then X contains the index into oldLocLO/HI and oldBit
  ; .getpixel
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


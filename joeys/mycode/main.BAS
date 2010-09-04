; vim: ft=basic

; >PAGE=&3800
; >NEW

MODE 7

#include "asm_common.jpp"

PROCassemble
END

DEF PROCassemble

  ; DIM code 2400
  code=&3800

  FOR I%=0 TO 2 STEP 2
  P%=code
  [OPT I%

    #define _OSCLI &FFF7
    #define _oscli(target) LDX _HASH target MOD 256 : LDY _HASH target DIV 256 : JSR _OSCLI

  .init

    _oscli(loadlogs)
    _oscli(loadsin)
    _oscli(loadsierpa)
    _oscli(loadrota)
    _oscli(loadphase)
    _oscli(loadwhirl)

    JSR &0E0F   ; page in tune data
    ; JSR &2337   ; start sierpa
; 
    ; .contSierpa
    ; LDA &29 : CMP #5 : BCC contSierpa
; 
    ; JSR &23AB   ; stop sierpa
    ; JSR &2C00   ; start rota
; 
    ; .cont_rota
    ; LDA &29 : CMP #8 : BCC cont_rota
; 
    ; JSR &2C7B  ; stop rota
    JSR &1B00   ; start phase

    .cont_phase
    LDA &29 : CMP #13 : BCC cont_phase

    JSR &1B72   ; stop phase
    JSR &290C   ; start whirl

    .cont_whirl
    LDA &29 : CMP #16 : BCC cont_whirl

    JSR &2999   ; stop whirl
    JSR &0E12   ; page out tune data

    _oscli(runsplitp)

  RTS

  .loadlogs
    EQUS "LOAD L.LOGS" : EQUB 13

  .loadsin
    EQUS "LOAD L.SIN" : EQUB 13

  .loadsierpa
    EQUS "LOAD O.SIERPA" : EQUB 13

  .loadrota
    EQUS "LOAD O.ROTA" : EQUB 13

  .loadphase
    EQUS "LOAD O.PHASE" : EQUB 13

  .loadwhirl
    EQUS "LOAD O.WHIRL" : EQUB 13

  .runsplitp
    EQUS "RUN SPLITP" : EQUB 13

  ]
  NEXT I%

  OSCLI "SAVE O.MAIN "+STR$~init+" "+STR$~P%+" "+STR$~init

  OSCLI "SPOOL I.MAIN"
  PRINT "start=&";~code;" end=&";~P%;" init=&";~init
  OSCLI "CLOSE"

ENDPROC


REM vim: ft=basic noexpandtab ts=2 sw=2 wrap listchars=tab\:|\ ,trail\:% showbreak=::::::::

; In modes with many colours, we may be able to hide the pass line by randomly
; swapping palette colours on interrupt.

MODE 2
FOR i%=0 TO 7 : VDU 19,8+i%,i%,0;0;0;0; : NEXT i%
; FOR i%=0 TO 7 : VDU 19,15-i%,i%,0;0;0;0; : NEXT i% ; for the pretty pattern when using pure timer

start%=HIMEM+&2800+8*24
jump%=640
locLO=&80 : locHI=&81
framecount=&82 : REM and &83
seed=&84
seeds=&E00 : REM to &EFF
FOR i%=0 TO 255 : seeds?i%=RND(256) : NEXT i%
FOR I%=0 TO 3 STEP 3
P%=PAGE
[OPT I%

.start
LDA #start% MOD 256 : STA locLO
LDA #start% DIV 256 : STA locHI
LDY #0

LDA &FE64
.reseed
EOR seeds,Y : STA seeds,Y
INY : BNE reseed

.loop
EOR &FE64
EOR seeds,Y
STA (locLO),Y
INY : BNE loop          ; break out at &00
; INC locHI : BPL loop    ; break out at &80
CLC : LDA locLO : ADC #jump% MOD 256 : STA locLO : LDA locHI : ADC #jump% DIV 256 : STA locHI : BPL loop
INC framecount : BCC skipFramecount : INC framecount+1 : .skipFramecount

; We could do a random hardware scroll once per frame, which might hide the blit line
; See AUG 18.15

JMP start

]
NEXT I%

CLS

!framecount = 0
CALL start


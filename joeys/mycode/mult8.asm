; 8-bit multiplication and division library bitchez.

; You will need something like this in your BASIC:
; result=&80
; numA=&81
; numB=&82
; numC=&83
; Or try #defines ?

; Hmmm maybe we don't want such core functions as calls.
; We might prefer to inline them when we need them, to make things faster.
; We may not know which register the data is in though.
; Seems like copy-paste and adjustment to surroundings would be the most efficient.

; TODO: The following are old (from mult.bas).  Compare against newer copies
;       in drip.bas!  Then complete the refactor.

.multiply8
LDA #0
LDX #8
; Efficiency hack, can be dropped:
; When numA is a small number, the first few ROLs do nothing else - they
; can be made faster by dropping the ROL A and the jump to skip.
; To maximize this advantage, callers should aim for numA<numB where possible.
.multLoop0
ROL numA
BCS multJumpIn
DEX
BNE multLoop0
; numA was zero :P
JMP multOut
; End hack.
.multLoop
ROL A
ROL numA
BCC skip
.multJumpIn
CLC
numB
; BCS toolarge
; If we want to support 16-bit output we must carry here
.skip
DEX
BNE multLoop
.multOut
STA result
RTS

.multiply8to16
; numA and numB are the numbers, numA will be destroyed
LDA #0
STA numC
LDX #8
.m816Loop
CLC
ROL numC
; numC can't overflow so this isn't needed: CLC
ROL A
BCC skipm816a
CLC
INC numC
.skipm816a
ROL numA
BCC skipm816b
CLC
ADC numB
BCC skipm816b
INC numC
.skipm816b
DEX
BNE m816Loop
; A=lo, hi is in numC tidy huh? :P
STA numB
RTS

; numA / numB -> numA (rem numA)
; numA destroyed!  numB unharmed
.divide8
LDA #0
LDX #8
ASL numA
.divLoop
ROL A
CMP numB
BCC divSkip
SBC numB
.divSkip
ROL numA
DEX
BNE divLoop
; ; result is in numA, remainder in A
RTS


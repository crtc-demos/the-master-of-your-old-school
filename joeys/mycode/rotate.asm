; @requires lookupSignedLog.dims
;
; Input: x,y are signed bytes
;        matrix is 4 signed bytes representing a transformation
; Output: x_,y_ are the transformed coordinates
; Also needs: tmpA
;
;           | a b |
; (x_,y_) = | c d | (x,y) = (ax+by,cx+dy)
;
; Y is unaffected throughout so can be used for an outer loop, and
; e.g. #define x verticesY,Y
;      #define y verticesZ,Y
; Oh too bad that will fail, since we LDX x rather than LDA x :P
; @todo A fix for complex cases would be: #define LOAD_X(source) LDA source : TAX

; CONSIDER: Maybe we want to precalc all our matrices to be already in log
; space.  Oh but then where will we get the sign from?!

; The branching to apply signs has caused us to save tmpA sometimes too often
; the second time!  Would a JMP out of the negative case be more efficient? =/

#define matrix_a matrix
#define matrix_b matrix+1
#define matrix_c matrix+2
#define matrix_d matrix+3

; x_ = a*x
	CLC
	LDX x : LDA lookupSignedLog,X
	LDX matrix_a : ADC lookupSignedLog,X
	BCS axNonZero
		LDA #0 : BCC axOut
	.axNonZero
		SBC #254
		TAX : LDA lookupUnlog,X
	.axOut
	STA x_
	; Apply sign
	LDA x : EOR matrix_a : AND #128 : BEQ axPositive
		DEC x_ : LDA x_ : EOR #255 : STA x_
	.axPositive
; tmpA = b*y
	CLC
	LDX y : LDA lookupSignedLog,X
	LDX matrix_b : ADC lookupSignedLog,X
	BCS byNonZero
		LDA #0 : BCC byOut
	.byNonZero
		SBC #254
		TAX : LDA lookupUnlog,X
	.byOut
	STA tmpA
	; Apply sign
	LDA y : EOR matrix_b : AND #128 : BEQ byPositive
		DEC tmpA : LDA tmpA : EOR #255 : STA tmpA
	.byPositive
	LDA tmpA
; x_ = x_ + tmpA
	CLC : ADC x_ : STA x_

; y_ = c*x
	CLC
	LDX x : LDA lookupSignedLog,X
	LDX matrix_c : ADC lookupSignedLog,X
	BCS cxNonZero
		LDA #0 : BCC cxOut
	.cxNonZero
		SBC #254
		TAX : LDA lookupUnlog,X
	.cxOut
	STA y_
	; Apply sign
	LDA x : EOR matrix_c : AND #128 : BEQ cxPositive
		DEC y_ : LDA y_ : EOR #255 : STA y_
	.cxPositive
; tmpA = d*y
	CLC
	LDX y : LDA lookupSignedLog,X
	LDX matrix_d : ADC lookupSignedLog,X
	BCS dyNonZero
		LDA #0 : BCC dyOut
	.dyNonZero
		SBC #254
		TAX : LDA lookupUnlog,X
	.dyOut
	STA tmpA
	; Apply sign
	LDA y : EOR matrix_d : AND #128 : BEQ dyPositive
		DEC tmpA : LDA tmpA : EOR #255 : STA tmpA
	.dyPositive
	LDA tmpA
; y_ = y_ + tmpA
	CLC : ADC y_ : STA y_

#undef matrix_a
#undef matrix_b
#undef matrix_c
#undef matrix_d



	.org $e00

; 0x40-0x5f used for matrices, vector temps.

; 32 bytes.
	.alias m_mat $50

; 8 bytes.
	.alias vec_tmp $40

; 0x00-0x3f can be used as X-indexed stack. (Not used at present.)
	.alias xsp $48

; three 256-byte chunks, "byte-planed"
	.alias sqtab_0 $8000
	.alias sqtab_1 $8100
	.alias sqtab_2 $8200

	.alias logtab_addr $8300
	.alias exptab_addr $8b00

; two 64-byte halves for lo/hi, "byte-planed"
	.alias sintab_0 $9b00
	.alias sintab_1 $9b40

	.alias columns_per_row 8

	; 256 bytes
	.alias row_length_0 $9c00
	; 256 * 8 bytes
	.alias change_columns_0 $9d00
	; 256 * 8 bytes
	.alias switch_colours_0 $a500
	
	; 256 bytes
	.alias row_length_1 $ad00
	; 256 * 8 bytes
	.alias change_columns_1 $ae00
	; 256 * 8 bytes
	.alias switch_colours_1 $b600
	; (finishes at $be00)

	; Declare ZP locations to use for automatically-allocated temporaries.
	.temps $70..$8f
	.temps $4a..$4f

entry:
	.(
	lda #2
	jsr mos_setmode
	jsr mos_cursoroff
	;jsr setorigin
	jsr select_sram
	jsr clear_sram
	jsr kill_sound
	jsr load_sqtab
	jsr load_logtab
	jsr load_exptab
	jsr load_sintab
	jsr cls
	jsr test_render_offscreen
	;jsr test_render
	jsr select_old_lang
	
	lda #7
	jsr mos_setmode
	
	ldx #0
final
	lda final_part,x
	cmp #255
	beq done
	jsr oswrch
	inx
	bra final
done
	ldx #<basic
	ldy #>basic
	jsr oscli
	
	rts
	.)

final_part
	.asc "The Master of Your Old School\r\n\nCode: puppeh\r\nCode: joey\r\nMusix: insectecutor\r\n\nSundown 2010\r\n\nThanks for watching!\r\n\n",255

basic
	.asc "basic",13

	.context clear_sram
	.var2 ptr
clear_sram
	lda #<$8000
	sta %ptr
	lda #>$8000
	sta %ptr + 1
	
outer_loop
	ldy #0
	lda #0
loop
	sta (%ptr), y
	iny
	bne loop
	
	inc %ptr + 1
	lda %ptr + 1
	cmp #$c0
	bcc outer_loop
	
	rts
	.ctxend

kill_sound:
	.(
	; tone 3 volume
	lda #0b10011111
	jsr write_sound_byte
	; tone 2 volume
	lda #0b10111111
	jsr write_sound_byte
	; tone 1 volume
	lda #0b11011111
	jsr write_sound_byte
	; noise volume
	lda #0b11111111
	jsr write_sound_byte
	rts
	
write_sound_byte
	sei
	ldy #255
	sty $fe43

	sta $fe41
	stz $fe40
	nop
	nop
	nop
	nop
	nop
	nop
	lda #$08
	sta $fe40
	
	cli
	rts
	.)

	.include "../lib/mos.s"

centre:
	.byte 29
	.byte <640
	.byte >640
	.byte <512
	.byte >512

setorigin:
	.(
	ldx #0
loop:
	lda centre,x
	jsr oswrch
	inx
	cpx #5
	bne loop
	rts
	.)

	.context cls
cls:
	lda #12
	jmp oswrch
	.ctxend

	.include "../lib/sram.s"

osfile_blk:
	.dsb 18,0

	; load a file named YX to screen ram (temporary space) at $3000.
load_file:
	stx osfile_blk
	sty osfile_blk + 1
	stz osfile_blk + 6
	lda #<$3000
	sta osfile_blk + 2
	lda #>$3000
	sta osfile_blk + 3
	ldx #<osfile_blk
	ldy #>osfile_blk
	lda #$ff
	jmp osfile

load_sqtab:
	.(
	ldx #<sqtab_name
	ldy #>sqtab_name
	jsr load_file
	lda #>768
	ldx #<sqtab_0
	ldy #>sqtab_0
	jmp copy_to_sram
sqtab_name:
	.asc "sqtab",13
	.)

load_logtab:
	.(
	ldx #<logtab_name
	ldy #>logtab_name
	jsr load_file
	lda #>2048
	ldx #<logtab_addr
	ldy #>logtab_addr
	jmp copy_to_sram
logtab_name:
	.asc "logtab",13
	.)

load_exptab:
	.(
	ldx #<exptab_name
	ldy #>exptab_name
	jsr load_file
	lda #>4096
	ldx #<exptab_addr
	ldy #>exptab_addr
	jmp copy_to_sram
exptab_name:
	.asc "exptab",13
	.)

load_sintab:
	.(
	ldx #<sintab_name
	ldy #>sintab_name
	jsr load_file
	; actually only 128 bytes, so this copies too much.
	lda #1
	ldx #<sintab_0
	ldy #>sintab_0
	jmp copy_to_sram
sintab_name:
	.asc "sintab",13	
	.)

	; multiply ahi,alo by bhi,blo, result in result (3 bytes).
	; 'dumb' implementation.
	; corrupts A,X,Y.

	.context mult_16_16
	.var alo, ahi, blo, bhi
	.var result_neg
	.var3 result
	.var4 tmp

mult_16_16:
	stz %result
	stz %result + 1
	stz %result + 2
	
	lda %ahi
	eor %bhi
	sta %result_neg

	; negate inputs if they are positive
	.(
	lda %bhi
	bpl b_pos
	lda #0
	sec
	sbc %blo
	sta %blo
	lda #0
	sbc %bhi
	sta %bhi
b_pos:
	.)

	.(
	lda %ahi
	bpl a_pos
	lda #0
	sec
	sbc %alo
	sta %alo
	lda #0
	sbc %ahi
	sta %ahi
a_pos:
	.)
	
	lda %blo
	sta %tmp + 1
	lda %bhi
	sta %tmp + 2
	stz %tmp + 3
	
	lda #1
	sta %tmp
	.(
lowbits:
	lda %alo
	and %tmp
	beq nextbit
	lda %result
	clc
	adc %tmp + 1
	sta %result
	lda %result + 1
	adc %tmp + 2
	sta %result + 1
	lda %result + 2
	adc %tmp + 3
	sta %result + 2
nextbit:
	asl %tmp + 1
	rol %tmp + 2
	rol %tmp + 3

	asl %tmp
	bne lowbits
	.)

	lda #1
	sta %tmp
	.(
highbits:
	lda %ahi
	and %tmp
	beq nextbit
	lda %result + 1
	clc
	adc %tmp + 2
	sta %result + 1
	lda %result + 2
	adc %tmp + 3
	sta %result + 2
nextbit:
	asl %tmp + 2
	rol %tmp + 3
	
	asl %tmp
	bne highbits
	.)

	lda %result_neg
	bpl done

	; negate result
	lda #0
	sec
	sbc %result
	sta %result
	lda #0
	sbc %result + 1
	sta %result + 1
	lda #0
	sbc %result + 2
	sta %result + 2

done:
	rts
	.ctxend

	; multiply ahi,alo by bhi,blo. Latter must be -256..256.
	; Both values are signed. Result in 'result'.
	; corrupts alo,ahi,blo,bhi,tmp1

	.context mult_16_8
	.var alo, ahi, blo, bhi, tmp1
	.var3 result

mult_16_8:
	phy
	phx
	ldy #0
	bit %bhi
	.(
	bpl b_positive
	iny

	lda #0
	sec
	sbc %blo
	sta %blo
	lda #0
	sbc %bhi
	sta %bhi
b_positive:
	.)
	
	bit %ahi
	.(
	bpl a_positive
	iny

	lda #0
	sec
	sbc %alo
	sta %alo
	lda #0
	sbc %ahi
	sta %ahi
a_positive:
	.)

	sty %tmp1

	; Allow b=256 or b=-256 as special cases. (Condition a bit slack).
	lda %bhi
	cmp #1
	beq mult_256
	
	ldx %alo
	ldy %blo
	lda sqtab_0, x
	clc
	adc sqtab_0, y
	sta %result
	lda sqtab_1, x
	adc sqtab_1, y
	sta %result + 1
	lda sqtab_2, x
	adc sqtab_2, y
	sta %result + 2
	; result[2-0] has alo^2 + b^2
	txa
	sec
	sbc %blo
	.(
	bcs alo_minus_b_positive
	eor #$ff
	inc
alo_minus_b_positive:
	.)
	tax
	; X has abs (alo - b).
	lda %result
	sec
	sbc sqtab_0, x
	sta %result
	lda %result + 1
	sbc sqtab_1, x
	sta %result + 1
	lda %result + 2
	sbc sqtab_2, x
	sta %result + 2
	; result[2-0] has alo^2 + b^2 - abs(alo-b)^2
	ldx %ahi
	ldy %blo
	; add (ahi^2) << 8
	lda %result + 1
	clc
	adc sqtab_0, x
	sta %result + 1
	lda %result + 2
	adc sqtab_1, x
	sta %result + 2
	; add (b^2) << 8
	lda %result + 1
	clc
	adc sqtab_0, y
	sta %result + 1
	lda %result + 2
	adc sqtab_1, y
	sta %result + 2
	; result[2-0] has (previous result) + (ahi^2 << 8) + (b^2 << 8)
	txa
	sec
	sbc %blo
	.(
	bcs ahi_minus_b_positive
	eor #$ff
	inc
ahi_minus_b_positive:
	.)
	tax
	; X has abs (ahi - b)
	lda %result + 1
	sec
	sbc sqtab_0, x
	sta %result + 1
	lda %result + 2
	sbc sqtab_1, x
	sta %result + 2
	; result[2-0] has (previous result) - abs(ahi-b)^2 << 8
	lsr %result + 2
	ror %result + 1
	ror %result

	; finally, should the answer be positive or negative?
	lsr %tmp1
	.(
	bcc done
	lda #0
	sec
	sbc %result
	sta %result
	lda #0
	sbc %result + 1
	sta %result + 1
	lda #0
	sbc %result + 2
	sta %result + 2
done:
	.)
	plx
	ply
	rts

mult_256:
	.(
	lsr %tmp1
	bcc m256_positive
	stz %result
	lda #0
	sec
	sbc %alo
	sta %result + 1
	lda #0
	sbc %ahi
	sta %result + 2
	plx
	ply
	rts
m256_positive:
	.)
	stz %result
	lda %alo
	sta %result + 1
	lda %ahi
	sta %result + 2
	plx
	ply
	rts
	.ctxend
	
	; Do scale * ahi,alo / bhi,blo. Result in 'result' (2 bytes). Inputs
	; corrupted.
	; A corrupted. X,Y preserved. "scale" is fixed at 32.
	
	.context scaled_div
	.var2 in_a, in_b, tmp1
	.var tmp2
	.var2 result
	
scaled_div:
	phy
	phx
	stz %tmp2
	bit %in_a + 1
	.(
	bpl apos
	lda #0
	sec
	sbc %in_a
	sta %in_a
	lda #0
	sbc %in_a + 1
	sta %in_a + 1
	inc %tmp2
apos:
	.)
	bit %in_b + 1
	.(
	bpl bpos
	lda #0
	sec
	sbc %in_b
	sta %in_b
	lda #0
	sbc %in_b + 1
	sta %in_b + 1
	inc %tmp2
bpos:
	.)
	lda %in_a + 1
	asl %in_a
	rol
	clc
	adc #>logtab_addr
	sta %in_a + 1
	lda (%in_a)
	sta %tmp1
	ldy #1
	lda (%in_a), y
	sta %tmp1 + 1
	lda %in_b + 1
	asl %in_b
	rol
	clc
	adc #>logtab_addr
	sta %in_b + 1
	lda %tmp1
	sec
	sbc (%in_b)
	sta %tmp1
	lda %tmp1 + 1
	sbc (%in_b), y
	; bias (+2048 bytes/1024 array elements)
	clc
	adc #8
	; exptab base
	clc
	adc #>exptab_addr
	sta %tmp1 + 1
	lsr %tmp2
	bcs result_negative
	lda (%tmp1)
	sta %result
	lda (%tmp1), y
	sta %result + 1
	plx
	ply
	rts
result_negative:
	lda #0
	sec
	sbc (%tmp1)
	sta %result
	lda #0
	sbc (%tmp1), y
	sta %result + 1
	plx
	ply
	rts
	.ctxend

	; Find the sin of the accumulator. 0 to 2*pi radians (full circle) are
	; represented as 0 to 255. Output is -256..+256, placed in (m_vec_p),y.
	; corrupts tmp1, A, X, Y.
	
	.context sin
	.var2 m_vec_p, tmp1
	
sin:
	phy
	pha
	and #$7f
	cmp #64
	bcc angle_0_to_halfpi
	bne angle_halfpi_to_pi
	; angle=64 is not stored in the table. Special case.
	ldx #<256
	ldy #>256
	bra over_pi_check
angle_0_to_halfpi:
	tax
	bra do_lookup
angle_halfpi_to_pi:
	eor #$7f
	tax
	inx
do_lookup:
	lda sintab_0,x
	ldy sintab_1,x
	tax
over_pi_check:
	; now low part of result in X, high part in Y
	pla
	bpl less_than_pi
	stx %tmp1
	sty %tmp1 + 1
	ply
	lda #0
	sec
	sbc %tmp1
	sta (%m_vec_p),y
	lda #0
	sbc %tmp1 + 1
	iny
	sta (%m_vec_p),y
	rts
less_than_pi:
	sty %tmp1
	txa
	ply
	sta (%m_vec_p),y
	iny
	lda %tmp1
	sta (%m_vec_p),y
	rts
	.ctxend

	.context cos
	; re-use the sin context for the arguments and return value for cos.
cos:
	clc
	adc #64
	bra sin
	.ctxend

rot_matrix:
	.dsb 32, 0

	; set up:
	; [  cos x  0  sin x   0 ]
	; [    0    1    0     0 ]
	; [ -sin x  0  cos x   0 ]
	; [    0    0    0     1 ]

	; Make rotation matrix about Y axis, from angle held in accumulator.
	; corrupts A, X, Y.
	; this is dumb. Just write directly to rot_matrix, don't bother with
	; indirection.
	
	.context make_yrot_matrix
	
make_yrot_matrix:
	pha
	
	ldx #<rot_matrix
	stx %sin.m_vec_p
	ldx #>rot_matrix
	stx %sin.m_vec_p + 1
	
	; store "cos x"
	ldy #0
	jsr cos
	lda rot_matrix
	sta rot_matrix + 20
	lda rot_matrix + 1
	sta rot_matrix + 21

	; store "sin x"
	pla
	ldy #16
	jsr sin
	; and "-sin x"
	lda #0
	sec
	sbc rot_matrix + 16
	sta rot_matrix + 4
	lda #0
	sbc rot_matrix + 17
	sta rot_matrix + 5

	; store ones (256s).
	lda #1
	stz rot_matrix + 10
	sta rot_matrix + 11
	stz rot_matrix + 30
	sta rot_matrix + 31

	; store zeros.
	stz rot_matrix + 2
	stz rot_matrix + 3
	stz rot_matrix + 6
	stz rot_matrix + 7
	stz rot_matrix + 8
	stz rot_matrix + 9
	stz rot_matrix + 12
	stz rot_matrix + 13
	stz rot_matrix + 14
	stz rot_matrix + 15
	stz rot_matrix + 18
	stz rot_matrix + 19
	stz rot_matrix + 22
	stz rot_matrix + 23
	stz rot_matrix + 24
	stz rot_matrix + 25
	stz rot_matrix + 26
	stz rot_matrix + 27
	stz rot_matrix + 28
	stz rot_matrix + 29
	
	rts
	.ctxend

	; set up:
	; [ 1    0      0    0 ]
	; [ 0  cos x  sin x  0 ]
	; [ 0 -sin x  cos x  0 ]
	; [ 0    0      0    1 ]

	; Make rotation matrix about Y axis, from angle held in accumulator.
	; corrupts tmp1 (by calling sin/cos), A, X, Y.
	
	.context make_xrot_matrix
	
make_xrot_matrix:
	pha
	
	ldx #<rot_matrix
	stx %sin.m_vec_p
	ldx #>rot_matrix
	stx %sin.m_vec_p + 1
	
	; store "cos x"
	ldy #10
	jsr cos
	lda rot_matrix + 10
	sta rot_matrix + 20
	lda rot_matrix + 11
	sta rot_matrix + 21

	; store "sin x"
	pla
	ldy #18
	jsr sin
	; and "-sin x"
	lda #0
	sec
	sbc rot_matrix + 18
	sta rot_matrix + 12
	lda #0
	sbc rot_matrix + 19
	sta rot_matrix + 13

	; store ones (256s).
	lda #1
	stz rot_matrix
	sta rot_matrix + 1
	stz rot_matrix + 30
	sta rot_matrix + 31

	; store zeros.
	stz rot_matrix + 2
	stz rot_matrix + 3
	stz rot_matrix + 4
	stz rot_matrix + 5
	stz rot_matrix + 6
	stz rot_matrix + 7
	stz rot_matrix + 8
	stz rot_matrix + 9
	stz rot_matrix + 14
	stz rot_matrix + 15
	stz rot_matrix + 16
	stz rot_matrix + 17
	stz rot_matrix + 22
	stz rot_matrix + 23
	stz rot_matrix + 24
	stz rot_matrix + 25
	stz rot_matrix + 26
	stz rot_matrix + 27
	stz rot_matrix + 28
	stz rot_matrix + 29
	
	rts
	.ctxend

points:
	.word -20, -20, -20, 1
	.word  20, -20, -20, 1
	.word -20,  20, -20, 1
	.word  20,  20, -20, 1
	.word -20, -20,  20, 1
	.word  20, -20,  20, 1
	.word -20,  20,  20, 1
	.word  20,  20,  20, 1

xpoints:
	.dsb 48, 0
xpoints_old:
	.dsb 48, 0
xpoints_tmp:
	.dsb 48, 0

	; for faces, define normal vector.
;faces:
;	.word  0,  0, -1, 1
;	.word  1,  0,  0, 1
;	.word  0,  0,  1, 1
;	.word -1,  0,  0, 1
;	.word  0, -1,  0, 1
;	.word  0,  1,  0, 1

;xfaces:
;	.dsb 36, 0

;     6__________7          __________    
;     /:        /|         /:	5    /|
;   2/________3/ |        /________ / |
;   |  :      |  |       |  :	 2 |  |
;   |  :      |  |       |3 :	   | 1|
;   | 4:______|__|5      |  :_0____|__| 
;   | /       | /        | /   4   | / 
;   |/________|/         |/________|/
;   0         1           	    

; pt0, pt1, pt2, visible.
corners:
	.byte 6*2, 6*0, 6*1, 0
	.byte 6*3, 6*1, 6*5, 0
	.byte 6*7, 6*5, 6*4, 0
	.byte 6*6, 6*4, 6*0, 0
	.byte 6*0, 6*4, 6*5, 0
	.byte 6*6, 6*2, 6*3, 0

face_colours:
	.byte 1
	.byte 2
	.byte 3
	.byte 4
	.byte 5
	.byte 6

	; for lines, define start point, end point, left face, right face.
lines:
	.byte 0, 1, 0, 4
	.byte 1, 5, 1, 4
	.byte 5, 4, 2, 4
	.byte 4, 0, 3, 4
	.byte 0, 2, 3, 0
	.byte 1, 3, 0, 1
	.byte 4, 6, 2, 3
	.byte 5, 7, 1, 2
	.byte 2, 3, 5, 0
	.byte 3, 7, 5, 1
	.byte 7, 6, 5, 2
	.byte 6, 2, 5, 3

; OpenGL perspective transformation P looks like:
; [ 2n/(r-l)     0       (r+l)/(r-l)      0      ]
; [    0      2n/(t-b)   (t+b)/(t-b)      0      ]
; [    0         0      -(f+n)/(f-n)  -2fn/(f-n) ]
; [    0         0           -1           0      ]
; plug in n = 1, f = 40, l = -20, r = 20, t = 16, b = -16
;
; Camera matrix C looks like:
; [ 1  0  0  vx ]
; [ 0  1  0  vy ]
; [ 0  0  1  vz ]
; [ 0  0  0  1  ]
; plug in e.g. vx = 0, vy = 0, vz = 20
;
; Screen matrix S looks like: (are z/w sensible?)
; [ 80  0  0  0 ]
; [  0 128 0  0 ]
; [  0  0  1  0 ]
; [  0  0  0  1 ]
;
; We want to transform camera, then perspective, then screen. This is:
; S . P . C
; or, (multiplied by 256 for fixed-point), something like:
; [ 5120   0     0    0   ]
; [   0  10240   0    0   ]
; [   0    0   -262 -7842 ]
; [   0    0   -256 -5120 ]
; This matrix is calculated using the "viewmatrix.ml" program.

; (This is written transposed.)
transformation:
        .word 768, 0, 0, 0
        .word 0, 1536, 0, 0
        .word 0, 0, -475, -256
        .word 0, 0, -5851, 20480

; Multiply a column vector V with a 4x4 matrix M (16-bit elements).
; (16 bit elements, but max. -256..256). Result loses 8 least significant bits.
; m_mat is (fixed) zero-page location, m_vec_p is pointer to vector,
; m_result_p is pointer to result.
; [ $50 $58 $60 $68 ] ( ($4c),0 )
; [ $52 $5a $62 $6a ] ( ($4c),2 )
; [ $54 $5c $64 $6c ] ( ($4c),4 )
; [ $56 $5e $66 $6e ] ( ($4c),6 )

	.context matrix_mult
	.var2 m_vec_p, m_result_p

matrix_mult:
	phy
	phx
	ldx #0
row:
	lda m_mat,x
	sta %mult_16_8.alo
	lda m_mat+1,x
	sta %mult_16_8.ahi
	lda (%m_vec_p)
	sta %mult_16_8.blo
	ldy #1
	lda (%m_vec_p),y
	sta %mult_16_8.bhi
	jsr mult_16_8
	txa
	tay
	lda %mult_16_8.result+1
	sta (%m_result_p),y
	lda %mult_16_8.result+2
	iny
	sta (%m_result_p),y
	
	lda m_mat+8,x
	sta %mult_16_8.alo
	lda m_mat+9,x
	sta %mult_16_8.ahi
	ldy #2
	lda (%m_vec_p),y
	sta %mult_16_8.blo
	iny
	lda (%m_vec_p),y
	sta %mult_16_8.bhi
	jsr mult_16_8
	txa
	tay
	lda (%m_result_p),y
	clc
	adc %mult_16_8.result+1
	sta (%m_result_p),y
	iny
	lda (%m_result_p),y
	adc %mult_16_8.result+2
	sta (%m_result_p),y
	
	lda m_mat+16,x
	sta %mult_16_8.alo
	lda m_mat+17,x
	sta %mult_16_8.ahi
	ldy #4
	lda (%m_vec_p),y
	sta %mult_16_8.blo
	iny
	lda (%m_vec_p),y
	sta %mult_16_8.bhi
	jsr mult_16_8
	txa
	tay
	lda (%m_result_p),y
	clc
	adc %mult_16_8.result+1
	sta (%m_result_p),y
	iny
	lda (%m_result_p),y
	adc %mult_16_8.result+2
	sta (%m_result_p),y
	
	lda m_mat+24,x
	sta %mult_16_8.alo
	lda m_mat+25,x
	sta %mult_16_8.ahi
	ldy #6
	lda (%m_vec_p),y
	sta %mult_16_8.blo
	iny
	lda (%m_vec_p),y
	sta %mult_16_8.bhi
	jsr mult_16_8
	txa
	tay
	lda (%m_result_p),y
	clc
	adc %mult_16_8.result+1
	sta (%m_result_p),y
	iny
	lda (%m_result_p),y
	adc %mult_16_8.result+2
	sta (%m_result_p),y
	
	inx
	inx
	
	cpx #8
	beq finished
	bra row
finished:
	plx
	ply
	rts
	.ctxend

; exactly the same, but with a/b swapped for multiplication.
	.context matrix_mult_pre
	.var2 m_vec_p, m_result_p

matrix_mult_pre:
	phy
	phx
	ldx #0
row:
	lda m_mat,x
	sta %mult_16_8.blo
	lda m_mat+1,x
	sta %mult_16_8.bhi
	lda (%m_vec_p)
	sta %mult_16_8.alo
	ldy #1
	lda (%m_vec_p),y
	sta %mult_16_8.ahi
	jsr mult_16_8
	txa
	tay
	lda %mult_16_8.result+1
	sta (%m_result_p),y
	lda %mult_16_8.result+2
	iny
	sta (%m_result_p),y
	
	lda m_mat+8,x
	sta %mult_16_8.blo
	lda m_mat+9,x
	sta %mult_16_8.bhi
	ldy #2
	lda (%m_vec_p),y
	sta %mult_16_8.alo
	iny
	lda (%m_vec_p),y
	sta %mult_16_8.ahi
	jsr mult_16_8
	txa
	tay
	lda (%m_result_p),y
	clc
	adc %mult_16_8.result+1
	sta (%m_result_p),y
	iny
	lda (%m_result_p),y
	adc %mult_16_8.result+2
	sta (%m_result_p),y
	
	lda m_mat+16,x
	sta %mult_16_8.blo
	lda m_mat+17,x
	sta %mult_16_8.bhi
	ldy #4
	lda (%m_vec_p),y
	sta %mult_16_8.alo
	iny
	lda (%m_vec_p),y
	sta %mult_16_8.ahi
	jsr mult_16_8
	txa
	tay
	lda (%m_result_p),y
	clc
	adc %mult_16_8.result+1
	sta (%m_result_p),y
	iny
	lda (%m_result_p),y
	adc %mult_16_8.result+2
	sta (%m_result_p),y
	
	lda m_mat+24,x
	sta %mult_16_8.blo
	lda m_mat+25,x
	sta %mult_16_8.bhi
	ldy #6
	lda (%m_vec_p),y
	sta %mult_16_8.alo
	iny
	lda (%m_vec_p),y
	sta %mult_16_8.ahi
	jsr mult_16_8
	txa
	tay
	lda (%m_result_p),y
	clc
	adc %mult_16_8.result+1
	sta (%m_result_p),y
	iny
	lda (%m_result_p),y
	adc %mult_16_8.result+2
	sta (%m_result_p),y
	
	inx
	inx
	
	cpx #8
	bne row
finished:
	plx
	ply
	rts
	.ctxend

	; copy matrix at (M_VEC_P) to M_MAT (the global transformation matrix).

	.context copy_matrix
	.var2 m_vec_p

copy_matrix:
	ldy #0
loop:
	lda (%m_vec_p),y
	sta m_mat,y
	iny
	cpy #32
	bne loop
	rts
	.ctxend

	; transpose matrix at (arg1). Result in (arg0).
	; corrupts A, X, Y
	
	.context transpose_matrix
	.var2 arg0, arg1
	.var tmp0, tmp1
	
transpose_matrix:
	ldy #0
	stz %tmp0
loop:
	; load lo byte
	lda (%arg1),y
	tax
	iny
	sty %tmp1
	; load hi byte
	lda (%arg1),y
	ldy %tmp0
	iny
	; store hi byte
	sta (%arg0),y
	txa
	dey
	; store lo byte
	sta (%arg0),y
	
	tya
	clc
	adc #8
	cmp #31
	bcc still_doing_column
	; if we get to the end of a column, we want to go back to the start
	; of the next column. Subtract 30.
	sec
	sbc #30
still_doing_column:
	sta %tmp0
	
	lda %tmp1
	iny
	cpy #32
	bne loop
	rts
	.ctxend

tmp_matrix:
	.dsb 32, 0

	; do TMP_MATRIX = M_MAT x ROT_MATRIX.

	.context postmultiply_matrix

postmultiply_matrix:
	lda #<rot_matrix
	sta %matrix_mult.m_vec_p
	lda #>rot_matrix
	sta %matrix_mult.m_vec_p + 1
	
	lda #<tmp_matrix
	sta %matrix_mult.m_result_p
	lda #>tmp_matrix
	sta %matrix_mult.m_result_p + 1
	
	jsr matrix_mult

	lda #<[rot_matrix + 8]
	sta %matrix_mult.m_vec_p
	lda #>[rot_matrix + 8]
	sta %matrix_mult.m_vec_p + 1
	
	lda #<[tmp_matrix + 8]
	sta %matrix_mult.m_result_p
	lda #>[tmp_matrix + 8]
	sta %matrix_mult.m_result_p + 1
	
	jsr matrix_mult

	lda #<[rot_matrix + 16]
	sta %matrix_mult.m_vec_p
	lda #>[rot_matrix + 16]
	sta %matrix_mult.m_vec_p + 1
	
	lda #<[tmp_matrix + 16]
	sta %matrix_mult.m_result_p
	lda #>[tmp_matrix + 16]
	sta %matrix_mult.m_result_p + 1
	
	jsr matrix_mult

	lda #<[rot_matrix + 24]
	sta %matrix_mult.m_vec_p
	lda #>[rot_matrix + 24]
	sta %matrix_mult.m_vec_p + 1
	
	lda #<[tmp_matrix + 24] 
	sta %matrix_mult.m_result_p
	lda #>[tmp_matrix + 24]
	sta %matrix_mult.m_result_p + 1
	
	jsr matrix_mult

	rts
	.ctxend

	.context transform_points

transform_points:
	; m_vec_p points to first point.
	lda #<points
	sta %matrix_mult.m_vec_p
	lda #>points
	sta %matrix_mult.m_vec_p+1

	lda #<vec_tmp
	sta %matrix_mult.m_result_p
	lda #>vec_tmp
	sta %matrix_mult.m_result_p+1

	; these stay live throughout the function. Make sure that they don't
	; get clobbered by calls to other contexts.

	.protect %matrix_mult.m_vec_p
	.protect %matrix_mult.m_result_p

	ldx #0
iter:
	jsr matrix_mult
	
	; dehomogenise X
	lda (%matrix_mult.m_result_p)
	sta %scaled_div.in_a
	ldy #1
	lda (%matrix_mult.m_result_p),y
	sta %scaled_div.in_a + 1
	ldy #6
	lda (%matrix_mult.m_result_p),y
	sta %scaled_div.in_b
	iny
	lda (%matrix_mult.m_result_p),y
	sta %scaled_div.in_b + 1
	jsr scaled_div
	lda %scaled_div.result
	sta xpoints,x
	lda %scaled_div.result+1
	sta xpoints+1,x
	
	; dehomogenise Y
	ldy #2
	lda (%matrix_mult.m_result_p),y
	sta %scaled_div.in_a
	iny
	lda (%matrix_mult.m_result_p),y
	sta %scaled_div.in_a + 1
	ldy #6
	lda (%matrix_mult.m_result_p),y
	sta %scaled_div.in_b
	iny
	lda (%matrix_mult.m_result_p),y
	sta %scaled_div.in_b + 1
	jsr scaled_div
	lda %scaled_div.result
	sta xpoints+2,x
	lda %scaled_div.result+1
	sta xpoints+3,x
	
	; store Z, but don't bother de-homogenising (only used to crudely 
	; disambiguate depth).
	ldy #4
	lda (%matrix_mult.m_result_p),y
	sta xpoints+4,x
	iny
	lda (%matrix_mult.m_result_p),y
	sta xpoints+5,x
	
	; move to next input point
	lda %matrix_mult.m_vec_p
	clc
	adc #8
	sta %matrix_mult.m_vec_p
	.(
	bcc nohi
	inc %matrix_mult.m_vec_p+1
nohi:
	.)
	
	txa
	clc
	adc #6
	tax
	
	cpx #48
	bcc iter
	
	rts
	.ctxend

	.context plot_xpoint_y

	; emit coordinates (x*8, y*4) for transformed point at Y-register
	; index into xpoints. A corrupted, X, Y preserved.
plot_xpoint_y:
	pha
	lda #25
	jsr oswrch
	pla
	jsr oswrch
	
	; output x
	lda xpoints,y
	jsr oswrch
	lda xpoints+1,y
	jsr oswrch

	; output y
	lda xpoints+2,y
	jsr oswrch
	lda xpoints+3,y
	jsr oswrch
	
	rts
	.ctxend

rotation_amount:
	.byte 1

pixmask:
	.byte 0b00101010
	.byte 0b00010101

	; .include "test-render.s"

done_frames
	.byte 0

	.context test_render_offscreen
	.var first

test_render_offscreen:
	lda #0
	sta %first

	.protect %draw_offscreen_object.buffer

	stz %draw_offscreen_object.buffer
	stz done_frames

test_render_loop:
	lda #<transformation
	sta %copy_matrix.m_vec_p
	lda #>transformation
	sta %copy_matrix.m_vec_p + 1
	jsr copy_matrix

	lda rotation_amount
	jsr make_yrot_matrix
	jsr postmultiply_matrix
	
	; copy temp matrix back to m_mat.
	lda #<tmp_matrix
	sta %copy_matrix.m_vec_p
	lda #>tmp_matrix
	sta %copy_matrix.m_vec_p + 1
	jsr copy_matrix
	
	lda rotation_amount
	asl
	jsr make_xrot_matrix
	jsr postmultiply_matrix
	
	lda #<tmp_matrix
	sta %copy_matrix.m_vec_p
	lda #>tmp_matrix
	sta %copy_matrix.m_vec_p + 1
	jsr copy_matrix
	
	;jsr cls
	jsr transform_points
	jsr visibility
	jsr zero_row_length
	;jsr blank_various_buffers
	;jsr draw_object
	jsr draw_offscreen_object
	jsr cleanup_rows
	jsr render_scanline_diffs

	lda %draw_offscreen_object.buffer
	eor #1
	sta %draw_offscreen_object.buffer

	inc rotation_amount
	inc rotation_amount
	
	inc done_frames
	lda done_frames
	cmp #150
	bcc test_render_loop
	
	rts
	.ctxend

	.context visibility
	.var2 tmp
	.var corner0, corner1, corner2

visibility:
	ldx #0
do_corner:
	; [ahi:alo] = x2 - x0
	ldy corners + 2, x
	lda xpoints, y
	sty %corner2
	ldy corners, x
	sty %corner0
	sec
	sbc xpoints, y
	sta %mult_16_8.alo
	ldy %corner2
	lda xpoints + 1, y
	ldy %corner0
	sbc xpoints + 1, y
	sta %mult_16_8.ahi
	
	; [bhi:blo] = y1 - y0
	ldy corners + 1, x
	lda xpoints + 2, y
	sty %corner1
	ldy %corner0
	sec
	sbc xpoints + 2, y
	sta %mult_16_8.blo
	ldy %corner1
	lda xpoints + 3, y
	ldy %corner0
	sbc xpoints + 3, y
	sta %mult_16_8.bhi
	
	jsr mult_16_8
	
	lda %mult_16_8.result
	sta %tmp
	lda %mult_16_8.result + 1
	sta %tmp + 1
	
	; [ahi:alo] = y2 - y0
	ldy %corner2
	lda xpoints + 2, y
	ldy %corner0
	sec
	sbc xpoints + 2, y
	sta %mult_16_8.alo
	ldy %corner2
	lda xpoints + 3, y
	ldy %corner0
	sbc xpoints + 3, y
	sta %mult_16_8.ahi
	
	; [bhi:blo] = x1 - x0
	ldy %corner1
	lda xpoints, y
	ldy %corner0
	sec
	sbc xpoints, y
	sta %mult_16_8.blo
	ldy %corner1
	lda xpoints + 1, y
	ldy %corner0
	sbc xpoints + 1, y
	sta %mult_16_8.bhi
	
	jsr mult_16_8
	
	; fudge factor: take a bit away from tmp to avoid artifacts from thin
	; polygons.
	lda %tmp
	sec
	sbc #128
	sta %tmp
	.(
	bcs no_hi
	dec %tmp + 1
no_hi:
	.)
	
	; compare tmp, result signed greater than
	.(
	lda %tmp
	cmp %mult_16_8.result
	lda %tmp + 1
	sbc %mult_16_8.result + 1
	bvc skip
	eor #$80
skip:
	bpl greater
	stz corners + 3, x
	bra done
greater:
	lda #1
	sta corners + 3, x
done:
	.)
	
	txa
	clc
	adc #4
	tax
	
	cpx #24
	bne do_corner
	
	; no printing
	rts
	
	lda #30
	jsr oswrch
	;lda #10
	;jsr oswrch
	
	ldx #0
print:
	lda corners + 3, x
	clc
	adc #'0'
	jsr oswrch
	txa
	clc
	adc #4
	tax
	cpx #24
	bne print
	
	rts
	.ctxend

	.context zero_row_length
zero_row_length:
	ldx #0
	lda %draw_offscreen_object.buffer
	bne clear_buf_1
	.(
loop:
	stz row_length_0, x
	inx
	bne loop
	.)
	rts
clear_buf_1:
	.(
loop:
	stz row_length_1, x
	inx
	bne loop
	.)
	rts
	.ctxend

	.context blank_various_buffers
	.var2 columns, colours
	.var number
	
blank_various_buffers:
	.(
	lda %draw_offscreen_object.buffer
	bne buf1
	@const_word %columns, change_columns_0
	@const_word %colours, switch_colours_0
	bra done
buf1:
	@const_word %columns, change_columns_1
	@const_word %colours, switch_colours_1
done:
	.)
	lda #8
	sta %number
	
loop2:
	ldy #0
	lda #0
loop:
	sta (%columns),y
	sta (%colours),y
	iny
	bne loop
	inc %columns + 1
	inc %colours + 1
	dec %number
	bne loop2
	
	rts
	.ctxend

	.context draw_offscreen_object
	.var r_tmp1, visibility
	.var buffer
	.var2 midpoint_tmp

draw_offscreen_object:

	;lda #30
	;jsr oswrch

	ldx #0
loop:
	lda lines,x
	; multiply by 6
	asl
	sta %r_tmp1
	asl
	clc
	adc %r_tmp1
	tay
	
	lda xpoints,y
	clc
	adc #80
	sta %render_line.x_start
	lda xpoints+2,y
	clc
	adc #128
	sta %render_line.y_start
	lda xpoints+4,y
	sta %midpoint_tmp
	lda xpoints+5,y
	sta %midpoint_tmp + 1
	
	lda lines+1,x
	asl
	sta %r_tmp1
	asl
	clc
	adc %r_tmp1
	tay
	
	lda xpoints,y
	clc
	adc #80
	sta %render_line.x_end
	lda xpoints+2,y
	clc
	adc #128
	sta %render_line.y_end
	;lda %midpoint_tmp
	;clc
	;adc xpoints+4,y
	;sta %midpoint_tmp
	;lda %midpoint_tmp + 1
	;adc xpoints+5,y
	;sta %midpoint_tmp + 1
	
	; ??? check values for sanity
	;lda %midpoint_tmp
	;clc
	;adc #<256
	;sta %midpoint_tmp
	;lda %midpoint_tmp + 1
	;adc #>256
	;sta %midpoint_tmp + 1
	;lsr
	;ror %midpoint_tmp
	;lsr
	;ror %midpoint_tmp
	;lda %midpoint_tmp
	;sta %render_line.midpoint
	
	;jsr pr_hex
	;jsr pr_newl
	
	stz %visibility
	
	; left face
	ldy lines+2, x
	lda face_colours, y
	sta %render_line.lhs_colour
	tya
	asl
	asl
	tay
	lda corners+3, y
	.(
	bne visible
	stz %render_line.lhs_colour
	inc %visibility
visible:
	.)
	
	; right face
	ldy lines+3, x
	lda face_colours, y
	sta %render_line.rhs_colour
	tya
	asl
	asl
	tay
	lda corners+3, y
	.(
	bne visible
	stz %render_line.rhs_colour
	inc %visibility
visible:
	.)
	
	lda %visibility
	cmp #2
	beq invisible
	
	phx
	jsr render_line
	plx

invisible:

	txa
	clc
	adc #4
	tax
	
	cmp #48
	bne loop
	rts
	.ctxend

	; inputs: (x_start, y_start) (x_end, y_end)
	;         lhs_colour, rhs_colour

	.context render_line
	.var y_start, y_end
	.var x_start, x_end
	.var lhs_colour, rhs_colour
	.var colour_byte
	.var2 xpos, xdelta
	.var2 rows, column, colour
	.var2 tmp
	.var row_length, rightmost_left_of

render_line:
	.(
	lda %y_end
	cmp %y_start
	bcs right_way_up
	
	; flip Y
	lda %y_start
	ldx %y_end
	sta %y_end
	stx %y_start
	
	; flip X
	lda %x_start
	ldx %x_end
	sta %x_end
	stx %x_start

	lda %lhs_colour
	asl
	asl
	asl
	asl
	ora %rhs_colour
	sta %colour_byte

	bra done
right_way_up:
	lda %rhs_colour
	asl
	asl
	asl
	asl
	ora %lhs_colour
	sta %colour_byte
done:
	.)
	
	lda %x_end
	sec
	sbc %x_start
	pha
	lda #0
	sbc #0
	sta %scaled_div.in_a + 1
	pla
	asl
	rol %scaled_div.in_a + 1
	asl
	rol %scaled_div.in_a + 1
	asl
	rol %scaled_div.in_a + 1
	sta %scaled_div.in_a
	; now scaled_div.in_a in (x_end - x_start) * 8.
	
	lda %y_end
	sec
	sbc %y_start
	sta %scaled_div.in_b
	stz %scaled_div.in_b + 1
	
	jsr scaled_div
	
	lda %scaled_div.result
	sta %xdelta
	lda %scaled_div.result + 1
	sta %xdelta + 1
	
	; put X start in (high byte of) xpos.
	lda %x_start
	sta %xpos + 1
	stz %xpos
	
	; now xpos, xdelta should be set correctly.

	.(
	lda %draw_offscreen_object.buffer
	bne buf1
	lda #<row_length_0
	sta %rows
	lda #>row_length_0
	sta %rows + 1
	bra done
buf1:
	lda #<row_length_1
	sta %rows
	lda #>row_length_1
	sta %rows + 1
done:
	.)

	lda %y_start
	sta %tmp
	lda #0
	; [A:%tmp] = %y_start * 8 (columns_per_row)
	asl %tmp
	rol
	asl %tmp
	rol
	asl %tmp
	rol
	sta %tmp + 1
	
	.(
	lda %draw_offscreen_object.buffer
	bne buf1
	
	lda #<change_columns_0
	clc
	adc %tmp
	sta %column
	lda #>change_columns_0
	adc %tmp + 1
	sta %column + 1
	
	lda #<switch_colours_0
	clc
	adc %tmp
	sta %colour
	lda #>switch_colours_0
	adc %tmp + 1
	sta %colour + 1
	
	bra done
buf1:
	lda #<change_columns_1
	clc
	adc %tmp
	sta %column
	lda #>change_columns_1
	adc %tmp + 1
	sta %column + 1
	
	lda #<switch_colours_1
	clc
	adc %tmp
	sta %colour
	lda #>switch_colours_1
	adc %tmp + 1
	sta %colour + 1
done:
	.)
		
loop:
	ldy %y_start
	lda (%rows), y
	sta %row_length
	
	.(
	lda #255
	sta %rightmost_left_of
	
	.(
	; first one...
	lda %row_length
	beq done

	ldy #0
search:
	lda (%column), y
	cmp %xpos + 1
	bcs done
	sty %rightmost_left_of
	
	iny
	cpy %row_length
	bcc search
done
	.)

	;	  y=0	  y=1
	;     N   O1      O2       (%rightmost_left_of = 255)
	;         O1   N  O2       (%rightmost_left_of = 0)
	;         O1      O2   N   (%rightmost_left_of = 1)

	lda %rightmost_left_of
	inc
	sta %rightmost_left_of
	cmp %row_length
	beq insert_at_end

	; say %row_length is 4 initially, rightmost_left_of is 1. So we have:
	;       O1    O2     O3    O4
	;                 N
	; shuffle
	;     dey			// y = 3   2   1
	;     lda (%column), y
	;     iny			// y = 4   3   2
	;     sta (%column), y
	;     dey			// y = 3   2   1
	;     cpy %rightmost_left_of	//     1   1   1
	;     bne shuffle

	ldy %row_length
shuffle
	dey
	lda (%column), y
	tax
	lda (%colour), y
	iny
	sta (%colour), y
	txa
	sta (%column), y
	dey
	cpy %rightmost_left_of
	bne shuffle

insert_at_end
	inc %row_length

do_insert
	ldy %rightmost_left_of
	lda %xpos + 1
	sta (%column), y
	
	lda %colour_byte
	sta (%colour), y
	
	lda %row_length
	ldy %y_start
	sta (%rows), y
	
	.)
	
	;cpy #8
	;bcs overflow
		
	lda %xpos
	clc
	adc %xdelta
	sta %xpos
	lda %xpos + 1
	adc %xdelta + 1
	sta %xpos + 1
	
	; move to next scanline for column
	lda %column
	clc
	adc #columns_per_row
	sta %column
	.(
	bcc no_hi
	inc %column + 1
no_hi:
	.)
	
	; move to next scanline for colour
	lda %colour
	clc
	adc #columns_per_row
	sta %colour
	.(
	bcc no_hi
	inc %colour + 1
no_hi:
	.)
	
	inc %y_start
	lda %y_start
	cmp %y_end
	bcc loop
	
	rts
	
overflow:
	lda #'E'
	jsr oswrch
	rts
	.ctxend

	.context cleanup_rows
	.var2 rows, column, colour
	.var row, idx, min_idx, num
	.var closest, write_idx, copy_from
	.var merged_colour
	
cleanup_rows:
	.(
	lda %draw_offscreen_object.buffer
	bne buf1
	
	@const_word %rows, row_length_0
	@const_word %column, change_columns_0
	@const_word %colour, switch_colours_0
	bra done
buf1:
	@const_word %rows, row_length_1
	@const_word %column, change_columns_1
	@const_word %colour, switch_colours_1
done:
	.)
	
	stz %row
loop:
	ldy %row
	lda (%rows), y
	cmp #2
	bcc row_empty
	sta %num

	; Do a quick check: are any column positions overlapping?
	.(
	ldy #0
	lda (%column), y
any_the_same:
	iny
	cpy %num
	beq row_empty
	cmp (%column), y
	beq one_same
	lda (%column), y
	bra any_the_same
one_same
	
	; check...
;	ldy #0
;	lda #7
;overwrite
;	sta (%colour), y
;	iny
;	cpy %num
;	bne overwrite
	
	.)

	; we're re-using variables here, be careful.
	.(
	stz %min_idx
	stz %write_idx
	
cleanup:
	.(
	;jmp skip_cleanup
	ldy %min_idx
	lda (%column),y
find_bounds:
	iny
	cpy %num
	bcs different
	cmp (%column),y
	beq find_bounds
different:
	sty %idx
	.)
	; now min_idx (inclusive) to idx (exclusive) should have the same
	; column positions.
	
	lda %min_idx
	sta %copy_from
	
	.(
	lda %idx
	sec
	sbc %min_idx
	cmp #2
	bcc only_1
	bne not_2
	
	; Both columns change to same RHS colour (doesn't help).
	;ldy %min_idx
	;lda (%colour),y
	;and #15
	;sta %merged_colour
	;iny
	;lda (%colour),y
	;and #15
	;cmp %merged_colour
	;beq done
	
	ldy %min_idx
	lda (%colour),y
	pha
	lsr
	lsr
	lsr
	lsr
	sta %merged_colour
	iny
	lda (%colour),y
	and #15
	cmp %merged_colour
	beq use_stacked_rhs
	pla
	and #15
	sta %merged_colour
	lda (%colour),y
	pha
	lsr
	lsr
	lsr
	lsr
	cmp %merged_colour
	beq use_stacked_rhs
	; drop stack top
	pla
	lda #7
	sta %merged_colour
	bra done
use_stacked_rhs:
	.(
	ldy %min_idx
	iny
	iny
	cpy %num
	bcs really_use_stacked
	; drop
	pla
	; use next LHS colour
	lda (%colour),y
	lsr
	lsr
	lsr
	lsr
	sta %merged_colour
	bra done
really_use_stacked:
	pla
	;and #15
	; this makes no sense at all?
	lda #7
	sta %merged_colour
	bra done
	.)
not_2:
	; a complicated corner. Choose black and hope for the best.
	lda #0
	sta %merged_colour
	bra done
only_1:
	ldy %copy_from
	lda (%colour),y
	sta %merged_colour
done:
	.)
	
	lda %idx
	sta %min_idx

	.(
	ldy %copy_from
	cpy %write_idx
	beq skip_copying
	; these two shouldn't be necessary...
	;cpy #255
	;beq skip_copying
	lda (%column),y
	ldy %write_idx
	sta (%column),y
skip_copying:
	ldy %write_idx
	lda %merged_colour
	sta (%colour),y
	inc %write_idx
	.)

	lda %min_idx
	cmp %num

	bcc cleanup
	
	ldy %row
	lda %write_idx
	sta (%rows), y
skip_cleanup:
	.)

row_empty:

	; move to next row of columns
	@addw_small_const %column, columns_per_row

	; move to next row of colours
	@addw_small_const %colour, columns_per_row

	inc %row
	bne loop
	
	rts
	.ctxend

	; A = new graphics colour
	.context set_gcol
set_gcol:
	pha
	lda #18
	jsr oswrch
	lda #0
	jsr oswrch
	pla
	jsr oswrch
	rts
	.ctxend

	; draw horizontal line from xstart,ypos to xend,ypos.
	; ypos is in OS units, but xstart & xend are in pixels.

	.context horiz_line
	.var2 ypos
	.var xstart, xend
horiz_line:
	; move to start...
	lda #25
	jsr oswrch
	lda #4
	jsr oswrch
	lda #0
	asl %xstart
	rol
	asl %xstart
	rol
	asl %xstart
	rol
	pha
	lda %xstart
	jsr oswrch
	pla
	jsr oswrch
	lda %ypos
	jsr oswrch
	lda %ypos + 1
	jsr oswrch
	
	; draw to end.
	lda #25
	jsr oswrch
	lda #5
	jsr oswrch
	lda #0
	asl %xend
	rol
	asl %xend
	rol
	asl %xend
	rol
	pha
	lda %xend
	jsr oswrch
	pla
	jsr oswrch
	lda %ypos
	jsr oswrch
	lda %ypos + 1
	jsr oswrch
	
	rts
	.ctxend

	.macro const_word dst val
	lda #<%val
	sta %dst
	lda #>%val
	sta %dst + 1
	.mend

	.macro addw_small_const dst cst
	lda %dst
	clc
	adc #%cst
	sta %dst
	bcc no_hi
	inc %dst + 1
no_hi:
	.mend

	.context render_scanline_diffs
	.var2 rows_current, column_current, colour_current
	.var2 rows_prev, column_prev, colour_prev
	.var2 ypos
	.var scanline, cur_idx, prev_idx
	.var cur_length, prev_length, next_x_cur, next_x_prev
	.var p_fill, c_fill, fill_next, upto_column, last_column
	.var last_cfill, last_cfill_column
	
render_scanline_diffs:
	.(
	lda %draw_offscreen_object.buffer
	bne buf1

	; current buffer is #0.
	@const_word %rows_current, row_length_0
	@const_word %rows_prev, row_length_1
	
	@const_word %column_current, change_columns_0
	@const_word %column_prev, change_columns_1
	
	@const_word %colour_current, switch_colours_0
	@const_word %colour_prev, switch_colours_1

	bra done
buf1:
	; current buffer is #1.
	@const_word %rows_current, row_length_1
	@const_word %rows_prev, row_length_0
	
	@const_word %column_current, change_columns_1
	@const_word %column_prev, change_columns_0
	
	@const_word %colour_current, switch_colours_1
	@const_word %colour_prev, switch_colours_0
done:
	.)
	
	stz %scanline
	@const_word %ypos, 0x3000
plot_row:
	ldy %scanline
	lda (%rows_current),y
	sta %cur_length
	
	lda (%rows_prev),y
	sta %prev_length

	ora %cur_length
	beq nothing_to_do

	stz %cur_idx
	stz %prev_idx

	stz %fill_next
	stz %last_column
	stz %upto_column
	stz %c_fill
	stz %p_fill

	.(
plot_pieces:
	lda #255
	sta %next_x_cur
	sta %next_x_prev

	ldy %cur_idx
	cpy %cur_length
	bcs no_more_current
	lda (%column_current),y
	sta %next_x_cur
no_more_current:
	ldy %prev_idx
	cpy %prev_length
	bcs no_more_prev
	lda (%column_prev),y
	sta %next_x_prev
no_more_prev:
	
	.(
	lda %next_x_prev
	cmp #255
	beq end_of_prev
	lda %next_x_cur
	cmp #255
	beq previous_changes_next
	; neither previous nor next are 255.
	cmp %next_x_prev
	bcc current_changes_next
	bra previous_changes_next
end_of_prev:
	lda %next_x_cur
	cmp #255
	beq finished
	bra current_changes_next
	.)

previous_changes_next:
	; previous changes first...

	ldy %prev_idx
	lda %next_x_prev
	sta %upto_column
;	cmp %last_column
;	.(
;	bne not_zero_length
;	iny
;	sty %prev_idx
;	bra skip_filling
;not_zero_length:
;	.)

	lda (%colour_prev),y
	and #15
	sta %p_fill
	iny
	sty %prev_idx
	bra render_piece
	
current_changes_next:
	ldy %cur_idx
	lda %next_x_cur
	sta %upto_column
	sta %last_cfill_column
;	cmp %last_column
;	.(
;	bne not_zero_length
;	stz %c_fill
;	iny
;	sty %cur_idx
;	bra skip_filling
;not_zero_length:
;	.)

	lda (%colour_current),y
	and #15
	sta %c_fill
	iny
	sty %cur_idx

render_piece:
	lda %fill_next
	beq skip_filling

	lda %last_cfill
	sta %hline.colour

	lda %last_column
	sta %hline.xstart
	
	lda %upto_column
	sta %hline.xend
	
	jsr hline

skip_filling:
	lda %upto_column
	sta %last_column

	lda %c_fill
	sta %last_cfill
	sec
	sbc %p_fill
	;lda #1
	sta %fill_next
	
	bra plot_pieces
finished:
	.)

	; deal with badly-formed data. Easier than fixing it up properly?
	lda %c_fill
	beq nothing_to_do
	
	lda %last_cfill_column
	sta %hline.xstart

	ldy %prev_length
	beq nothing_to_do
	dey
	lda (%column_prev),y
	ldy %cur_length
	beq nothing_to_do
	dey
	cmp (%column_current),y
	bcc nothing_to_do

	; previous is higher. Blank rest of line.
	sta %hline.xend
	stz %hline.colour
	jsr hline

nothing_to_do:

	.(
	lda %ypos
	and #7
	cmp #7
	beq add_row
	.(
	inc %ypos
	bne no_hi
	inc %ypos + 1
no_hi:
	.)
	bra done
add_row:
	lda %ypos
	clc
	adc #<[640-7]
	sta %ypos
	lda %ypos + 1
	adc #>[640-7]
	sta %ypos + 1
done:
	.)

	@addw_small_const %column_current, columns_per_row
	@addw_small_const %column_prev, columns_per_row
	@addw_small_const %colour_current, columns_per_row
	@addw_small_const %colour_prev, columns_per_row
	
	inc %scanline
	bne plot_row

	rts
	.ctxend

colours:
	.byte 0b00000000
	.byte 0b00000011
	.byte 0b00001100
	.byte 0b00001111
	.byte 0b00110000
	.byte 0b00110011
	.byte 0b00111100
	.byte 0b00111111

	.context hline
	.var xstart, xend
	.var colour, tmp
	.var2 ptr
hline:
	ldx %colour
	lda colours,x
	sta %colour

	lda %xend
	sec
	sbc %xstart
	tax
	beq done

	lda %xstart
	and #$fe
	sta %ptr
	lda #0
	asl %ptr
	rol
	asl %ptr
	rol
	sta %ptr + 1
	lda %render_scanline_diffs.ypos
	clc
	adc %ptr
	sta %ptr
	lda %render_scanline_diffs.ypos + 1
	adc %ptr + 1
	sta %ptr + 1
	.(
	lda #1
	bit %xstart
	beq no_first_pixel
	lda (%ptr)
	and #0b10101010
	sta %tmp
	lda %colour
	and #0b01010101
	ora %tmp
	sta (%ptr)
	lda %ptr
	clc
	adc #8
	sta %ptr
	.(
	bcc no_hi
	inc %ptr + 1
no_hi:
	.)
	dex
	beq done
no_first_pixel:
	.)
	; halve length.
	txa
	lsr
	tax
	beq maybe_draw_end_pixel
	ldy %colour
loop:
	tya
	sta (%ptr)
	lda %ptr
	clc
	adc #8
	sta %ptr
	.(
	bcc no_hi
	inc %ptr + 1
no_hi:
	.)
	dex
	bne loop

maybe_draw_end_pixel:
	.(
	lda #1
	bit %xend
	beq no_last_pixel
	lda (%ptr)
	and #0b01010101
	sta %tmp
	lda %colour
	and #0b10101010
	ora %tmp
	sta (%ptr)
no_last_pixel:
	.)
done:
	rts
	.ctxend

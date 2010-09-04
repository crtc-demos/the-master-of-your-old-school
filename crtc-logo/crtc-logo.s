	.temps $70..$8f

	.org $1200

entry:
	lda #0
	jsr mos_setmode
	jsr mos_cursoroff
	
	jsr player_init
	
	lda #12
	jsr oswrch
	
	jsr init_irq
	
	@load_file_to blank_rle, end_of_program

	ldx #<end_of_program
	ldy #>end_of_program
	jsr do_unpack
	
	lda #<end_of_program
	sta b2c_ptr
	lda #>end_of_program
	sta b2c_ptr + 1
	
	@load_file_via b2c_rle, b2c_ptr
	
	lda #<end_of_program
	clc
	adc osfile_blk + 10
	sta c2r_ptr
	lda #>end_of_program
	adc osfile_blk + 11
	sta c2r_ptr + 1
	
	@load_file_via c2r_rle, c2r_ptr
	
	lda c2r_ptr
	clc
	adc osfile_blk + 10
	sta r2t_ptr
	lda c2r_ptr + 1
	adc osfile_blk + 11
	sta r2t_ptr + 1
	
	@load_file_via r2t_rle, r2t_ptr

	lda r2t_ptr
	clc
	adc osfile_blk + 10
	sta t2c_ptr
	lda r2t_ptr + 1
	adc osfile_blk + 11
	sta t2c_ptr + 1

	@load_file_via t2c_rle, t2c_ptr

	jsr player_vsync_event_enable
	
	jsr wait_a_while

	stz number_of_times

lots_of_times:
	ldx b2c_ptr
	ldy b2c_ptr + 1
	jsr do_unpack

	jsr wait_a_while

	ldx c2r_ptr
	ldy c2r_ptr + 1
	jsr do_unpack

	jsr wait_a_while

	ldx r2t_ptr
	ldy r2t_ptr + 1
	jsr do_unpack

	jsr wait_a_while

	ldx t2c_ptr
	ldy t2c_ptr + 1
	jsr do_unpack

	jsr wait_a_while

	ldx b2c_ptr
	ldy b2c_ptr + 1
	jsr do_unpack

	jsr wait_a_while

	inc number_of_times
	lda number_of_times
	cmp #3
	bcc lots_of_times

	jsr player_vsync_event_disable
	jsr uninit_irq
	jsr player_unselect_sram

	ldx #<next_effect
	ldy #>next_effect
	jsr oscli

	rts

next_effect
	.asc "run O.MAIN",13
;	.asc "splitp",13

number_of_times:
	.byte 0

start_time:
	.word 0
current_time:
	.word 0

wait_a_while:
	.(
	sei
	lda player_frame_no
	sta start_time
	lda player_frame_no
	sta start_time + 1
	cli
	
loop:
	sei
	lda player_frame_no
	sta current_time
	lda player_frame_no + 1
	sta current_time + 1
	cli
	
	lda current_time
	sec
	sbc start_time
	sta current_time
	lda current_time + 1
	sbc start_time + 1
	sta current_time + 1
	
	lda current_time
	cmp #50
	bcc loop
	
	rts
	.)

b2c_ptr
	.word 0x0

c2r_ptr
	.word 0x0

r2t_ptr
	.word 0x0

t2c_ptr
	.word 0x0

	; Unpack data in Y:X to screen address.
do_unpack:
	stx %unpack_rle.start_address
	sty %unpack_rle.start_address + 1
	lda #<$3000
	sta %unpack_rle.screenptr
	lda #>$3000
	sta %unpack_rle.screenptr + 1
	jmp unpack_rle	

	.context unpack_rle
	; Inputs:
	;    start_address: start of RLE data
	;    screenptr: output pointer.
	.var2 start_address, screenptr
	.var length, eor_byte
unpack_rle:

rle_loop:
	; byte to write
	ldy #1
	lda (%start_address), y
	sta %eor_byte

	; ...this number of times
	lda (%start_address)
	sta %length
	tay

	lda %eor_byte
	beq skip_filling

	.(
fill_loop
	dey
	lda (%screenptr), y
	eor %eor_byte
	sta (%screenptr), y
	cpy #0
	bne fill_loop
	.)

skip_filling
	.(
	lda %length
	beq length_256

	clc
	adc %screenptr
	sta %screenptr
	bcc no_hi
length_256:
	inc %screenptr + 1
no_hi
	.)
	
	lda %start_address
	clc
	adc #2
	sta %start_address
	.(
	bcc no_hi
	inc %start_address + 1
no_hi
	.)

	lda %screenptr + 1
	cmp #$80
	bcc rle_loop

	rts
	.ctxend

	.include "../lib/mos.s"
	.include "../lib/load.s"
	.include "../lib/sram.s"
	.include "../lib/player.s"
	
blank_rle:
	.asc "blkrle",13

b2c_rle:
	.asc "b2crle",13

c2r_rle:
	.asc "c2rrle",13

r2t_rle:
	.asc "r2trle",13

t2c_rle:
	.asc "t2crle",13

oldirq1v:
	.word 0

fliptime:
	.word 64 * 16

init_irq:
	lda $204
	sta oldirq1v
	lda $205
	sta oldirq1v + 1
	
	sei

	lda #<irq1
	sta $204
	lda #>irq1
	sta $205
	
	lda fliptime
	sta USR_T1L_L
	lda fliptime + 1
	sta USR_T1L_H
	
	lda fliptime
	sta USR_T1C_L
	lda fliptime + 1
	sta USR_T1C_H

	; Generate stream of interrupts
	lda USR_ACR
	and #0b00111111
	ora #0b01000000
	sta USR_ACR

	; Enable usr timer1 interrupt
	lda #0b11000000
	sta USR_IER

	cli
	rts

uninit_irq
	sei
	; Disable usr timer1 interrupt
	lda #0b01000000
	sta USR_IER
	
	; restore old IRQ handler
	lda oldirq1v
	sta $204
	lda oldirq1v + 1
	sta $205
	
	cli
	rts

which_pal:
	.byte 0

irq1:
	lda $fc
	pha
	
	lda #64
	bit USR_IFR
	beq not_timer1

	; Clear interrupt
	lda USR_T1C_L
	
	lda which_pal
	eor #1
	sta which_pal
	bne second_pal
	
	lda #0b10000100
	sta PALCONTROL
	lda #0b10010100
	sta PALCONTROL
	lda #0b10100100
	sta PALCONTROL
	lda #0b10110100
	sta PALCONTROL
	lda #0b11000100
	sta PALCONTROL
	lda #0b11010100
	sta PALCONTROL
	lda #0b11100100
	sta PALCONTROL
	lda #0b11110100
	sta PALCONTROL

	bra done_switching

second_pal	
	lda #0b10000101
	sta PALCONTROL
	lda #0b10010101
	sta PALCONTROL
	lda #0b10100101
	sta PALCONTROL
	lda #0b10110101
	sta PALCONTROL
	lda #0b11000101
	sta PALCONTROL
	lda #0b11010101
	sta PALCONTROL
	lda #0b11100101
	sta PALCONTROL
	lda #0b11110101
	sta PALCONTROL

done_switching
not_timer1
	pla
	sta $fc
	jmp (oldirq1v)

end_of_program:

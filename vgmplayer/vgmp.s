	.org $e00

	; two bytes
	.alias trackptr 0x20
	; three bytes
	.alias real_time 0x22
	; three bytes
	.alias track_time 0x25

	.macro incw var
	inc %var
	lda %var
	bne no_hi
	inc %var + 1
no_hi:
	.mend

	.macro addw_small_const var cst
	lda %var
	clc
	adc #%cst
	sta %var
	bcc no_hi
	inc %var + 1
no_hi:
	.mend

	; greater than or equal, three byte quantities
	;   a+2 > b+2
	;   || (a+2 == b+2 && a+1 > b+1)
	;   || (a+1 == b+1 && a >= b)

	.macro cmpt_geu a b dst
	lda %a+2
	cmp %b+2
	bcc skip
	bne %dst
	lda %a+1
	cmp %b+1
	bcc skip
	bne %dst
	lda %a
	cmp %b
	bcs %dst
skip:
	.mend

start:
	@load_file_to trackname, tune
	
	lda #<tune
	sta trackptr
	lda #>tune
	sta trackptr + 1
	
	.(
	ldy #0x1c
	lda (trackptr), y
	bne set_loop_point
	iny
	lda (trackptr), y
	bne set_loop_point
	iny
	lda (trackptr), y
	bne set_loop_point
	iny
	lda (trackptr), y
	bne set_loop_point
	bra no_loop_point
set_loop_point
	ldy #0x1c
	lda (trackptr), y
	sta loop_point
	iny
	lda (trackptr), y
	sta loop_point + 1
no_loop_point
	.)
	
	.(
	ldy #0x34
	lda (trackptr), y
	bne not_zero
	iny
	lda (trackptr), y
	bne not_zero
	iny
	lda (trackptr), y
	bne not_zero
	iny
	lda (trackptr), y
	bne not_zero
	
	; if 32-bit word at offset 0x34 is zero, track data starts 0x40 bytes
	; into track.
	lda #<tune
	clc
	adc #0x40
	sta trackptr
	lda #>tune
	adc #0
	sta trackptr + 1
	
	bra setup_playing
	
not_zero:
	.)

	; if 32-bit word at 0x34 is non-zero, it specifies the offset to the
	; start of track data.
	
	ldy #0x34
	lda #<tune
	clc
	adc (trackptr), y
	sta trackptr
	iny
	lda #>tune
	adc (trackptr), y
	sta trackptr + 1

setup_playing
	stz real_time
	stz real_time + 1
	stz real_time + 2
	
	stz track_time
	stz track_time + 1
	stz track_time + 2
	
consume_bytes:
	lda (trackptr)
	
	; Hmm, implement as jump table perhaps?
	cmp #0x50
	beq write_psg
	cmp #0x61
	beq wait_n_samples
	cmp #0x62
	beq wait_735_samples
	cmp #0x63
	beq wait_882_samples
	cmp #0x4f
	beq ignore_byte
	cmp #0x51
	beq ignore_two_bytes
	cmp #0x52
	beq ignore_two_bytes
	cmp #0x53
	beq ignore_two_bytes
	cmp #0x54
	beq ignore_two_bytes
	cmp #0x66
	beq end_of_sound_data
	cmp #0x67
	beq data_block
	cmp #0xe0
	beq ignore_four_bytes

	and #0xf0

	cmp #0x70
	beq wait_short_nplus1_samples
	cmp #0x80
	beq wait_short_n_samples
	cmp #0x30
	beq ignore_byte
	cmp #0x40
	beq ignore_byte
	cmp #0x50
	beq ignore_two_bytes
	cmp #0xa0
	beq ignore_two_bytes
	cmp #0xb0
	beq ignore_two_bytes
	cmp #0xc0
	beq ignore_three_bytes
	cmp #0xd0
	beq ignore_three_bytes
	cmp #0xe0
	beq ignore_four_bytes
	cmp #0xf0
	beq ignore_four_bytes
	
ignore_byte:
	@addw_small_const trackptr, 2
	jmp consume_bytes

ignore_two_bytes:
	@addw_small_const trackptr, 3
	jmp consume_bytes

ignore_three_bytes:
	@addw_small_const trackptr, 4
	jmp consume_bytes

ignore_four_bytes:
	@addw_small_const trackptr, 5
	jmp consume_bytes

wait_n_samples
	ldy #1
	lda (trackptr), y
	tax
	iny
	lda (trackptr), y
	tay
	
	; add 2 bytes now: wait_xy_samples adds another byte.
	@addw_small_const trackptr, 2
	
	bra wait_xy_samples

wait_735_samples
	ldx #<735
	ldy #>735
	bra wait_xy_samples
	
wait_882_samples
	ldx #<882
	ldy #>882
	bra wait_xy_samples
	
wait_short_nplus1_samples
	lda (trackptr)
	and #0xf
	inc
	tax
	ldy #0
	bra wait_xy_samples

wait_short_n_samples
	lda (trackptr)
	and #0xf
	tax
	ldy #0

wait_xy_samples
	txa
	clc
	adc track_time
	sta track_time
	tya
	adc track_time + 1
	sta track_time + 1
	lda #0
	adc track_time + 2
	sta track_time + 2

	@incw trackptr
	
	; if track_time is greater than or equal to real_time, wait for vsync.
	;   track_time+2 > real_time+2
	;   || (track_time+2 == real_time+2 && track_time+1 > real_time+1)
	;   || (track_time+1 == real_time+1 && track_time >= real_time)
	@cmpt_geu track_time, real_time, wait_for_frame
	
	jmp consume_bytes

data_block
	ldy #3
	lda (trackptr), y
	tax
	iny
	lda (trackptr), y
	tay
	
	; skip data size
	txa
	clc
	adc trackptr
	sta trackptr
	tya
	adc trackptr + 1
	sta trackptr + 1
	
	; skip header size also
	@addw_small_const trackptr, 7
	
	jmp consume_bytes

write_psg
	ldy #1
	lda (trackptr), y

	sei

	; all lines to output
	ldy #255
	sty $fe43

	sta $fe41
	; sound generator write strobe. Should be low for 8ms (8us?). Each
	; NOP is 2 cycles, so 1us.
	stz $fe40
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	lda #$08
	sta $fe40
	
	cli
	
	lda #'A'
	jsr oswrch
	
	@addw_small_const trackptr, 2
	jmp consume_bytes

wait_for_frame
	; wait 1 video frame, 882 samples
	lda #19
	jsr osbyte
	
	lda #'F'
	jsr oswrch
	
	lda real_time
	clc
	adc #<882
	sta real_time
	lda real_time + 1
	adc #>882
	sta real_time + 1
	lda real_time + 2
	adc #0
	sta real_time + 2
	
	jmp consume_bytes
		
end_of_sound_data:
	.(
	lda loop_point
	bne loop_point_nonzero
	lda loop_point + 1
	bne loop_point_nonzero
	bra loop_point_unset
loop_point_nonzero
	lda loop_point
	clc
	adc #0x1c
	sta trackptr
	lda loop_point + 1
	adc #0
	sta trackptr + 1

	lda trackptr
	clc
	adc #<tune
	sta trackptr
	lda trackptr + 1
	adc #>tune
	sta trackptr + 1

	jmp consume_bytes
	
loop_point_unset
	.)

	rts

loop_point:
	.word 0

trackname:
	.asc "track",13

	.include "../lib/mos.s"
	.include "../lib/load.s"

tune:

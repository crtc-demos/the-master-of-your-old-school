	.org $e00

	; two bytes
	.alias trackptr 0x20
	; three bytes
	.alias real_time 0x22
	; three bytes
	.alias track_time 0x25
	; two bytes
	.alias frame_no 0x28

	.temps 0x2a..0x2f

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
	;   a[2] > b[2]
	;   || (a[2] == b[2] && a[1] > b[1])
	;   || (a[2] == b[2] && a[1] == b[1] && a[0] >= b[0])

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

	; entry points. Must keep in sync with list in player.s!
	jmp start
	jmp consume_bytes_noirq
	jmp consume_bytes_irq
	jmp vsync_event_enable
	jmp vsync_event_disable
	jmp select_sram
	jmp select_old_lang

consume_bytes_noirq
	stz from_irq
	jmp poll_player

consume_bytes_irq
	lda #1
	sta from_irq
	jmp poll_player

old_eventv:
	.word 0

vsync_event_enable
	sei

	stz frame_no
	stz frame_no + 1

	lda $220
	sta old_eventv
	lda $221
	sta old_eventv + 1
	
	lda #<player_event
	sta $220
	lda #>player_event
	sta $221
	
	cli
	
	lda #14
	ldx #4
	jsr osbyte
	
	rts

vsync_event_disable
	sei

	lda old_eventv
	sta $220
	lda old_eventv + 1
	sta $221
	
	cli
	
	lda #13
	ldx #4
	jsr osbyte
	
	rts

player_event
	.(
	cmp #4
	bne done

	jmp consume_bytes_irq
done
	jmp (old_eventv)
	.)

	.alias tune $8000

start:
	.(
	@load_file_to musix, $3000
	
	jsr select_sram
	
	ldx #<tune
	ldy #>tune
	lda #[16*1024]/256
	jsr copy_to_sram

	lda #<tune
	sta pattern_hdr
	lda #>tune
	sta pattern_hdr + 1
	jsr skip_header
	
	stz real_time
	stz real_time + 1
	stz real_time + 2
	
	stz track_time
	stz track_time + 1
	stz track_time + 2
	rts
	.)

pattern_hdr
	.word 0

skip_header
	.(
	lda pattern_hdr
	sta trackptr
	lda pattern_hdr + 1
	sta trackptr + 1
	
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
	lda pattern_hdr
	clc
	adc #0x40
	sta trackptr
	lda pattern_hdr + 1
	adc #0
	sta trackptr + 1

	rts
	
not_zero:

	; if 32-bit word at 0x34 is non-zero, it specifies the offset to the
	; start of track data.
	
	ldy #0x34
	lda pattern_hdr
	clc
	adc (trackptr), y
	pha
	iny
	lda pattern_hdr + 1
	adc (trackptr), y
	sta trackptr + 1
	pla
	sta trackptr

	@addw_small_const trackptr, 0x34

	rts
	.)

poll_player:
	.(

	; increment frame counter. Used for various timing thingies.
	inc frame_no
	lda frame_no
	.(
	bne no_hi
	inc frame_no + 1
no_hi:	.)

	; ***** just for testing: return immediately. *****
	;rts

	; if we haven't caught up with the tune yet, wait a bit more.
	@cmpt_geu track_time, real_time, wait_for_frame
	
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
	ldx #2
	bra ignore_x_bytes

ignore_two_bytes:
	ldx #3
	bra ignore_x_bytes

ignore_three_bytes:
	ldx #4
	bra ignore_x_bytes

ignore_four_bytes:
	ldx #5

ignore_x_bytes:
	txa
	clc
	adc trackptr
	sta trackptr
	.(
	bcc no_hi
	inc trackptr + 1
no_hi:	.)
	bra consume_bytes

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
	.(
	bcc no_hi
	inc track_time + 2
no_hi:	.)

	@incw trackptr
	
	; if track_time is greater than or equal to real_time, wait for vsync.
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
	ldx #7
	jmp ignore_x_bytes

write_psg
	ldy #1
	lda (trackptr), y

	ldy from_irq
	bne write_psg_from_irq

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
	lda #$08
	sta $fe40
	
	cli
	
	;lda #'A'
	;jsr oswrch
	
	@addw_small_const trackptr, 2
	jmp consume_bytes

write_psg_from_irq
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
	
	@addw_small_const trackptr, 2
	jmp consume_bytes

wait_for_frame
	; wait 1 video frame, 882 samples
	;lda #19
	;jsr osbyte
	
	;lda #'F'
	;jsr oswrch
	
	lda real_time
	clc
	adc #<882
	sta real_time
	lda real_time + 1
	adc #>882
	sta real_time + 1
	.(
	bcc no_hi
	inc real_time + 2
no_hi:	.)
	
	rts
		
end_of_sound_data:
	inc current_pattern
	lda current_pattern
	cmp #20
	bne use_pattern
	lda #11
	sta current_pattern
use_pattern

	tax
	lda play_order, x
	asl
	tax
	lda pattern_starts, x
	sta pattern_hdr
	lda pattern_starts + 1, x
	sta pattern_hdr + 1

	jsr skip_header

	jmp consume_bytes
	
	rts
	.)

loop_point:
	.word 0

current_pattern:
	.byte 0

musix:
	.asc "tune",13

play_order:
	.byte 0,1,1,2,4,4,5,4,4,4,6,3,7,9,7,8,7,9,7,6

pattern_starts:
        .word 0x8000
        .word 0x82df
        .word 0x856c
        .word 0x87b3
        .word 0xa3c8
        .word 0xa6db
        .word 0xac42
        .word 0xaebd
        .word 0xb2a4
        .word 0xb707

from_irq:
	.byte 0

	.include "../lib/mos.s"
	.include "../lib/load.s"
	.include "../lib/sram.s"

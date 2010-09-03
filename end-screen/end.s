	.org $1200

start
	.(
	lda #4
	jsr mos_setmode
	jsr mos_cursoroff
	
	@load_file_to endscr, $5800
	
	jsr player_select_sram
	jsr player_vsync_event_enable
	
	jsr wait_a_while
	
	jsr player_vsync_event_disable
	jsr player_unselect_sram
	
	ldx #<next_effect
	ldy #>next_effect
	jsr oscli
	
	rts
	.)

next_effect
	.asc "mult", 13

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
	
	lda current_time + 1
	cmp #2
	bcc loop
	
	rts
	.)

endscr
	.asc "endscr", 13

	.include "../lib/mos.s"
	.include "../lib/load.s"
	.include "../lib/player.s"

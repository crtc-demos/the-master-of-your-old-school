	.context test_line
test_line:
	lda #50
	sta %v_line.y_start
	lda #100
	sta %v_line.y_end
	lda #30
	sta %v_line.x_start
	lda #60
	sta %v_line.x_end
	
	jsr v_line

	rts
	.ctxend

	.context test_render
	.var first

test_render:
	lda #0
	sta %first

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
	
	.(
	ldx #0
loop:
	lda xpoints,x
	sta xpoints_old,x
	inx
	cpx #48
	bne loop
	.)
	
	jsr transform_points
	; draw new object
	jsr draw_object

	jsr visibility

	lda %first
	beq is_first

	.(
	ldx #0
loop:
	lda xpoints, x
	sta xpoints_tmp, x
	lda xpoints_old, x
	sta xpoints, x
	inx
	cpx #48
	bne loop
	.)

	; undraw old object
	jsr draw_object

	.(
	ldx #0
loop:
	lda xpoints_tmp, x
	sta xpoints, x
	inx
	cpx #48
	bne loop
	.)

is_first:
	lda #1
	sta %first

	inc rotation_amount
	jmp test_render_loop
	
	rts
	.ctxend

sin_result:
	.word 0

	.context sin_wave
	.var2 tmp2

	; test for sin function. Comically slow!
sin_wave:
	lda #<sin_result
	sta %sin.m_vec_p
	lda #>sin_result
	sta %sin.m_vec_p + 1
	stz %tmp2
	stz %tmp2 + 1
loop:
	lda %tmp2
	ldy #2
	jsr sin
	lda #25
	jsr oswrch
	lda #69
	jsr oswrch
	lda %tmp2
	sec
	sbc #<640
	php
	jsr oswrch
	plp
	lda %tmp2 + 1
	sbc #>640
	jsr oswrch
	ldy #2
	lda (%sin.m_vec_p),y
	jsr oswrch
	ldy #3
	lda (%sin.m_vec_p),y
	jsr oswrch
	
	inc %tmp2
	bne no_hi
	inc %tmp2 + 1
no_hi:
	
	lda %tmp2 + 1
	cmp #5
	bne loop
	rts
	.ctxend

	.context v_line

	.var y_start, y_end
	.var x_start, x_end
	.var2 xpos, xdelta
	.var2 tmp1, tmp2
	
v_line:
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
	
right_way_up:
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
	; now scaled_div.in_a is (x_end - x_start) * 8.
	
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
	
	lda %x_start
	sta %xpos + 1
	stz %xpos
	
	; now xpos, xdelta should be set correctly.
	
	lda %y_start
	and #255-7
	stz %tmp1

	; multiply by 64 to [A:%tmp1]
	lsr
	ror %tmp1
	lsr
	ror %tmp1
	
	; store to tmp2 (ypos & ~7) * 64
	sta %tmp2 + 1
	ldx %tmp1
	stx %tmp2
	
	; tmp1 is (ypos & ~7) * 16
	lsr
	ror %tmp1
	lsr
	ror %tmp1
	sta %tmp1 + 1

	; tmp2 = (ypos & ~7) * 80 + screen start
	lda %tmp1
	clc
	adc %tmp2
	sta %tmp2
	lda %tmp1 + 1
	adc %tmp2 + 1
	clc
	adc #$30
	sta %tmp2 + 1
	
	; row offset to Y
	lda %y_start
	and #7
	tay
	
loop:
	lda %xpos + 1
	stz %tmp1 + 1
	and #0xfe
	asl
	rol %tmp1 + 1
	asl
	rol %tmp1 + 1
	
	clc
	adc %tmp2
	sta %tmp1
	lda %tmp2 + 1
	adc %tmp1 + 1
	sta %tmp1 + 1
	
	lda %xpos + 1
	and #1
	tax
	lda pixmask, x
	eor (%tmp1), y
	sta (%tmp1), y
	
	lda %xpos
	clc
	adc %xdelta
	sta %xpos
	lda %xpos + 1
	adc %xdelta + 1
	sta %xpos + 1
	
	ldx %y_start
	inx
	cpx %y_end
	bcs done
	stx %y_start
	
	iny
	cpy #8
	bne loop
	
	ldy #0
	lda %tmp2
	clc
	adc #<640
	sta %tmp2
	lda %tmp2 + 1
	adc #>640
	sta %tmp2 + 1
	bra loop
done:
	rts
	.ctxend

	.context draw_object
	.var r_tmp1

draw_object:
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
	sta %v_line.x_start
	lda xpoints+2,y
	clc
	adc #128
	sta %v_line.y_start
	
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
	sta %v_line.x_end
	lda xpoints+2,y
	clc
	adc #128
	sta %v_line.y_end
	
	phx
	jsr v_line
	plx
	
	txa
	clc
	adc #4
	tax
	
	cmp #48
	bne loop
	rts
	.ctxend

	.notemps pr_digit, pr_hex, pr_newl

pr_digit:
	.(
	pha
	cmp #10
	bcc less_than_10
	clc
	adc #'a'-10
	bra print
less_than_10:
	clc
	adc #'0'-0
print:
	jsr oswrch
	pla
	rts
	.)

pr_hex:
	.(
	pha
	pha
	lsr
	lsr
	lsr
	lsr
	jsr pr_digit
	pla
	and #15
	jsr pr_digit
	pla
	rts
	.)

pr_newl:
	.(
	pha
	lda #10
	jsr oswrch
	lda #13
	jsr oswrch
	pla
	rts
	.)

	.context render_scanlines_test
	.var2 ypos
	.var scanline, go_across, upto
	.var2 column, colour, rows
	.var2 old_column, old_rows
	.var skip

render_scanlines_test:
	stz %scanline
	lda #<$3000
	sta %ypos
	lda #>$3000
	sta %ypos + 1
	
	.(
	lda %draw_offscreen_object.buffer
	bne buf1
	
	lda #<change_columns_0
	sta %column
	lda #>change_columns_0
	sta %column + 1
	
	lda #<switch_colours_0
	sta %colour
	lda #>switch_colours_0
	sta %colour + 1

	lda #<row_length_0
	sta %rows
	lda #>row_length_0
	sta %rows + 1

	@const_word %old_column, change_columns_1
	@const_word %old_rows, row_length_1

	bra done
buf1:
	lda #<change_columns_1
	sta %column
	lda #>change_columns_1
	sta %column + 1
	
	lda #<switch_colours_1
	sta %colour
	lda #>switch_colours_1
	sta %colour + 1

	lda #<row_length_1
	sta %rows
	lda #>row_length_1
	sta %rows + 1
	
	@const_word %old_column, change_columns_0
	@const_word %old_rows, row_length_0
done:
	.)
	
plot_row:
	lda #0
	sta %hline.colour
	sta %hline.xstart
	lda #159
	sta %hline.xend
	jsr hline

	stz %go_across
	ldy %scanline
	lda (%rows), y
	cmp #2
	bcc empty_row
	dec
	sta %upto

	;lda #3
	;sta %skip

plot_pieces:
	ldy %go_across
	lda (%colour), y
	and #15
	sta %hline.colour
	
	ldy %go_across
	lda (%column), y
	sta %hline.xstart
	iny
	lda (%column), y
	sta %hline.xend
	
	;dec %skip
	;bne miss_hline
	
	jsr hline
miss_hline:
	
	inc %go_across
	lda %go_across
	cmp %upto
	bne plot_pieces

empty_row:
	lda %column
	clc
	adc #columns_per_row
	sta %column
	.(
	bcc no_hi
	inc %column + 1
no_hi:
	.)

	lda %colour
	clc
	adc #columns_per_row
	sta %colour
	.(
	bcc no_hi
	inc %colour + 1
no_hi:
	.)

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

	inc %scanline
	bne plot_row

	rts
	.ctxend


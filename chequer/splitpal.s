	.alias oswrch $ffee
	.alias osbyte $fff4

	.org $e00
        
        .(
	stz active_phase
	
	lda #<phase_0
	sta fliptimes
	lda #>phase_0
	sta fliptimes + 1
	
	lda phase_lens
	sta max_idx
	
        ;lda #4
        ;jsr setmode
        jsr initvsync
stop
	; jmp stop
        rts
        .)

; Set mode, mode number in A.
setmode
	.(
	pha
        lda #22
        jsr oswrch
        pla
        jsr oswrch
        rts
        .)

	.alias SYS_ORB $fe40
	.alias SYS_ORA $fe41
	.alias SYS_DDRB $fe42
	.alias SYS_DDRA $fe43
	.alias SYS_T1C_L $fe44
	.alias SYS_T1C_H $fe45
	.alias SYS_T1L_L $fe46
	.alias SYS_T1L_H $fe47
	.alias SYS_T2C_L $fe48
	.alias SYS_T2C_H $fe49
	.alias SYS_SR $fe4a
	.alias SYS_ACR $fe4b
	.alias SYS_PCR $fe4c
	.alias SYS_IFR $fe4d
	.alias SYS_IER $fe4e

	.alias USR_T1C_L $fe64
	.alias USR_T1C_H $fe65
	.alias USR_T1L_L $fe66
	.alias USR_T1L_H $fe67
	.alias USR_T2C_L $fe68
	.alias USR_T2C_H $fe69
	.alias USR_SR $fe6a
	.alias USR_ACR $fe6b
	.alias USR_PCR $fe6c
	.alias USR_IFR $fe6d
	.alias USR_IER $fe6e

;oldeventv
;	.word 0
oldirq1v
	.word 0

initvsync
	.(
        lda $204
        ldx $205
        sta oldirq1v
        stx oldirq1v+1

	sei

        ; Set one-shot mode for timer 1
        lda USR_ACR
        and #$3f
        sta USR_ACR
        
        ; Sys VIA CA1 interrupt on positive edge
        lda SYS_PCR
        ora #$1
        sta SYS_PCR
                
        ; Point at timer1 handler
        lda #<irq1
        ldx #>irq1
        sta $204
        stx $205

        ; Enable Usr timer 1 interrupt
        lda #$c0
        sta USR_IER
	
	; Disable USR_IER bits
	;lda #0b00111111
	;sta USR_IER
        
        ; Enable Sys CA1 interrupt.
        lda #$82
        sta SYS_IER
        
	; Disable Sys CB1, CB2, timer1 interrupts
	; Note turning off sys timer1 interrupt breaks a lot of stuff!
	lda #0b01011000
	; CB1 & CB2 only
	;lda #0b00011000
	; or everything!
	;lda #0b01111101
	sta SYS_IER
	
        cli
        
        ; Turn off ADC sampling (seems to affect timing too much)
        ;lda #16
        ;ldx #0
        ;jsr osbyte
        
        rts
	.)

	; a PAL line takes 64uS.

fliptime
	.word 64 * [128 + 28] - 10

	.include "phases.s"

	.alias use_pal $70
	.alias index $71
	.alias fliptimes $72
	.alias max_idx $74
	.alias active_phase $75
	.alias last_flip $76

palette_1
	.byte 0b00100001
	.byte 0b00110001
	.byte 0b01100001
	.byte 0b01110001
	.byte 0b10000011
	.byte 0b10010011
	.byte 0b11000011
	.byte 0b11010011

palette_2
	.byte 0b00100011
	.byte 0b00110011
	.byte 0b01100011
	.byte 0b01110011
	.byte 0b10000001
	.byte 0b10010001
	.byte 0b11000001
	.byte 0b11010001

	.alias PALCONTROL $fe21

irq1:	.(
	lda $fc
        pha
	phx
	phy
        ; Is it our User VIA timer1 interrupt?
        lda #64
        bit USR_IFR
        bne timer1
        ; Is it our System VIA CA1 interrupt?
	lda #2
        bit SYS_IFR
        bne vsync
        
	ply
	plx
        pla
	sta $fc
        jmp (oldirq1v)

timer1
	; Clear interrupt
	lda USR_T1C_L

	.(
	lda last_flip
	beq not_last

	; Disable usr timer1 interrupt
	lda #0b01000000
	sta USR_IER
	
	bra do_flip

not_last
	.)

	; Latch next timeout
	ldy index
	lda (fliptimes),y
	sta USR_T1L_L
	iny
	lda (fliptimes),y
	sta USR_T1L_H

	iny
	sty index

	; Disable Sys timer1 interrupt
	;lda #0b01000000
	;sta SYS_IER

do_flip
	lda use_pal
	eor #1
	sta use_pal

	cpy max_idx
	beq last

	bra change

last
	; One-shot mode for timer1
	;lda USR_ACR
	;and #0b00111111
	;sta USR_ACR

	lda #1
	sta last_flip

change
	lda use_pal
	bne use_second_pal

	lda #0b00100110
	sta PALCONTROL
	lda #0b00110110
	sta PALCONTROL
	lda #0b01100110
	sta PALCONTROL
	lda #0b01110110
	sta PALCONTROL
	lda #0b10000100
	sta PALCONTROL
	lda #0b10010100
	sta PALCONTROL
	lda #0b11000100
	sta PALCONTROL
	lda #0b11010100
	sta PALCONTROL

	ply
	plx
	pla
	sta $fc
	rti

use_second_pal
	lda #0b00100100
	sta PALCONTROL
	lda #0b00110100
	sta PALCONTROL
	lda #0b01100100
	sta PALCONTROL
	lda #0b01110100
	sta PALCONTROL
	lda #0b10000110
	sta PALCONTROL
	lda #0b10010110
	sta PALCONTROL
	lda #0b11000110
	sta PALCONTROL
	lda #0b11010110
	sta PALCONTROL

	ply
	plx
	pla
	sta $fc
	rti

vsync
        ; Trigger after 'fliptime' microseconds
        lda fliptime
        sta USR_T1C_L
        lda fliptime+1
        sta USR_T1C_H

	ldx active_phase
	lda phase_lens,x
	sta max_idx
	
	txa
	asl
	tax
	
	lda phase_index, x
	sta fliptimes
	lda phase_index + 1, x
	sta fliptimes + 1

	lda active_phase
	inc a
	and #31
	sta active_phase

	; Set latch to fliptime2.
	lda (fliptimes)
	sta USR_T1L_L
	ldy #1
	lda (fliptimes), y
	sta USR_T1L_H
	
	; Generate stream of interrupts
	lda USR_ACR
	and #0b00111111
	ora #0b01000000
	sta USR_ACR
        
	; Clear IFR
	lda SYS_ORA
	
	; Enable Sys timer1 interrupt
	;lda #0b11000000
	;sta SYS_IER
	
	; Enable usr timer1 interrupt
	lda #0b11000000
	sta USR_IER

	lda #2
	sta index
	
	stz last_flip
	
        lda #0
	sta use_pal

	; physical colour 0: logical 5 (2)
	lda #0b00000010
	sta PALCONTROL
	lda #0b00010010
	sta PALCONTROL
	lda #0b01000010
	sta PALCONTROL
	lda #0b01010010
	sta PALCONTROL

	; physical colour 1: logical 4 (3)
	lda #0b00100011
	sta PALCONTROL
	lda #0b00110011
	sta PALCONTROL
	lda #0b01100011
	sta PALCONTROL
	lda #0b01110011
	sta PALCONTROL
	
	; physical colour 2: logical 6 (1)
	lda #0b10000001
	sta PALCONTROL
	lda #0b10010001
	sta PALCONTROL
	lda #0b11000001
	sta PALCONTROL
	lda #0b11010001
	sta PALCONTROL

	; physical colour 3: logical 7 (0)
	lda #0b10100000
	sta PALCONTROL
	lda #0b10110000
	sta PALCONTROL
	lda #0b11100000
	sta PALCONTROL
	lda #0b11110000
	sta PALCONTROL

	; gtfo
	ply
	plx
	pla
	sta $fc
	rti

	.)

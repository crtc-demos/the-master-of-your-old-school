REM vim: ft=basic

; The score needs to hold some extra info...
; - Mark the end of the song - when to stop playing
; - Change tempo
; - Change envelope(s)

; Suggested format for music data
; 1 command byte (CB), followed by corresponding data bytes.
; If CB < 16, then we will play a note.
;   The first 4 bits of CB mark whether we have a note for the 4 sound channels
;   respectively.
;   For those channels which do have a note, we will read the pitch from the
;   data, and play it.
;   For those channels which do NOT have a note, we will play an empty hold
;   note (to keep the buffers in sync).
;   Therefore CB=0 means no new notes are played, but envelopes already
;   playing will be held.
;   TODO: What about when we don't want to sustain a note, but want to stop
;   sound on a particular channel?  (aka dampen pedal)
;   After playing 1 or more notes, we RTS.
; If CB >= 16, then we will do something different, before looping around to
; read another CB.  (We always expect to sound some notes, after running the
; extra commands, *except* when the end-of-song CB is read.)
; If bit 8 is set, then we will change the default envelope for the channel.
;   Bits 1+2 mark the channel number, bits 3+4+5+6 mark the envelope number.
;   (If we want to set a volume rather than an envelope, we can set bit 7.)
;   Note: although envelopes on the tone channels may change only occasionally,
;   it's likely that the envelope for the noise channel will change often, to
;   simulate different drums.  This will create a lot of CBs.)
; If bit 7 is set but bit 8 is not, then we will change tempo.
;   Bits 1-6 will contain the new tempo.
; We still have values 16 - 63 free.
; One of these numbers should mark end-of-song.

> NEW

MODE 7

#include "asm_common.jpp"

DIM score% 2048

PRINT "Assembling"
PROCassemble

; Test
OSCLI "LOAD M.TRACK "+STR$~score%
CALL init
; TODO: *FX should be in asm
; *FX 14,0

END

DEF PROCassemble
	:
	DIM code 2400
	:
	playPos=&8E   ; TODO: reserve these two bytes in all other progs!
	:
	FOR I%=0 TO 2 STEP 2
	P%=code
	_resetLabelCounters
	[OPT I%

.oldEvent EQUW &0000

; .playPos EQUB &00
;          EQUB &00

.duration EQUB 2

.envelopes EQUW &F1F1 : EQUW &F2F3

.soundParamBlock EQUW &0000 : EQUW &FF00 : EQUW &0000 : EQUW &0000

.init
	; _print("DOING INIT")
	LDA #(score% MOD 256) : STA playPos
	LDA #(score% DIV 256) : STA playPos+1
	LDA #0
	STA soundParamBlock + 5   ; pitchHI
	STA soundParamBlock + 7   ; durationHI
	LDA duration
	STA soundParamBlock + 6   ; duration (only really needs to be set when changed)
	_interceptEvent(OUTPUT_BUFFER_EMPTY_EVENT,&220,oldEvent,event)
	LDA #14 : LDX #0 : JSR &FFF4
	; _print("DONE INIT")
	JMP readCB   ; play the first note, to get things rolling
RTS

.stop
	LDA #13 : LDX #0 : JSR &FFF4
	_removeEvent(OUTPUT_BUFFER_EMPTY_EVENT,&220,oldEvent,event)
RTS

.event

	CPX # SOUND_CHANNEL_0_BUFFER_EMPTIED
	BEQ okEvent
	JMP leaveEvent
	.okEvent

	_print("[NOTE] ")

	.readCB
		LDY #0 : LDA (playPos),Y
		INC playPos : BNE noCarry1 : INC playPos+1 : .noCarry1   ; advance

		CMP #16   ; Carry will be set if A>=16
		BCS notNote
			; Play notes
			LDX #0   ; channel
			.loopChannels
				STX soundParamBlock + 0   ; channel
				ROR A : PHA : BCC emptyNote
					LDA #0 : STA soundParamBlock + 1   ; Noisy note
					LDY #0 : LDA (playPos),Y
					STA soundParamBlock + 4   ; pitch
					INC playPos : BNE noCarry2 : INC playPos+1 : .noCarry2   ; advance
				JMP noteSetupDone
				.emptyNote
					LDA #&10 : STA soundParamBlock + 1   ; Empty note
					LDA #0 : STA soundParamBlock + 4
				.noteSetupDone
				LDA envelopes,X
				STA soundParamBlock + 2   ; volume/envelope
				; TODO: I fear soundParamBlock + 3 needs to be 0 for an envelope, but &ff for a volume
				PHX
				LDX #soundParamBlock MOD 256
				LDY #soundParamBlock DIV 256
				LDA #7 : JSR OSWORD
				PLX : PLA
			INX : CPX #4 : BNE loopChannels
			JMP leaveEvent   ; aka RTS
		.notNote

		CMP #ASC("J") : BNE notJump
			; Perform requested JSR
			LDY #1 : LDA (playPos),Y : STA postJump-2
			LDY #2 : LDA (playPos),Y : STA postJump-1
			LDA playPos : CLC : ADC #2 : STA playPos
			LDA playPos+1 : ADC #0 : STA playPos+1
			JSR &1234 : .postJump
		.notJump

		CMP #ASC("E") : BNE notEnvelope
			; TODO
			; Oh wait isn't "change envelope" supposed to be bit 8 set as per format described at top of file?!
		.notEnvelope

		; TODO: Check for other values of CB
		; ...

	.doneCB
	JMP readCB

.leaveEvent
RTS

	]
	NEXT I%
ENDPROC


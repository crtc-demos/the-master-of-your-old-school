MODE 7

; DONE: If we make distance -> charSet a separate dimension of lookups, then we
; will only need 7 charsets (0-6 bits on), and we can quickly change the radii
; of the boundary circles by updating this lookup.

; CONSIDER: If we drop the mirror effect and have a full-size intensity /
; distance buffer then we could also plot other dirty objects onto the scene.

; No it is good to have a few intensityCharsets but probably 16 is enough.

; Anyway in asm how much time do we really have for lookups?

; TODO: There are still visible jagged movements.
; DONE: Increase the resolution of the distance we lookup from hypots, and
; hence increase the number of bins in intensityLookup. (SCALE_HYPOTS)
; TRIED and sucked: Then again we only have 16 intensity levels.  We could have
; 32 if we were willing to drop to only 8 chars per set.

; You fool.  You are worried about the inward-to-outward effect of the
; intensity updates, when they are quite obviously caused by the BASIC.  They
; should be very small, or could even be calculated in a separate array then
; blitted? nah.

; #define DEBUG(X)
#define DEBUG(X) X

#define KEEP_INTERRUPTS
#define CALC_DIRTY
#define SCALE_HYPOTS 3

#define INTENSITY_CHARSETS 32
#define CHARS_PER_SET 8
randCharMask% = &FF - (INTENSITY_CHARSETS-1)

; Generate lookups
	aspect_squared = (18 / 12) * (18 / 12)
	; surface = 10 : glow = 14
	; surface = 1 : glow = 4
	surface = -2.0 : glow = 5.0

	; hypots - maps large (x,y) space to distance-from-origin (screen-space * SCALE_HYPOTS)
		DIM hypots 18*12
		i%=0
		FOR y%=0 TO 11
			FOR x%=0 TO 17
				#define SQ(N) ((N)*(N))
				hypots?i% = SCALE_HYPOTS * SQR(SQ(x%+0.5)+SQ(y%+0.5)*aspect_squared) + 0.5
				; DONE: More accurate to use centre of pixel +0.5, +0.5, and final rounding +0.5.
				i% = i% + 1
			NEXT
		NEXT
		; Should be sqrt(max_x^2+max_y^2) but we did some other freakies so it changed
		MAX_HYPOT = hypots?(i%-1)+1
		PRINT "MAX_HYPOT = ";MAX_HYPOT

	; intensityLookup - maps a hypot distance to an intensity
		DIM intensityLookup MAX_HYPOT
		PROCcalcIntensityLookup

	; intensityChars - maps an intensity to a set of teletext chars of that intensity
		DIM intensityChars INTENSITY_CHARSETS*CHARS_PER_SET
		FOR intensity%=0 TO INTENSITY_CHARSETS-1
			; Pon = 1.0 - intensity%/14.0
			; Pon = 1.0 - (intensity%-surface)/glow
			Pon = intensity% / (INTENSITY_CHARSETS-1)
			; DONE: To generate a better set of dither chars, calculate the ideal number
			; of bits for this intensity, and create a correct distribution of chars with that
			; many or that many+1
			floor% = (Pon*6) DIV 1
			fraction = Pon*6.0 - floor%
			DEBUG(VDU 144+5)
			FOR char%=0 TO CHARS_PER_SET-1
				#ifdef CALC_DIRTY
					byte%=160
					#define _addBit(B) IF RND(1)<Pon THEN byte% = byte% OR B
					_addBit(1)
					_addBit(2)
					_addBit(4)
					_addBit(8)
					_addBit(16)
					_addBit(64)
				#else
					IF RND(1)<=fraction THEN numBits%=floor%+1 ELSE numBits%=floor%
					byte% = FNaddBits(numBits%,160)
				#endif
				intensityChars?(intensity%+char%*INTENSITY_CHARSETS) = byte%
				DEBUG(VDU byte%)
			NEXT
			DEBUG(PRINT)
		NEXT

; Assemble
	DIM code 2000
	#include "asm_common.jpp"
	FOR I%=0 TO 3 STEP 3
		_resetLabelCounters
		P%=code
		centreTop% = &7C03 + 11 * 40
		centreBottom% = &7C03 + 12 * 40
		oldEvent=&70 ; and &71
		bottomLineLoc=&80 ; and &81
		topLineLoc=&82 ; and &83
		rightX=&84
		leftX=&85
		bottomY=&86
		index=&87
		framecounter=&88 ; and &89,8A,8B
		#ifdef KEEP_INTERRUPTS
			alreadyRunning=&8C
		#endif
		; random=&8D
		intensity=&8E
		[OPT I%

			.init
				_interceptEvent(4,&220,oldEvent,event)
				LDA #14 : LDX #4 : JSR &FFF4
			RTS

			.stop
				LDA #13 : LDX #4 : JSR &FFF4
				_removeEvent(4,&220,oldEvent,event)
			RTS

			.event
				#ifdef KEEP_INTERRUPTS
					LDA alreadyRunning : CMP #0 : BEQ okEvent : JMP leaveEvent
					.okEvent
					LDA #1 : STA alreadyRunning
					CLI
				#endif
				JSR blit
				INC framecounter : BNE skipInc2
					INC framecounter+1 : .skipInc2
				#ifdef KEEP_INTERRUPTS
					SEI
					LDA #0 : STA alreadyRunning
				#endif
				.leaveEvent
			RTS

			.blit
				LDA #0 : STA index
				LDA #centreTop% MOD 256 : STA topLineLoc
				LDA #centreTop% DIV 256 : STA topLineLoc+1
				LDA #centreBottom% MOD 256 : STA bottomLineLoc
				LDA #centreBottom% DIV 256 : STA bottomLineLoc+1
				LDY #0 : STY bottomY
				.loopY
					LDX #17 : STX leftX
					LDX #18 : STX rightX
					.loopX
						; LDA &FE64 : AND #&F0 : STA random
						LDX index : LDA hypots,X
						TAX : LDA intensityLookup,X
						; low 4 bits are intensity (0-15)
						STA intensity

						; EOR here gives us slightly more random results than LDA :)
						; Show distance:
						; #define _getRandomIntensityChar LDX index : LDA hypots,X : AND #63 : CLC : ADC #65
						; Show intensity:
						; #define _getRandomIntensityChar LDA intensity : CLC : ADC #65
						; Real render:
						#define _getRandomIntensityChar EOR &FE64 : AND #randCharMask% : ORA intensity : TAX : LDA intensityChars,X
						LDY rightX
						_getRandomIntensityChar
						STA (bottomLineLoc),Y
						_getRandomIntensityChar
						STA (topLineLoc),Y
						LDY leftX
						_getRandomIntensityChar
						STA (bottomLineLoc),Y
						_getRandomIntensityChar
						STA (topLineLoc),Y

						INC index
						INC rightX
						DEC leftX
						; LDX leftX : CPX #255
					; BNE loopX
					BPL loopX
					; _ifCS( )
					LDA bottomLineLoc : CLC : ADC #40 : STA bottomLineLoc : BCC skipInc1
						INC bottomLineLoc+1 : .skipInc1
					LDA topLineLoc : SEC : SBC #40 : STA topLineLoc : BCS skipInc3
						DEC topLineLoc+1 : .skipInc3
					INC bottomY : LDY bottomY : CPY #12
				BNE loopY
			RTS

		]
	NEXT I%

; Initialise
	MODE 7
	VDU 23,1,0;0;0;0;
	FOR y%=0 TO 24
		?(&7C00+y%*40+0) = 128+1
		?(&7C00+y%*40+1) = 157
		?(&7C00+y%*40+2) = 144+3
	NEXT

	; #define BASIC

	#ifdef BASIC

		REPEAT

			i%=0
			FOR y%=0 TO 11
				FOR x%=0 TO 17
					hypot% = hypots?i%
					intens% = intensityLookup?hypot%
					; getChar% = intensityChars + INTENSITY_CHARSETS*hypot% + RND(CHARS_PER_SET)
					; ?(&7C00+2+x%+y%*40) = ?getChar%
					#define _plot(X,Y,C) ?(&7C00+(X)+(Y)*40) = C
					; char% = ?getChar%
					; #define charToPlot char%
					; #define charToPlot ?getChar%
					#define charToPlot ?( intensityChars + INTENSITY_CHARSETS*RND(CHARS_PER_SET) + intens% )
					_plot(21+x%,13+y%,charToPlot)
					_plot(21+x%,12-y%,charToPlot)
					_plot(20-x%,13+y%,charToPlot)
					_plot(20-x%,12-y%,charToPlot)
					i% = i% + 1
				NEXT
			NEXT

		UNTIL FALSE

	#else

		startTime=TIME - 1   ; avoid /0 !
		!(framecounter)=0
		CALL init
		; *FX 14,4
		fg$=CHR$(128)
		bg$=CHR$(128+1)+CHR$(157)+CHR$(144+3)
		REPEAT
			PRINTTAB(0,24)"surface=";surface;"  ";
			PRINTTAB(18,24)" TIME=";(TIME/100);" ";
			PRINTTAB(28,24)" fps=";((!framecounter)*100 DIV (TIME-startTime));" ";
			; PRINTTAB(17,24) " frame=";(!framecounter);" ";
			IF surface<25 THEN surface=surface+0.457 : glow=glow+0.157 : PROCcalcIntensityLookup
		UNTIL FALSE

	#endif

	END

; PROCs and FNs
	DEF FNaddBits(numBits%,byte%)
		IF numBits% = 0 THEN =byte%
		REPEAT
			bit% = 2^RND(8)
		UNTIL byte% AND bit% = 0
	=FNaddBits(numBits%-1,byte% OR bit%)

	DEF FNchop(low,hi,val)
		IF val<low THEN =low
		IF val>hi THEN =hi
	=val

	DEF PROCcalcIntensityLookup
		FOR dist%=0 TO MAX_HYPOT - 1
			Pon = 1.0 - (dist%/SCALE_HYPOTS-surface)/glow
			; A better fade-off might relate to dist_from_surface^2 rather than linear.
			; Non-linear glow:
			IF Pon > 0 AND Pon < 1 THEN Pon = SQ(Pon)
			intensityLookup?dist% = FNchop(0,INTENSITY_CHARSETS-1,(INTENSITY_CHARSETS-1) * Pon+0.5)
			; +0.5 final rounding to int
		NEXT
	ENDPROC


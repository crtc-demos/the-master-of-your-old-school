; @required plotTelexel.dims
; @expected Zero-page bytes: x,y,charx,chary,bitx,bity,plotBit
; @expected Zero-page words: plotLoc
; @optional PLOT_TELEXEL_SAVE_OLD (requires oldIndexLO/HI), PLOT_TELEXEL_SKIPIFSET, PLOT_TELEXEL_XOR
; @optional OLDDATA_SUPERFAST (requires not PLOT_TELEXEL_SAVE_OLD)

; Does not contain an RTS, so can be included inline (with risk of variable
; overlap!) or can be turned into a function by adding RTS.

; TESTING:
; For faster plotting, consider using lookups:
;   y -> liney (or better locyLO,HI)
;   x -> charx
;   y -> 2bits of the teletext char (+160)
;   x -> 3bits of the teletext char (+160), to be anded with the previous to make the plotchar
; Oh we are already using lookups mod3,div3, but they are a bit abstract :P

#ifndef PLOT_TELEXEL_SAVE_OLD
	#define FAST_Y_OFFSET
#endif

; Untrue: TELEXEL_LOOKUP_MASKS and TELEXEL_LOOKUP_YLOCS should be used together or neither.
; True: TELEXEL_LOOKUP_MASKS negates the need for mod3/div3 lookups

.plotTelexel                ; plot point at x,y
	;; Split x,y into charx,chary and bitx,bity
		; We need not STA plotBit early, we could load it later and AND it.
		; But there might be complications losing Y in certain situations.
		#ifdef TELEXEL_LOOKUP_MASKS
			; Lookup plotBit really fast by ANDing X,Y lookups
			LDX x : LDA telexMaskX,X
			LDY y : AND telexMaskY,Y
			STA plotBit
		#else
			TAY : LDA mod3Lookup,Y : STA bity
			LDA y : LDA div3Lookup,Y   ; Actually chary is never used, we use plotLoc instead (STA chary)
			STA plotLoc   ; needed later, maybe
			LDA x : CLC : ROR A : STA charx
			LDA #0 : ROL A : STA bitx
		; Which bit must we plot?  Lookup plotBit from bitx,bity.
			LDA bity : CLC : ROL A : ADC bitx
			TAX : LDA bits,X : STA plotBit
		#endif
	;; Calculate plotLoc from charx,chary
		#ifdef TELEXEL_LOOKUP_YLOCS
			LDY y
			#ifdef FAST_Y_OFFSET
				; We can output Y here as the offset to use from plotLoc
				; which might be a bit faster, but would break SAVE_OLD.
				LDA lookupYlocsLO,Y : STA plotLoc
				LDA lookupYlocsHI,Y : STA plotLoc+1
				LDA x : CLC : ROR A : TAY
				; LDY charx
			#else
				LDA x : CLC : ROR A
				CLC : ADC lookupYlocsLO,Y : STA plotLoc
				LDA lookupYlocsHI,Y : ADC #0 : STA plotLoc+1
				LDY #0
			#endif
		#else
			; This does not work with TELEXEL_LOOKUP_MASKS because only the other method sets plotLoc.
			_multiply8to16(plotLoc,#40,plotLoc+1,plotLoc)
			_add16(#SCRTOP DIV 256,charx,plotLoc+1,plotLoc,plotLoc+1,plotLoc)
			; Also note it requires SCRTOP MOD 256 == 0
			LDY #0
		#endif
	#ifdef PLOT_TELEXEL_SKIPIFSET
		; If the bit is already set, do nothing.  Needed if we want to plot with an
		; OR but use XOR for unplot.
		 LDA (plotLoc),Y : AND plotBit : BNE plotTelexelSkipPlot
	#endif
; .plotIt
	#ifdef PLOT_TELEXEL_XOR
		 LDA (plotLoc),Y : EOR plotBit : STA (plotLoc),Y
	#else
		 LDA (plotLoc),Y : ORA plotBit : STA (plotLoc),Y
	#endif

#ifdef PLOT_TELEXEL_SAVE_OLD

	; This technique was originally for the Sierpinski.
	; It stored previously set pixels (actually location+bit).  After trailLen%
	; plotted pixels, it starts to clear the 1 oldest pixel per new plotted one.

	; Other techniques might be preferable, e.g.:
	;   - Clear all pixels from last frame, before we start to plot new frame.

	; TODO: This could be faster if it used 3 tables rather than 1 table with records of size 3 bytes.
	; It could also be faster if we imposed the limit that there will be max 256 records.

	; I think PLOT_TELEXEL_ALWAYS_CLEANUP is thoroughly buggy (when used
	; alongside PLOT_TELEXEL_SKIPIFSET, which is entirely what it was intended
	; for!)
	; E.g. If we plot 100 one frame, then 150 the next, we will clear 50 what?!
	; Or if we plot 200 one frame, then 120 the next, we want to clear 200, but
	; it's not currently doing that!
	; So ... we should save it even if we don't plot it.  Done.
	; But if we didn't plot it and we save it, then we can't use XOR to unplot!
	; We must do the slow unplot.
	; But what we have achieved is full clearing of the previous frame, when
	; the number of points each frame differs.
	; Although there is a danger we may clear some of the new points added this frame.
	#ifdef PLOT_TELEXEL_ALWAYS_CLEANUP
	.plotTelexelSkipPlot
	#endif

	#ifdef OLDDATA_SUPERFAST

		.savePosition
			LDX oldIndex
			LDA plotBit : STA oldPlotBits,X
			LDA plotLoc : STA oldPlotLocLO,X
			LDA plotLoc+1 : STA oldPlotLocHI,X
			INX : STX oldIndex

	#else

		.savePosition
			LDY #0 : LDA plotBit : STA (oldIndexLO),Y
			INY : LDA plotLoc : STA (oldIndexLO),Y
			INY : LDA plotLoc+1 : STA (oldIndexLO),Y
			; INC oldIndexLO : BNE skipSave1 : INC oldIndexHI : .skipSave1
			; INC oldIndexLO : BNE skipSave2 : INC oldIndexHI : .skipSave2
			; INC oldIndexLO : BNE skipSave3 : INC oldIndexHI : .skipSave3
			CLC : LDA oldIndexLO : ADC #3 : STA oldIndexLO : LDA oldIndexHI : ADC #0 : STA oldIndexHI

		; If we are not using incremental method then we DON'T want to wraparound (at least, we are happy to go 1 record beyond IFF oldData size is exactly the size needed).
		#ifdef UNPLOT_TELEXEL_INCREMENTALLY
			LDA oldIndexLO : CMP #oldDataEnd MOD 256 : BNE oldNoOverflow
			LDA oldIndexHI : CMP #oldDataEnd DIV 256 : BNE oldNoOverflow
			LDA #oldData MOD 256 : STA oldIndexLO
			LDA #oldData DIV 256 : STA oldIndexHI
			.oldNoOverflow
		#endif

	#endif

	#ifdef UNPLOT_TELEXEL_INCREMENTALLY

		#ifdef OLDDATA_SUPERFAST

			.clearOld
				; LDY #0
				; LDX oldIndex
				#ifndef TRAILLEN_IS_256
					CPX #trailLen% MOD 256 : BNE sfxSkip : LDX #0 : STX oldIndex : .sfxSkip
				#endif
				LDA oldPlotLocLO,X : STA plotLoc
				LDA oldPlotLocHI,X : STA plotLoc+1
			.unplotOld
				; LDY #0
				#ifdef UNPLOT_TELEXEL_XOR
					LDA (plotLoc),Y : EOR oldPlotBits,X : STA (plotLoc),Y
				#else
					LDA oldPlotBits,X : EOR #255 : AND (plotLoc),Y : ORA #160 : STA (plotLoc),Y
				#endif

		#else

			.clearOld
				LDY #0 : LDA (oldIndexLO),Y : STA plotBit
				INY : LDA (oldIndexLO),Y : STA plotLoc
				INY : LDA (oldIndexLO),Y : STA plotLoc+1
			.unplotOld
				#ifdef UNPLOT_TELEXEL_XOR
					LDY #0 : LDA (plotLoc),Y : EOR plotBit : STA (plotLoc),Y
				#else
					LDY #0 : LDA plotBit : EOR #255 : AND (plotLoc),Y : ORA #160 : STA (plotLoc),Y
				#endif

		#endif

	#endif

	#ifndef PLOT_TELEXEL_ALWAYS_CLEANUP
	.plotTelexelSkipPlot
	#endif

#else

	.plotTelexelSkipPlot

#endif


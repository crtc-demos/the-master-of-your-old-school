REM vim: ft=basic

; > *BASIC

; > HIMEM=&4800
>PAGE=&3800
>NEW
; >LOMEM=&5000
; >PRINT ~HIMEM

; Todo consider: We need resolution 80 right.  So let's double it to 160, and
; aim to use the *middle* 160 of the range, to avoid the poor res at the ends.

; We could double the resolution of the LogOfSin if needed, since it is a
; doubled curve.  In fact we can quarter it, since the curve reflects itself.
; These would increase resolution or reduce the size of the lookup, but would
; require additional processing.

; CONSIDER TODO: We could simplify things by forcing waveYamp == waveXamp
; without I think sacrificing much of the image.

; TODO: Vary amplitudes without exceeding bounds.

; Bah our amplitudes were pretty similar anyway, and also we aren't changing them,
; so really using logarithms is kinda wasted! :P

#define TELETEXT_MODE
#define BASIC_USE_LOGS
; #define GENERATE_NEW_LOOKUP_FILE
#define ASSEMBLY
; #define TRAILLEN_IS_256
; #define DASHED
; #define FADE
#define FIX_NEGATIVE_BUG

#define DRAW_LINE_WITH_BRESENHAM
; or
; #define PLOT_DOTS
; #define INTERPOLATE_DOTS_ONCE

#define DOUBLE_BUFFER
scrbuffer% = &7C00 - 1024
#define SCRTOP scrbuffer%
; #define SCRTOP &7800

; > VDU 21

#ifdef TELETEXT_MODE
	MODE 7
	#define PLOT_XOR
	#include "teletext_bits.dim"
	; This is needed because the top of the scale has poor resolution!
	; We get better relative accuracy from the log trick nearer the middle of the curve.
	#define scaleDown 0.58
	; #define scaleDown 0.5
#else
	MODE 4
	#define scaleDown 0.8
#endif
VDU 23,1,0;0;0;0;

#ifdef BASIC_USE_LOGS

	#include "lookupLogs2.dims"

#endif


; numWaves% = 2
numWaves% = 3
; #define MOVEMENT_SPEED 63
; #define MOVEMENT_SPEED 31
; #define MOVEMENT_SPEED 91
; #define MOVEMENT_SPEED 47
#define MOVEMENT_SPEED 15

#ifdef TRAILLEN_IS_256
	angleStep% = 1
	trailLen% = 256
#else
	#ifdef DASHED
		dashLength% = 2   ; must be a power of 2
		; angleStep% = 1
		; #define ANGLESTEP_IS_1
		angleStep% = 1
		trailLen% = 128/angleStep%
	#else
		angleStep% = 3
		trailLen% = 256/angleStep%
	#endif
#endif
#ifdef INTERPOLATE_DOTS_ONCE
	trailLen% = trailLen% * 2
	;; This isn't efficient - it drops us from 14 to 12 fps!
	; #define TRAILLEN_IS_256
#endif
#ifdef FADE
	#define fadeLength dashLength%
	trailLen% = trailLen% / 2
#endif
#ifdef DRAW_LINE_WITH_BRESENHAM
	trailLen%=320
	angleStep%=5   ; with 4 the framerate dropped, with 5 occasionally lines are visible
#endif

; #ifdef BASIC_USE_LOGS
; DIM logwaveXamp% numWaves%
; DIM logwaveYamp% numWaves%
; #else
; DIM waveXamp(numWaves%),waveYamp(numWaves%)
; #endif
; DIM waveXphase% numWaves%
; DIM waveYphase% numWaves%
; DIM wavefreq% numWaves%
; DIM wavefreqMultCache% numWaves%
; DIM rotateCounterX numWaves%
; DIM rotateCounterY numWaves%
; DIM rotateCounterMaxX numWaves%
; DIM rotateCounterMaxY numWaves%



CLS
; Load or generate log lookups
	; (We can't do this in a PROC due to the ON ERRORs)

	PROCprepareScreen(4)

	PRINT "Loading lookups";CHR$(128+3);"(press ESC if frozen)";
	fail%=0
	ON ERROR REPORT:PRINT " #";ERR;" at line ";ERL:fail%=1
		IF fail%=0 THEN OSCLI "LOAD L.LOGS "+STR$~(lookupLog)

	IF fail% THEN PRINT "Load failed.  Generating lookups ..."
	IF fail% THEN PROCcalcLogs

	IF fail% THEN PRINT "Saving lookups";CHR$(128+3);"(press ESC if frozen)";
	fail%=fail% EOR 1   ; We only save if we failed to load
	ON ERROR REPORT:PRINT " #";ERR;" at line ";ERL:fail%=1
		IF fail%=0 THEN OSCLI "SAVE L.LOGS "+STR$~(lookupLog)+" +400"

	PRINT
	ON ERROR REPORT:PRINT " at line ";ERL:END

#ifdef ASSEMBLY

	#include "asm_common.jpp"

	PRINT "Assembling"
	PROCassemble

	PROCinitWaves

  OSCLI "SAVE O.PHASE "+STR$~code+" "+STR$~P%+" "+STR$~init

  OSCLI "SPOOL I.PHASE"
  PRINT "start=&";~code;" end=&";~P%;" init=&";~init;" and stop=&";~stop
  OSCLI "CLOSE"

	CLS
	; FOR line%=0 TO 23 : PRINTTAB(0,i%);CHR$(148);STRING$(39,CHR$(160)); : NEXT line%

	; PRINTTAB(2) "log[0]=";(lookupLog?0);"  "
	; PRINTTAB(2) "log[1]=";(lookupLog?1);"  "
	; PRINTTAB(2) "log[2]=";(lookupLog?2);"  "
	; PRINTTAB(2) "log[3]=";(lookupLog?3);"  "
	; PRINTTAB(2) "log[127]=";(lookupLog?127);"  "
	; PRINT "log[255]=";(lookupLog?255);"  "

	; PROCprepareScreen(2)

	startTime=TIME - 1   ; avoid /0 !
	; !(framecounter)=0
	CALL init
	; *FX 14,4
	; CALL start
	REPEAT
		; FOR f%=1 TO 10
			; CALL event
			; *FX 19
		; NEXT f%
		PRINTTAB(0,0);
		; PRINT "x=";(?x);"  ";"y=";(?y);"  "
		; PRINT "tx=";(?tx);"  ";"ty=";(?ty);"  "
		; PRINT "angle=";?angle;"  "
		; PRINT "oldIndexLO=";(?oldIndexLO);"  "
		; PRINT "angle=";(?angle);"  "
		; breaks: PRINTTAB(2) "3*54 = 162, loo=";lookupUnlog2(lookupLog(3) + lookupLog(54));"  "
		; PRINT "(";?lastx;",";?lasty;") - (";?dotx;",";?doty;")  "
		; PRINT "xdir=";~?xdir;"  ydir=";~?ydir;"  "
		; PRINT "x_dist=";~?x_dist;"  y_dist=";~?y_dist;"  "
		PRINT "freqs:   ";FNgetSignedByte(wavefreq%?0);"   ";FNgetSignedByte(wavefreq%?1);"   ";FNgetSignedByte(wavefreq%?2);"     "
		; PRINT "Xamps(logged): ";logwaveXamp%?0;" ";logwaveXamp%?1;" ";logwaveXamp%?2;"  "
		; PRINT "Yamps(logged): ";logwaveYamp%?0;" ";logwaveYamp%?1;" ";logwaveYamp%?2;"  "
		PRINT "speedX: ";rotateCounterMaxX?0;"  ";rotateCounterMaxX?1;"  ";rotateCounterMaxX?2;"  "
		PRINT "speedY: ";rotateCounterMaxY?0;"  ";rotateCounterMaxY?1;"  ";rotateCounterMaxY?2;"  "
		PRINT "phaseX: ";waveXphase%?0;"  ";waveXphase%?1;"  ";waveXphase%?2;"  "
		PRINT "phaseY: ";waveYphase%?0;"  ";waveYphase%?1;"  ";waveYphase%?2;"  "
		; PRINT "frame=";(!framecounter);"  "
		; PRINT "secs=";((TIME-startTime) DIV 100);"  "
		; PRINT "fe67=";(?&FE67);"  " ; does not change from 255!
		fps = ((!framecounter)*100 / (TIME-startTime))
		PRINT "FPS=";fps DIV 1;"  "
		sinAddsPerSec = numWaves%*trailLen%*fps
		; PRINT "sps=";sinAddsPerSec DIV 1;"  "
		; dummy = RND(-TIME)
		; FOR i%=0 TO numWaves%-1
			; logwaveXamp%?i% = (lookupLog?( ( 125 + RND(130) ) / numWaves% * scaleDown ))
			; ; logwaveYamp%?i% = (lookupLog?( ( 125 + RND(130) ) / numWaves% * scaleDown ))
			; logwaveYamp%?i% = logwaveXamp%?i%
		; NEXT i%
	UNTIL FALSE
	END

#else

	CLS : PROCprepareScreen(2)

	REPEAT

		FOR frame%=0 TO 1000

			IF frame% MOD 2 < 2 THEN PROCinitWaves

			globalphase%=(frame%) * 2*PI/50
			GCOL 0,0
			PROCplotWiggle
			GCOL 0,0
			PROCplotWiggle

		NEXT

	UNTIL FALSE

	END

#endif



#ifdef TELETEXT_MODE
#include "plot_telexel.fns"
#endif



DEF PROCprepareScreen(col%)
	FOR i%=0 TO 24*40 : ?(&7C00+i%)=160 : NEXT
	FOR i%=0 TO 24 : ?(&7C00+i%*40)=144+col% : NEXT
ENDPROC

DEF PROCcalcLogs

	#include "lookupLogs2.calc"

ENDPROC

DEF PROCinitWaves
	; dummy = RND(-TIME)
	FOR i%=0 TO numWaves%-1
		logwaveXamp%?i% = (lookupLog?( ( 185 + RND(70) ) / numWaves% * scaleDown ))
		logwaveYamp%?i% = (lookupLog?( ( 185 + RND(70) ) / numWaves% * scaleDown ))
		waveXphase%?i% = RND(255)
		waveYphase%?i% = RND(255)
		wavefreq%?i% = 2 + i%
	NEXT i%
ENDPROC

DEF FNchop(low,hi,val)
	IF val<low THEN =low
	IF val>hi THEN =hi
=val



#ifndef ASSEMBLY

	DEF PROCplotWiggle
		FOR angle% = 0 TO 255 STEP 4
			x% = 0 : y% = 0
			FOR wave%=0 TO numWaves%-1
				#ifdef BASIC_USE_LOGS
					; PRINTTAB(0,0);
					x% = x% + FNlogadd(logwaveXamp%?wave%,wavefreq%?wave%*angle% + waveXphase%?wave% + globalphase%)
					y% = y% + FNlogadd(logwaveYamp%?wave%,wavefreq%?wave%*angle% + waveYphase%?wave% + globalphase%)
				;; TODO/DONE?
				;; wavefreq%(wave%)*angle% could be faster if done with logs, or could be pre-cached for all angles!
				;; waveXphase% + globalphase% could be precached, why not drop globalphase and edit waveXphase each frame?
				#else
					x% = x% + waveXamp(wave%) * SIN(wavefreq(wave%)*angle + waveXphase(wave%) + globalphase)
					y% = y% + waveYamp(wave%) * SIN(wavefreq(wave%)*angle + waveYphase(wave%) + globalphase)
				#endif
			NEXT wave%
			#ifdef TELETEXT_MODE
				x% = 40 + x%/7/scaleDown
				y% = 38 + y%/7/scaleDown
				PROCplotTelexel(x%,y%)
			#else
				x% = 640 + 2*x%/scaleDown
				y% = 512 + 2*y%/scaleDown
				IF angle% = 0 THEN plotMode%=4 ELSE plotMode%=5
				PLOT plotMode%,x%,y%
				; PLOT 69,x%,y%
			#endif
		NEXT angle%
	ENDPROC

	#ifdef BASIC_USE_LOGS

		; amp should be 0-255
		; ang should be 0-2PI or more
		DEF FNlogadd(logamp%,ang%)
			#ifdef OLD
			#define logamp% lookupLog?(amp)
			#endif
			choppedAng% = ang% MOD 256
			; PRINT "logamp=";logamp%;"  ang=";ang%;"  "
			; PRINT "sinI=";(choppedAng% DIV 64);"  llI=";amp;"  llsI=";choppedAng%;"  "
			; PRINT "llu2I=";( ( lookupLog?(amp) + lookupLogOfSin?(choppedAng%) )/2 );"  "
			; PRINT "result=";(FNgetSinCharge%(choppedAng% DIV 64) * lookupUnlog2?( ( lookupLog?(amp) + lookupLogOfSin?choppedAng% )/2 ));"  "
		= FNgetSinCharge(choppedAng%) * lookupUnlog2?( FNchop(0,255,logamp% + lookupLogOfSin?choppedAng% - 256) )

		DEF FNgetSinCharge(quad%) IF sinCharge?quad% = 255 THEN =-1 ELSE =+1

	#endif

#endif



#ifdef ASSEMBLY

DEF PROCassemble
	:
	; DIM code 2400
	code=&1B00
	; code=HIMEM
	:
	rotationSlowdown% = 1   ; 0 means 256
	:
	#ifndef DOUBLE_BUFFER
		#define PLOT_TELEXEL_SAVE_OLD
		#define UNPLOT_TELEXEL_INCREMENTALLY
		#define UNPLOT_TELEXEL_XOR
		;; If we do unplot with XOR, then we must do at least 1 of these two:
		#define PLOT_TELEXEL_XOR
		; #define PLOT_TELEXEL_SKIPIFSET
		; #define PLOT_TELEXEL_ALWAYS_CLEANUP
		#ifndef DRAW_LINE_WITH_BRESENHAM
			#define OLDDATA_SUPERFAST
		#endif
	#endif
	;; Re-enable interrupts (in case we take longer than a frame) - needed for accurate FPS reading:
	; #define KEEP_INTERRUPTS
	;; LOOP_IN_FOREGROUND will continue to run the renderer, rather than wait for
	;; the next frame event.  Will very occasionally drop out so that BASIC may
	;; make updates.  This can increase the framerate somewhat, but leaves very
	;; little time for other processing.  And possibly code could still be
	;; running during the next vsync, which might show uglies with some methods.
	; #define LOOP_IN_FOREGROUND
	:
	; #include "plotTelexel.dims.OLD"
	#ifdef DRAW_LINE_WITH_BRESENHAM
	firstTimeRound=&80
	#endif
	oldIndexLO=&81
	oldIndexHI=&82
	dotx=&83 : doty=&84
	charx=&85 : chary=&86
	bitx=&87 : bity=&88
	plotLoc=&89 : REM and &8A
	plotBit=&8B
	lastx=&8C : lasty=&8D
	#ifdef PLOT_DOTS
		#define x dotx
		#define y doty
	#else
		; DRAW_LINE_WITH_BRESENHAM
		x=&70 : y=&71
	#endif
	:
	; numWaves=&80
	; ?numWaves = numWaves%
	; tx=&8C : ty=&8D   ; I was just using these for testing
	#define tx dotx
	#define ty doty
	:
	oldEvent=&72 : REM and &73
	x_dist=&74
	y_dist=&75
	srcLoc=&74 : REM and &75
	fraction=&76
	delta=&77
	angle=&78
	framecounter=&79 : REM and &7A &7B &7C
	tmpA=&7D
	#ifdef KEEP_INTERRUPTS
		alreadyRunning=&7E
	#endif
	currentColor=&7F
	:
	FOR I%=0 TO 2 STEP 2
	P%=code
	_resetLabelCounters
	[OPT I%

.init
	LDA #22 : JSR OSASCI
	LDA #7 : JSR OSASCI
	; hide cursor
		LDA #23 : JSR OSASCI
		LDA #1 : JSR OSASCI
		LDA #0 : JSR OSASCI
						 JSR OSASCI
						 JSR OSASCI
						 JSR OSASCI
						 JSR OSASCI
						 JSR OSASCI
						 JSR OSASCI
						 JSR OSASCI
	; _print("Phase started")
	; LDX #0 : STX rotation
	; LDA #1 : STA rotateCounterA : STA rotateCounterB : STA rotateCounterC
	LDA #0
	STA framecounter : STA framecounter+1
	STA framecounter+2 : STA framecounter+3
	#ifndef DOUBLE_BUFFER
		LDA #oldData MOD 256 : STA oldIndexLO
		LDA #oldData DIV 256 : STA oldIndexHI
	#endif
	LDA #144+1 : STA currentColor
	JSR setupColors
	#ifdef KEEP_INTERRUPTS
		LDA #0 : STA alreadyRunning
	#endif
	_interceptEvent(4,&220,oldEvent,event)
	LDA #14 : LDX #4 : JSR &FFF4
RTS

.stop
  LDA #13 : LDX #4 : JSR &FFF4
  _removeEvent(4,&220,oldEvent,event)
RTS

]

logwaveXamp%=P% : P%=P%+numWaves%
logwaveYamp%=P% : P%=P%+numWaves%
waveXphase%=P% : P%=P%+numWaves%
waveYphase%=P% : P%=P%+numWaves%
wavefreq%=P% : P%=P%+numWaves%
wavefreqMultCache%=P% : P%=P%+numWaves%
rotateCounterX=P% : P%=P%+numWaves%
rotateCounterY=P% : P%=P%+numWaves%
rotateCounterMaxX=P% : P%=P%+numWaves%
rotateCounterMaxY=P% : P%=P%+numWaves%

#include "plotTelexel.dims"

[OPT I%

; DONE: put these back in ZP for speed
; .lastx EQUB &00
; .lasty EQUB &00
; #ifdef DRAW_LINE_WITH_BRESENHAM
; .firstTimeRound EQUB 123
; #endif

.event

  JSR &0E06

	#ifdef KEEP_INTERRUPTS
		LDA alreadyRunning : CMP #0 : BEQ okEvent : JMP leaveEvent
		.okEvent
		LDA #1 : STA alreadyRunning
		CLI
	#endif

.start

	; _print("*e")

	#ifdef DOUBLE_BUFFER
		; Blit the offscreen buffer to the screen
		LDA #scrbuffer% MOD 256 : STA srcLoc
		LDA #scrbuffer% DIV 256 : STA srcLoc+1
		LDA #&00 : STA plotLoc
		LDA #&7C : STA plotLoc+1
		LDX #3
		.blitloop1
			LDY #0
			.blitloop2
				LDA (srcLoc),Y
				STA (plotLoc),Y
			INY : BNE blitloop2
			INC srcLoc+1
			INC plotLoc+1
		DEX : BPL blitloop1
	#endif

	#ifndef UNPLOT_TELEXEL_INCREMENTALLY
	#ifndef DOUBLE_BUFFER
		; Clear the last frame
		#include "plotTelexelUnplotAll.asm"
	#endif
	#endif

	#ifdef DOUBLE_BUFFER
		; Clear the offscreen buffer
		LDA #scrbuffer% MOD 256 : STA plotLoc
		LDA #scrbuffer% DIV 256 : STA plotLoc+1
		LDA #160
		LDX #3
		.clsloop1
			LDY #0
			.clsloop2
				STA (plotLoc),Y
			INY : BNE clsloop2
			INC plotLoc+1
		DEX : BPL clsloop1
		JSR setupColors
	#endif

	; LDA rotateCounterA : AND #7 : BNE plotLoop
	; INC angle
	; INC offset
	; LDA #0 : STA angle

; > VDU 6

	#ifdef DRAW_LINE_WITH_BRESENHAM
		LDA #1 : STA firstTimeRound
	#endif

	LDA #0
	LDY #numWaves% : DEY
	.clearCacheLoop
		STA wavefreqMultCache%,Y
	DEY : BPL clearCacheLoop

	.plotLoop

		#ifdef DASHED
			LDA angle : AND #dashLength%*2-1 : CMP #0 : BNE skipAngleStep
				LDA angle : CLC : ADC #dashLength% : STA angle
				; Update the wave caches
				LDY #numWaves% : DEY
				.updateCacheLoop
					LDA wavefreqMultCache%,Y
						;; Update the cached wavefreqs dashLength-angleStep% times (because
						;; we will always do angleStep% later)
						;; OK I dropped the -angleStep% part, I think we do need to do that :P
						;; Basically the angleStep% part is left over to be done from that last iteration.
						; ]
						; FOR i%=1 TO dashLength%
							; [OPT I% : CLC : ADC wavefreq%,Y : ]
						; NEXT i%
						; [OPT I%
						LDX #dashLength% : .dashLoop
							CLC : ADC wavefreq%,Y
						DEX : BNE dashLoop
					STA wavefreqMultCache%,Y
				DEY : BPL updateCacheLoop
			.skipAngleStep
		#endif

		LDY #numWaves% : DEY
		.updateCacheLoop
			; These numbers could be further cached inside a lookup table of size 256 per wave(freq).
			LDA wavefreqMultCache%,Y
			LDX #angleStep% : .updateCacheLoopInner
				CLC : ADC wavefreq%,Y
			DEX : BNE updateCacheLoopInner
			STA wavefreqMultCache%,Y
		DEY : BPL updateCacheLoop

		; TODO? only copy down every N frames
		; N ~ tension

		#ifdef FADE
			LDA &FE64 : AND #fadeLength-1 : STA tmpA
			LDA angle : AND #fadeLength-1 : CMP tmpA : BCS okPlot
				JMP skipPlot
			.okPlot
		#endif

		LDA #0 : STA tx : STA ty
		LDY #numWaves% : DEY
		.loopWaves
			.getdeltax
				; work out the angle for this wave, angle + frame, (no need to chop it :D)
					;; DONE: These results (wavefreq*angle) could be pre-calculated before we enter loopWaves.
					;; TODO: By separating our two caches for X and Y, we could also precalc the ADC waveXphase%,Y
					; LDA #0 : LDX wavefreq%,Y
					; .loopX : CLC : ADC angle : DEX : BNE loopX
					LDA wavefreqMultCache%,Y
					; ADC offset
					; done mult :f
					CLC : ADC waveXphase%,Y
					; CLC : ADC rotation
				; ok so we have the angle
				; we should do an early check whether we will need to invert
					STA tmpA   ; PHA
					; divide by 64 to find the quadrant
					; Done: consider two ANDs instead of 6 RORs.  Or 1 AND and 3 ROLs.
					; LSR A : LSR A : LSR A : LSR A : LSR A : LSR A
					; FORGET: maybe better: just ROL and branch with carry twice to get the quadrant?
					; AND #128+64 : CLC : ROL A : ROL A : ROL A   ; Better!
					; DONE: sinCharge lookup :)
					TAX : LDA sinCharge,X : STA postInvertA-1
					#ifdef FIX_NEGATIVE_BUG
						AND #1 : STA postInvertAsub-1
					#endif
					LDA tmpA   ; PLA
				; lookup the LogOfSin
				TAX : LDA lookupLogOfSin,X
				; Add the logamp for this wave
				CLC : ADC logwaveXamp%,Y
				; lookup the un-logged result
					; ROR A : TAX : LDA lookupUnlog2,X
					BCC nodeltax
					TAX : LDA lookupUnlog2,X
				; this is what we should add to x, except we should
				; invert it if sinCharge says so!
				#ifdef FIX_NEGATIVE_BUG
					SEC : SBC #123 : .postInvertAsub
				#endif
				EOR #255 : .postInvertA
			.gotdeltax
				CLC : ADC tx : STA tx
			.nodeltax
			.getdeltay
				; work out the angle for this wave, angle + frame, (no need to chop it :D)
					; LDA #0 : LDX wavefreq%,Y
					; .loopY : CLC : ADC angle : DEX : BNE loopY
					LDA wavefreqMultCache%,Y
					; ADC offset
					; done mult :f
					CLC : ADC waveYphase%,Y
					; : CLC : ADC rotation
				; ok so we have the angle
				; we should do an early check whether we will need to invert
					STA tmpA   ; PHA
					; divide by 64 to find the quadrant
					; LSR A : LSR A : LSR A : LSR A : LSR A : LSR A
					; AND #128+64 : CLC : ROL A : ROL A : ROL A   ; Better!
					TAX : LDA sinCharge,X : STA postInvertB-1
					#ifdef FIX_NEGATIVE_BUG
						AND #1 : STA postInvertBsub-1
					#endif
					LDA tmpA   ; PLA
				; lookup the LogOfSin
				TAX : LDA lookupLogOfSin,X
				; Add the logamp for this wave
				CLC : ADC logwaveYamp%,Y
				; lookup the un-logged result
					; ROR A : TAX : LDA lookupUnlog2,X
					BCC nodeltay
					TAX : LDA lookupUnlog2,X
				; this is what we should add to x, except we should
				; invert it if sinCharge says so!
				#ifdef FIX_NEGATIVE_BUG
					SEC : SBC #123 : .postInvertBsub
				#endif
				EOR #255 : .postInvertB
			.gotdeltay
				CLC : ADC ty : STA ty
			.nodeltay
		DEY : BPL loopWaves
		; DEY : BNE loopWavesOut : JMP loopWaves
		.loopWavesOut
		; OK so we have dotx,doty
		; LDA tx : STA dotx : LDA ty : STA doty
			; We want to divide both by 7!
			; n / 7 = n/256 * 36 = n/128 * 18
		.fixx
			; LDX #36 : LDA lookupLog,X
			; LDX dotx : CLC : ADC lookupLog,X
			; ROR A : TAX : LDA lookupUnlog2,X
			; LDA dotx : LSR A : LSR A : LSR A   ; simple divide by 8
			; are we negative?
			LDA dotx : ROL A : PHP : BCC skipA : EOR #255 : .skipA : LSR A
			; divide by 4, putting negative back on
			LSR A : LSR A
			PLP : BCC skipA2 : EOR #255 : .skipA2
			; finally add 40 to centralise horizontally
			CLC : ADC #40   ; 50 is furthest right
			STA dotx
		.fixy
			; LDX #36 : LDA lookupLog,X
			; LDX doty : CLC : ADC lookupLog,X
			; ROR A : TAX : LDA lookupUnlog2,X
			; LDA doty : LSR A : LSR A : LSR A   ; simple divide by 8
			; are we negative?
			LDA doty : ROL A : PHP : BCC skipB : EOR #255 : .skipB : LSR A
			; divide by 4, putting negative back on
			LSR A : LSR A
			PLP : BCC skipB2 : EOR #255 : .skipB2
			; finally add 36 to centralise vertically
			CLC : ADC #36   ; 42 is furthest down
			STA doty

		#ifdef PLOT_DOTS
			; Plot the pixel
			JSR plotTelexel
			#ifdef INTERPOLATE_DOTS_ONCE
				; LDA lastx : CLC : ADC dotx : ROR A : STA dotx
				; LDA lasty : CLC : ADC doty : ROR A : STA doty
				LDA dotx : STA tmpA : CLC : ADC lastx : ROR A : STA dotx : LDA tmpA : STA lastx
				LDA doty : STA tmpA : CLC : ADC lasty : ROR A : STA doty : LDA tmpA : STA lasty
				JSR plotTelexel
			#endif
		#endif

		#ifdef DRAW_LINE_WITH_BRESENHAM
			LDA angle : CMP #0 : BNE doDrawLine
			LDA firstTimeRound : CMP #0 : BEQ doDrawLine
			JMP skipDrawLine
			.doDrawLine
			#define x1 lastx
			#define y1 lasty
			#define x2 dotx
			#define y2 doty
			#define PLOT_POINT(x,y) JSR plotTelexel
			#include "drawLine.asm"
			.skipDrawLine
			LDA dotx : STA lastx
			LDA doty : STA lasty
			#undef x1
			#undef y1
			#undef x2
			#undef y2
			#undef PLOT_POINT
		#endif

		.skipPlot

		#ifdef ANGLESTEP_IS_1
			INC angle : BEQ plotLoopOut
		#else
			LDA angle : CLC : ADC #angleStep% : STA angle : BCS plotLoopOut
			;; Chop off end for testing purposes:
			; CMP #240 : BCC keepLooping
			; LDA angle : SEC : SBC #240 : STA angle : JMP plotLoopOut
			; .keepLooping
		#endif
		#ifdef DRAW_LINE_WITH_BRESENHAM
			LDA firstTimeRound : CMP #0 : BEQ plotLoopOutReal
		#endif
	JMP plotLoop
	.plotLoopOut

	#ifdef DRAW_LINE_WITH_BRESENHAM
		; We go around the loop 257 times, to draw the last line segment
		DEC firstTimeRound
		JMP plotLoop
		.plotLoopOutReal
	#endif

	LDA #0 : STA angle

	; LDA &FE64 : EOR &FE65 : CMP #255 : BNE noSpecial
	LDA framecounter : AND #127
	CMP #0 : BNE noSpecial
	; LDA framecounter+1 : AND #3 : CMP #0 : BNE noSpecial
		; TODO: We could decide to switch instead when
		;       waveXphase*==waveYphase*, since that produces a flat diagonal
		;       shape.
		; LDA #(32+16) : BIT &FE64 : BNE noSpecial   ; 1 in 4 chance of proceeding
		; New values!
		JSR createNewValues
	.noSpecial

	LDY #MOVEMENT_SPEED
	.rotate
		;; TODO: Could probably be faster with BCCs instead of BNEs, but a bit more
		;;       fiddly, requiring JMPs back to re-entry labels.
		;; TODO: When numWaves%<2 this breaks, when >2 it doesn't alter higher
		;; waves.  It should be done with DIMs like all the others :P
		;; Maybe for all these INCs and DECs we really do want zero-page storage.
		;; But if that is true, less accessed variables such as framecounter could
		;; be moved out of zero-page.
		;; TODO: More efficient than counters: use instead 8 or 16-bit fractional values.
		;; Create macros for these!
		; ; TYA : AND #1 : BNE noRotateZ
			; ; DEC waveYphase%
		; ; .noRotateZ
		; DEC rotateCounterA : BNE noRotateA
			; INC waveXphase%+1
			; LDA #5 : .rotateCounterALoc : STA rotateCounterA
		; .noRotateA
		; DEC rotateCounterB : BNE noRotateB
			; INC waveYphase%+1
			; LDA #3 : .rotateCounterBLoc : STA rotateCounterB
		; .noRotateB
		; DEC rotateCounterC : BNE noRotateC
			; INC waveXphase%   ; one of them should stay still!  in fact it's invisible if one does, since 1 is redundant
			; LDA #11 : .rotateCounterCLoc : STA rotateCounterC
		; .noRotateC
		; ; AND #4 : BNE noRotate
		; DEC rotateCounterD : BNE noRotateD
			; INC waveYphase%
			; LDA #2 : .rotateCounterDLoc : STA rotateCounterD
		; .noRotateD

		LDX #numWaves% : DEX
		.rotateLoop
			; DEC rotateCounterX,X : BNE noRotateX
				; INC waveXphase%,X
				; LDA rotateCounterMaxX,X : STA rotateCounterX,X
			; .noRotateX
			; DEC rotateCounterY,X : BNE noRotateY
				; INC waveYphase%,X
				; LDA rotateCounterMaxY,X : STA rotateCounterY,X
			; .noRotateY
			LDA rotateCounterX,X : CLC : ADC rotateCounterMaxX,X : STA rotateCounterX,X
			BCC noIncPhaseX : INC waveXphase%,X : .noIncPhaseX
			LDA rotateCounterY,X : CLC : ADC rotateCounterMaxY,X : STA rotateCounterY,X
			BCC noIncPhaseY : INC waveYphase%,X : .noIncPhaseY
		DEX : BPL rotateLoop
	DEY : BNE rotate
	.noRotate

	_INCdouble(framecounter)

	#ifdef LOOP_IN_FOREGROUND
		;; We still make occasional dropouts to allow BASIC to run
		LDA &FE64 : AND #31 : CMP #17 : BEQ dropOutThisOnce
		JMP start
		.dropOutThisOnce
	#endif

	#ifdef KEEP_INTERRUPTS
		SEI
		LDA #0 : STA alreadyRunning
	#endif

.leaveEvent
; LDA #19 : JSR &FFF4
RTS

; We cannot #include "plotTelexel.asm" twice because it has not localised its
; labels.  So in case we are using INTERPOLATE_DOTS_ONCE, we include it once here, and
; call the plotTelexel label it provides.
#include "plotTelexel.asm"
RTS

.createNewValues
	INC currentColor
	LDA currentColor : CMP #144+7 : BNE setupColorsSkip1
		LDA #144+1 : STA currentColor
	.setupColorsSkip1
	JSR setupColors
	#define GetRandom() EOR &FE64 : EOR tmpA : STA tmpA : DEC tmpA
	;; BUG: We do not deal with the general case here, just some code for numWaves%=2/3
	;; BUG: Ensures no 1,2s or 2,4s but creates 1,3 / 3,1 too often.
	GetRandom() : AND #2 : CLC : ADC #1 : STA wavefreq%   ; 1,3
	GetRandom() : AND #3 : CLC : ADC #1 : STA wavefreq%+1   ; 1-4
	; GetRandom() : AND #2 : CLC : ADC #3 : STA wavefreq%+2   ; 3,5
	GetRandom() : AND #3 : CLC : ADC #3 : STA wavefreq%+2   ; 3-6
	; TODO: We should do this now for numWaves%=3.
	LDA wavefreq% : CMP wavefreq%+1 : BNE waveFreqsUnique
		INC wavefreq%
	.waveFreqsUnique
	; #define MaybeInvert(byteLoc) LOAD_LABEL(miNeg) : LOAD_LABEL(miDone) : GetRandom() : ROL A : BCS miNeg : LDA _HASH 0 : JMP miDone : .miNeg : LDA _HASH 255 : .miDone : EOR byteLoc : STA byteLoc : SAVE_LABEL(miNeg) : SAVE_LABEL(miDone)   ; fuck! xD
	; MaybeInvert(wavefreq%)
	; MaybeInvert(wavefreq%+1)
	; MaybeInvert(wavefreq%+2)
	LDX #numWaves% : DEX
	.maybeInvertLoop
		; GetRandom() : ROL A : BCS miNeg
		; .miPos : LDA #0 : JMP miDone
		; .miNeg : LDA #255
		; .miDone
		; EOR wavefreq%,X
		; STA wavefreq%,X
		GetRandom() : ROL A : BCC miPos
			DEC wavefreq%,X : LDA wavefreq%,X : EOR #255 : STA wavefreq%,X
		.miPos
	DEX : BPL maybeInvertLoop
	;; Change phases
	;; Actually little point since they are driven by the rotateCounters.
	; LDA &FE64 : ROR A : ROR A : AND #3 : STA waveYphase% : INC waveYphase%
	; LDA &FE65 : ROR A : ROR A : AND #7 : STA waveYphase%+1 : INC waveYphase%+1
	;; BUG: If everything is high then the whole thing moves slow.
	; GetRandom() : AND #7 : CLC : ADC #3 : STA rotateCounterALoc-1
	; GetRandom() : AND #7 : CLC : ADC #3 : STA rotateCounterBLoc-1
	; GetRandom() : AND #7 : CLC : ADC #3 : STA rotateCounterCLoc-1
	; GetRandom() : AND #7 : CLC : ADC #3 : STA rotateCounterDLoc-1
	; LDX numWaves : DEX
	; .createNewValuesLoop2
		; GetRandom() : STA waveXphase%,X
		; GetRandom() : STA waveYphase%,X
	; DEX : BPL createNewValuesLoop2
	;; Change speeds
	LDX #numWaves% : DEX
	.createNewValuesLoop1
		; GetRandom() : AND #7 : CLC : ADC #3 : STA rotateCounterMaxX,X
		; GetRandom() : AND #7 : CLC : ADC #3 : STA rotateCounterMaxY,X
		GetRandom() : ORA #128 : AND #255-64 : STA rotateCounterMaxX,X
		GetRandom() : ORA #128 : AND #255-64 : STA rotateCounterMaxY,X
	DEX : BPL createNewValuesLoop1
RTS

.setupColors
	LDA #SCRTOP MOD 256 : STA plotLoc
	LDA #SCRTOP DIV 256 : STA plotLoc+1
	LDX #25
	LDY #0
	.setupColorsLoop
		DEX : BMI setupColorsLoopEnd
		LDA currentColor : STA (plotLoc),Y
		; INY
		; LDA #157 : STA (plotLoc),Y
		; DEY
		_add16(plotLoc+1,plotLoc,#0,#40,plotLoc+1,plotLoc)   ; this macro is not really short :P
		                                                     ; we always store 16-bit nums together, so no need to specify.  also it's rare we want a separate output, often we just want to add something
		JMP setupColorsLoop
	.setupColorsLoopEnd
RTS

	]
	NEXT I%
	; PRINT "?xdir=";~?xdir
	; PRINT "?ydir=";~?ydir
	; k$=GET$

ENDPROC

#endif

DEF FNgetSignedByte(byte%) IF byte%<128 THEN =byte% ELSE =byte%-256

;; This did not help.  The tokenised BASIC file was equally large.
; > SAVE "T.PHASE"

; > VDU 6 : MODE 7 : PRINT "Running..."

; >PRINT ~TOP
; >*CLOSE


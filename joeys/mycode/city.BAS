REM vim: ft=basic

> *BASIC

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
		IF fail%=0 THEN OSCLI "SAVE L.LOGS "+STR$~(lookupLog)+" +300"

	PRINT
	ON ERROR REPORT:PRINT " at line ";ERL:END

#ifdef ASSEMBLY

	#include "asm_common.jpp"

	PRINT "Assembling"
	PROCassemble

	CLS
	; FOR line%=0 TO 23 : PRINTTAB(0,i%);CHR$(148);STRING$(39,CHR$(160)); : NEXT line%

	; PRINTTAB(2) "log[0]=";(lookupLog?0);"  "
	; PRINTTAB(2) "log[1]=";(lookupLog?1);"  "
	; PRINTTAB(2) "log[2]=";(lookupLog?2);"  "
	; PRINTTAB(2) "log[3]=";(lookupLog?3);"  "
	; PRINTTAB(2) "log[127]=";(lookupLog?127);"  "
	; PRINT "log[255]=";(lookupLog?255);"  "

	PROCprepareScreen(2)

	startTime=TIME - 1   ; avoid /0 !
	!(framecounter)=0
	CALL init
	*FX 14,4
	; CALL start
	REPEAT
		; FOR f%=1 TO 10
			; CALL event
			; *FX 19
		; NEXT f%
		PRINTTAB(0,0);
		; ; PRINT "x=";(?x);"  ";"y=";(?y);"  "
		; ; PRINT "tx=";(?tx);"  ";"ty=";(?ty);"  "
		; ; PRINT "angle=";?angle;"  "
		; ; PRINT "angle=";(?angle);"  "
		; ; breaks: PRINTTAB(2) "3*54 = 162, loo=";lookupUnlog2(lookupLog(3) + lookupLog(54));"  "
		; ; PRINT "(";?lastx;",";?lasty;") - (";?dotx;",";?doty;")  "
		; ; PRINT "xdir=";~?xdir;"  ydir=";~?ydir;"  "
		; ; PRINT "x_dist=";~?x_dist;"  y_dist=";~?y_dist;"  "
		; PRINT "freqs:   ";FNgetSignedByte(wavefreq%?0);"   ";FNgetSignedByte(wavefreq%?1);"   ";FNgetSignedByte(wavefreq%?2);"     "
		; ; PRINT "Xamps(logged): ";logwaveXamp%?0;" ";logwaveXamp%?1;" ";logwaveXamp%?2;"  "
		; ; PRINT "Yamps(logged): ";logwaveYamp%?0;" ";logwaveYamp%?1;" ";logwaveYamp%?2;"  "
		; PRINT "speedX: ";rotateCounterMaxX?0;"  ";rotateCounterMaxX?1;"  ";rotateCounterMaxX?2;"  "
		; PRINT "speedY: ";rotateCounterMaxY?0;"  ";rotateCounterMaxY?1;"  ";rotateCounterMaxY?2;"  "
		; PRINT "phaseX: ";waveXphase%?0;"  ";waveXphase%?1;"  ";waveXphase%?2;"  "
		; PRINT "phaseY: ";waveYphase%?0;"  ";waveYphase%?1;"  ";waveYphase%?2;"  "
		; ; PRINT "frame=";(!framecounter);"  "
		; ; PRINT "secs=";((TIME-startTime) DIV 100);"  "
		; ; PRINT "fe67=";(?&FE67);"  " ; does not change from 255!
		; fps = ((!framecounter)*100 / (TIME-startTime))
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




#ifdef ASSEMBLY

DEF PROCassemble
	:
	DIM code 4800
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
	#include "plotTelexel.dims"
	x1=&81 : y1=&82
	x2=&83 : y2=&84
	charx=&85 : chary=&86
	bitx=&87 : bity=&88
	plotLoc=&89 : REM and &8A
	plotBit=&8B
	; lastx=&8C : lasty=&8D
	; DRAW_LINE_WITH_BRESENHAM
	x=&8C : y=&8D
	:
	numWaves=&80
	; tx=&8C : ty=&8D   ; I was just using these for testing
	#define tx dotx
	#define ty doty
	?numWaves = numWaves%
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
	; LDX #0 : STX rotation
	; LDA #1 : STA rotateCounterA : STA rotateCounterB : STA rotateCounterC
	#ifdef KEEP_INTERRUPTS
		LDA #0 : STA alreadyRunning
	#endif
	LDA #144+1 : STA currentColor
	; JSR setupColors
	_interceptEvent(4,&220,oldEvent,event)
RTS

.stop
  LDA #13 : LDX #4 : JSR &FFF4
  _removeEvent(4,&220,oldEvent,event)
RTS

; x=right across screen
; y=down screen
; z=into screen (depth)

.camx EQUB 0
.camy EQUB 0
.camz EQUB -35

.camHorizontalRot EQUB 0
.camVerticalRot EQUB 0

#define cubeDepth 42
#define cubeRadius 45
#define cubeHeight 12

; Top face of cuboid is A-B-C-D-A

.objAx EQUB 0
.objAz EQUB cubeDepth+cubeRadius
.objAy EQUB -cubeHeight

.objBx EQUB +cubeRadius
.objBz EQUB cubeDepth+0
.objBy EQUB -cubeHeight

.objCx EQUB 0
.objCz EQUB cubeDepth-cubeRadius
.objCy EQUB -cubeHeight

.objDx EQUB -cubeRadius
.objDz EQUB cubeDepth+0
.objDy EQUB -cubeHeight

.worldAx EQUB 123
.worldAy EQUB 123
.worldAz EQUB 123

.worldBx EQUB 123
.worldBy EQUB 123
.worldBz EQUB 123

.worldCx EQUB 123
.worldCy EQUB 123
.worldCz EQUB 123

.worldDx EQUB 123
.worldDy EQUB 123
.worldDz EQUB 123

.event

	#ifdef KEEP_INTERRUPTS
		LDA alreadyRunning : CMP #0 : BEQ okEvent : JMP leaveEvent
		.okEvent
		LDA #1 : STA alreadyRunning
		CLI
	#endif

.start

	; TODO: Strangely, even when we jump the main body, this program goes crazy!
	JMP noSpecial

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

	; Translate all the corners (per camera)
	; TODO

	; Rotate all the corners (per camera)

		_rotate2d(objAx,objAz,camHorizontalRot,worldAx,worldAz)
		_rotate2d(objBx,objBz,camHorizontalRot,worldBx,worldBz)
		_rotate2d(objCx,objCz,camHorizontalRot,worldCx,worldCz)
		_rotate2d(objDx,objDz,camHorizontalRot,worldDx,worldDz)

	; Project all the corners
		#define _project(x,y) LDA x : CLC : ADC _HASH 40 : STA x : LDA y : CLC : ADC _HASH 36 : STA y
		; sx = 40 + focaldist*worldx/worldz
		; sy = 36 + focaldist*worldx/worldz
		_project(worldAx,worldAz)
		_project(worldBx,worldBz)
		_project(worldCx,worldCz)
		_project(worldDx,worldDz)

	; Draw the neccessary lines

		LDA worldAx : STA x1
		LDA worldAz : STA y1
		LDA worldBx : STA x2
		LDA worldBz : STA y2
		JSR drawLine

		LDA worldBx : STA x1
		LDA worldBz : STA y1
		LDA worldCx : STA x2
		LDA worldCz : STA y2
		JSR drawLine

		LDA worldCx : STA x1
		LDA worldCz : STA y1
		LDA worldDx : STA x2
		LDA worldDz : STA y2
		JSR drawLine

		LDA worldDx : STA x1
		LDA worldDz : STA y1
		LDA worldAx : STA x2
		LDA worldAz : STA y2
		JSR drawLine

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

	; LDA &FE64 : EOR &FE65 : CMP #255 : BNE noSpecial
	LDA framecounter : AND #127
	CMP #0 : BNE noSpecial
	; LDA framecounter+1 : AND #3 : CMP #0 : BNE noSpecial
		; TODO: We could decide to switch instead when
		;       waveXphase*==waveYphase*, since that produces a flat diagonal
		;       shape.
		; LDA #(32+16) : BIT &FE64 : BNE noSpecial   ; 1 in 4 chance of proceeding
		; New values!
		; JSR createNewValues
	.noSpecial

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

	INC camHorizontalRot

.leaveEvent
; JMP (oldEvent)   ; This is done by _interceptEvent silly!
RTS

; We cannot #include "plotTelexel.asm" twice because it has not localised its
; labels.  So in case we are using INTERPOLATE_DOTS_ONCE, we include it once here, and
; call the plotTelexel label it provides.
#include "plotTelexel.asm"
RTS

.drawLine
	#define PLOT_POINT(x,y) JSR plotTelexel
	; #include "drawLine.asm"
	#undef PLOT_POINT
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


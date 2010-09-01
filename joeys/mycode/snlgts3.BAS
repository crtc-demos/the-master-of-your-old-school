; #define DIAMOND
#define CUBE

; MODE 4
; #define GetCol(E) 1
; MODE 5
; #define GetCol(E) 1 + (E MOD 3)
MODE 2   ;; Not enough memory for this atm!
#define GetCol(E) 1 + (E MOD 6)

PRINT ;~PAGE;" ";~TOP;" ";~LOMEM;" ";~HIMEM

; DIM code 400
code=&1000
#include "lookupSignedLog.dims"

step%=43
#ifdef DIAMOND
	numVertices% = 6
	numEdges% = 12
#endif
#ifdef CUBE
	numVertices% = 8
	numEdges% = 12
#endif

DIM vertX% numVertices%
DIM vertY% numVertices%
DIM vertZ% numVertices%
DIM edgeVertexA% numEdges%
DIM edgeVertexB% numEdges%

#define CreateVertex(i,x,y,z) vertX%?i=x : vertY%?i=y : vertZ%?i=z
#define CreateEdge(i,A,B) edgeVertexA%?i=A : edgeVertexB%?i=B

#ifdef DIAMOND
	vertX%?0 =  127 : vertY%?0 =    0 : vertZ%?0 =    0
	vertX%?1 = -127 : vertY%?1 =    0 : vertZ%?1 =    0
	vertX%?2 =    0 : vertY%?2 =  127 : vertZ%?2 =    0
	vertX%?3 =    0 : vertY%?3 = -127 : vertZ%?3 =    0
	vertX%?4 =    0 : vertY%?4 =    0 : vertZ%?4 =  127
	vertX%?5 =    0 : vertY%?5 =    0 : vertZ%?5 = -127
	edgeVertexA%?0=0 : edgeVertexB%?0=2
	edgeVertexA%?1=0 : edgeVertexB%?1=3
	edgeVertexA%?2=0 : edgeVertexB%?2=4
	edgeVertexA%?3=0 : edgeVertexB%?3=5
	edgeVertexA%?4=1 : edgeVertexB%?4=2
	edgeVertexA%?5=1 : edgeVertexB%?5=3
	edgeVertexA%?6=1 : edgeVertexB%?6=4
	edgeVertexA%?7=1 : edgeVertexB%?7=5
	edgeVertexA%?8=2 : edgeVertexB%?8=4
	edgeVertexA%?9=2 : edgeVertexB%?9=5
	edgeVertexA%?10=3 : edgeVertexB%?10=4
	edgeVertexA%?11=3 : edgeVertexB%?11=5
#endif
#ifdef CUBE
	cubeSize% = 75   ; I thought we should be able to reach 89 but there is draw fail at 85 or less!
	CreateVertex(0,-cubeSize%,-cubeSize%,-cubeSize%)
	CreateVertex(1,+cubeSize%,-cubeSize%,-cubeSize%)
	CreateVertex(2,-cubeSize%,+cubeSize%,-cubeSize%)
	CreateVertex(3,+cubeSize%,+cubeSize%,-cubeSize%)
	CreateVertex(4,-cubeSize%,-cubeSize%,+cubeSize%)
	CreateVertex(5,+cubeSize%,-cubeSize%,+cubeSize%)
	CreateVertex(6,-cubeSize%,+cubeSize%,+cubeSize%)
	CreateVertex(7,+cubeSize%,+cubeSize%,+cubeSize%)
	CreateEdge(0,0,1)
	CreateEdge(1,1,3)
	CreateEdge(2,3,2)
	CreateEdge(3,2,0)
	CreateEdge(4,4,5)
	CreateEdge(5,5,7)
	CreateEdge(6,7,6)
	CreateEdge(7,6,4)
	CreateEdge(8,0,4)
	CreateEdge(9,1,5)
	CreateEdge(10,2,6)
	CreateEdge(11,3,7)
#endif

PROCassemble

; CLS

; Initially rotate all vertices (pitch)
sin = SIN(-PI/12)
cos = SQR(1 - sin*sin)
matrix?0 = FNputSignedByte(127*cos)
matrix?1 = FNputSignedByte(-127*sin)
matrix?2 = FNputSignedByte(127*sin)
matrix?3 = FNputSignedByte(127*cos)
FOR vert%=0 TO numVertices%-1
	?x = vertZ%?vert%
	?y = vertY%?vert%
	CALL rotate
	vertZ%?vert% = FNgetSignedByte(?x_)
	vertY%?vert% = FNgetSignedByte(?y_)
NEXT

PRINT ;~PAGE;" ";~TOP;" ";~LOMEM;" ";~HIMEM

FOR angle = 0 TO 2*PI STEP PI/step%

	sin = SIN(angle)
	cos = SQR(1 - sin*sin)
	IF angle>PI/2 AND angle<3*PI/2 THEN cos = -cos

	matrix?0 = FNputSignedByte(127*cos)
	matrix?1 = FNputSignedByte(-127*sin)
	matrix?2 = FNputSignedByte(127*sin)
	matrix?3 = FNputSignedByte(127*cos)

	;; Camera setup
	F% = 64 : imgScale% = 2
	;; Or move the camera halfway towards the screen.  This causes world screen
	;; to shrink by half, so we double screen scaling to keep FOV 90.
	; F% = 32 : imgScale% = 4
	centreDepth% = 128 + F%

	/*
	FOR vertex%=0 TO numVertices%-1
		?x = vertX%?vertex%
		?y = vertY%?vertex%
		CALL rotate
		x_res% = FNgetSignedByte(?x) * cos - FNgetSignedByte(?y) * sin
		y_res% = FNgetSignedByte(?x) * sin + FNgetSignedByte(?y) * cos
		; Now we should have _x,_y signed bytes range -128 to +127
		GCOL 0,1+vertex%
		PLOT 69,640+4*FNgetSignedByte(?x_),512+4*FNgetSignedByte(?y_)
	NEXT
	*/

	*FX 19
	*FX 19
	CLS

	FOR edge%=0 TO numEdges%-1
		vertA% = edgeVertexA%?edge%
		vertB% = edgeVertexB%?edge%

		PRINTTAB(0,0);
		; PRINT "A=";vertA%;" B="vertB%;"  "

		; Rotate A
		?x = vertX%?vertA%
		?y = vertZ%?vertA%
		CALL rotate
		Ax% = FNgetSignedByte(?x_)
		Ay% = FNgetSignedByte(vertY%?vertA%)
		Az% = FNgetSignedByte(?y_) + centreDepth%   ; 64 to 255+64

		; Rotate B
		?x = vertX%?vertB%
		?y = vertZ%?vertB%
		CALL rotate
		Bx% = FNgetSignedByte(?x_)
		By% = FNgetSignedByte(vertY%?vertB%)
		Bz% = FNgetSignedByte(?y_) + centreDepth%   ; 64 to 255+64

		; Az% = Az% + 1
		; Bz% = Bz% + 1

		; PRINT "Ax=";Ax%;" Bx=";Bx%;"  "
		; PRINT "Ay=";Ay%;" By=";By%;"  "
		; PRINT "Az=";Az%;" Bz=";Bz%;"  "

		Adivisor = Az%/imgScale%/F%
		Bdivisor = Bz%/imgScale%/F%
		PRINT "Am = ";1/Adivisor;"  "
		PRINT "Bm = ";1/Bdivisor;"  "
		; With F=64,imgScale=2, Amult ranges 0.3 to 1.9 at least.
		; So we could apply it using existing log mults by halving it, applying it,
		; then doubling the result.  (Any overflow at the end implies we have gone
		; off the screen, a problem which already existed.)

		; Plot the mofo
		GCOL 0,GetCol(edge%)
		; MOVE 640+4*Ax%,512+4*Ay%
		; DRAW 640+4*Bx%,512+4*By%
		MOVE 640+4*imgScale%*F%*Ax%/Az%,512+4*imgScale%*F%*Ay%/Az%
		DRAW 640+4*imgScale%*F%*Bx%/Bz%,512+4*imgScale%*F%*By%/Bz%
	NEXT

NEXT angle

END

DEF FNgetSignedByte(byte%) IF byte%<128 THEN =byte% ELSE =byte%-256

DEF FNputSignedByte(num%) IF num%>=0 THEN =num% ELSE =256-ABS(num%)

DEF PROCassemble
x=&80 : y=&81
x_=&82 : y_=&83
matrix=&84 ; and 85,86,87
tmpA=&88
FOR I%=0 TO 2 STEP 2
P%=code
[OPT I%
.rotate
	PHP : PHA : TXA : PHA : TYA : PHA
	#include "rotate.asm"
	PLA : TAY : PLA : TAX : PLA : PLP
RTS
]
NEXT I%
ENDPROC


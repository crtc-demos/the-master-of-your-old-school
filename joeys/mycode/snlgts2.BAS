#include "asm_common.jpp"
#include "lookupSignedLog.dims"

#define PRINT_DEBUG_INFO
; #define DRAWING

#ifdef DRAWING
	MODE 2
	step%=43
#else
	MODE 7
	step%=128
#endif

#ifdef PRINT_DEBUG_INFO
	VDU 14
#endif

DIM code 1000
x=&80 : y=&81
x_=&82 : y_=&83
matrix=&84 ; and 85,86,87
tmpA=&88
FOR I%=0 TO 3 STEP 3
P%=code
_resetLabelCounters
[OPT I%
.rotate
	#include "rotate.asm"
RTS
]
NEXT I%

DIM vertX% 6
DIM vertY% 6
DIM vertZ% 6
vertX%?0 =    0 : vertY%?0 =  127 : vertZ%?0 =    0
vertX%?1 =    0 : vertY%?1 = -127 : vertZ%?1 =    0
vertX%?2 =  127 : vertY%?2 =    0 : vertZ%?2 =    0
vertX%?3 = -127 : vertY%?3 =    0 : vertZ%?3 =    0
vertX%?4 =    0 : vertY%?4 =    0 : vertZ%?4 =  127
vertX%?5 =    0 : vertY%?5 =    0 : vertZ%?5 = -127

CLS

FOR angle = 0 TO 2*PI STEP PI/step%

	sin = SIN(angle)
	cos = SQR(1 - sin*sin)
	IF angle>PI/2 AND angle<3*PI/2 THEN cos = -cos

	matrix?0 = FNputSignedByte(127*cos)
	matrix?1 = FNputSignedByte(-127*sin)
	matrix?2 = FNputSignedByte(127*sin)
	matrix?3 = FNputSignedByte(127*cos)

	FOR vertex%=0 TO 3
		?x = vertX%?vertex%
		?y = vertY%?vertex%
		CALL rotate
		x_res% = FNgetSignedByte(?x) * cos - FNgetSignedByte(?y) * sin
		y_res% = FNgetSignedByte(?x) * sin + FNgetSignedByte(?y) * cos
		; Now we should have _x,_y signed bytes range -128 to +127
		#ifdef PRINT_DEBUG_INFO
			error% = ABS(x_res% - FNgetSignedByte(?x_)) + ABS(y_res% - FNgetSignedByte(?y_))
			IF error% < 3 THEN PROCshowGoodResult ELSE PROCshowBadResult
		#endif
		#ifdef DRAWING
			GCOL 0,1+vertex%
			PLOT 69,640+4*FNgetSignedByte(?x_),512+4*FNgetSignedByte(?y_)
		#endif
	NEXT

NEXT angle

END

DEF FNbit(ang)
	IF ang<0 THEN = 128
=0

DEF FNgetSignedByte(byte%)
	IF byte%<128 THEN =byte%
= -256 + byte%

DEF FNputSignedByte(num%)
	IF num%>=0 THEN =num%
= 256 - ABS(num%)

#ifdef PRINT_DEBUG_INFO
	DEF PROCshowGoodResult
		PRINT "OK ";vertex%;" (";(angle*180/PI)DIV1;") (";FNgetSignedByte(?x);",";FNgetSignedByte(?y);") -> (";FNgetSignedByte(?x_);",";FNgetSignedByte(?y_);") [";error%;"]"
	ENDPROC
	DEF PROCshowBadResult
		PRINT "Error at ";vertex%;" (";(angle*180/PI)DIV1;")"
		PRINT "  | ";FNgetSignedByte(matrix?0);" ";FNgetSignedByte(matrix?1);" |"
		PRINT "  | ";FNgetSignedByte(matrix?2);" ";FNgetSignedByte(matrix?3);" |"
		PRINT "  From (";FNgetSignedByte(?x);",";FNgetSignedByte(?y);")"
		PRINT "  want (";x_res%;",";y_res%;")"
		PRINT "   got (";FNgetSignedByte(?x_);",";FNgetSignedByte(?y_);") ?"
		PRINT "  sin=";sin;" cos=";cos
		PRINT "  lSL?x=";lookupSignedLog?(?x);" lSL?a=";lookupSignedLog?(matrix?0)
		PRINT "  lSL?y=";lookupSignedLog?(?y);" lSL?b=";lookupSignedLog?(matrix?1)
		PRINT "  lSL?x+lSL?a=";(lookupSignedLog?(?x) + lookupSignedLog?(matrix?0))
		PRINT "  lSL?y+lSL?b=";(lookupSignedLog?(?y) + lookupSignedLog?(matrix?1))
		; PRINT "  lSL?x=";lookupSignedLog?(?x);" lSL?c=";lookupSignedLog?(matrix?2)
		; PRINT "  lSL?y=";lookupSignedLog?(?y);" lSL?d=";lookupSignedLog?(matrix?3)
		; PRINT "  lSL?x+lSL?c=";(lookupSignedLog?(?x) + lookupSignedLog?(matrix?2))
		; PRINT "  lSL?y+lSL?d=";(lookupSignedLog?(?y) + lookupSignedLog?(matrix?3))
		; PRINT ;?x;" -> ";FNgetSignedByte(?x_);"   ";?y;" -> ";FNgetSignedByte(?y_)
	ENDPROC
#endif

#ifdef PRINT_DEBUG_INFO
> VDU 14
#endif


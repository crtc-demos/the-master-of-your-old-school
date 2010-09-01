MODE 7

MEM%=&7C00
MEM%=&80

REPEAT

  FOR Y%=0 TO 15
  D%=0
  PRINTTAB(0,4+Y%);FNhexWord(MEM%+Y%*8);
  VDU 9,131
  FOR X%=0 TO 7
    V%=?(MEM%+X%+Y%*8)
    REM IF X%=4 THEN VDU 9
    PRINT ;FNhexByte(V%);
    ?(&7C00+31+X%+D%+(4+Y%)*40)=V%
    VDU 9
  NEXT
  VDU 130
  NEXT

UNTIL FALSE

END

:

DEF FNhexByte(X%)
h$="0123456789abcdef"
=MID$(h$,X% DIV 16+1,1)+MID$(h$,X% MOD 16+1,1)

DEF FNhexWord(m%)
=FNhexByte(m% DIV 256)+FNhexByte(m% MOD 256)


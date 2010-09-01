
MODE 7

*FX 4,1    ; Capture cursor keys
*FX 200,1  ; Disable ESCAPE key

x%=0 : y%=0

REPEAT

  PRINTTAB(x%,y%);
  loc% = &7C00 + 40*y% + x%

  K=GET

  IF K=&88 OR K=127 THEN x%=(x%-1+40) MOD 40
  IF K=&89 OR K=32 THEN x%=(x%+1+40) MOD 40
  IF K=13 THEN y%=(y%+1+25) MOD 25 : x%=0
  IF K=&8A THEN y%=(y%+1+25) MOD 25
  IF K=&8B THEN y%=(y%-1+25) MOD 25

  IF K=ASC("Q") THEN ?loc%=?loc% OR 160 EOR 1
  IF K=ASC("W") THEN ?loc%=?loc% OR 160 EOR 2
  IF K=ASC("A") THEN ?loc%=?loc% OR 160 EOR 4
  IF K=ASC("S") THEN ?loc%=?loc% OR 160 EOR 8
  IF K=ASC("Z") THEN ?loc%=?loc% OR 160 EOR 16
  IF K=ASC("X") THEN ?loc%=?loc% OR 160 EOR 64

  IF K=ASC("R") THEN ?loc%=GET
  IF K=ASC("I") THEN PROCdoInput

  IF K=ASC("?") THEN PROCdoInfo

UNTIL FALSE

DEF PROCdoInput
  PROCsaveTopLine
  INPUT input%
  PROCrestoreTopLine
  ?loc% = input%
ENDPROC

DEF PROCsaveTopLine
  ; topline$ = LEFT$($&7C00,40)
  topline$ = ""
  FOR l%=&7C00 TO &7C00+39 : topline$=topline$+CHR$(?l%) : NEXT l%
  PRINTTAB(0,0);STRING$(40," ");
  PRINTTAB(0,0);
ENDPROC

DEF PROCrestoreTopLine
  PRINTTAB(0,0);topline$;
ENDPROC

DEF PROCdoInfo
  PROCsaveTopLine
  PRINT "?&";~loc%;" = ";?loc%;" (";~?loc%;")";
  PROCpause(200)
  PROCrestoreTopLine
ENDPROC

DEF PROCpause(duration)
  startTime=TIME
  REPEAT : UNTIL TIME > startTime+duration
ENDPROC


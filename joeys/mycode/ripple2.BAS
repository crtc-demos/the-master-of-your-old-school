REM vim: ft=basic noexpandtab ts=2 sw=2 wrap listchars=tab\:|\ ,trail\:% showbreak=::::::::

; TODO: This would be much better in MODE 4.  We could do 1-pixel shifting of
; specific lines at pre-calculated times to provide the ripple and effect and
; an overall left scroll of the desired speed.  In the sky the same text
; scrolls at that speed without the ripple.

#define numlines 11

DIM line$(numlines)

 line$(1)="##  ###  #   ## ###"
 line$(2)="# # #   # # #   #  "
 line$(3)="##  ### ### #   ###"
 line$(4)="#   #   # # #   #  "
 line$(5)="#   ### # #  ## ###"
 line$(6)=""
 line$(7)="        # #"
 line$(8)="#      #####      #"
 line$(9)="        ###"
line$(10)="         #"

VDU 23,1,0;0;0;0;

CLS

FOR line%=1 TO numlines
  PRINTTAB(10,-1+line%);line$(line%);
NEXT

FOR line%=0 TO numlines+1
  PRINTTAB(0,24-line%);CHR$(132);CHR$(157);CHR$(130);
NEXT

consta = 2*PI/10

FOR frame%=1 TO 1000

  parama = frame%*2*PI/7
  paramb = 1 : REM SIN(frame%*2*PI/100)
  ; amp=0.7
  amp=0.3

  FOR line%=1 TO numlines
    delta% = (numlines+2-line%)*amp * SIN(line%*consta - parama) * paramb   ; this needs 0.5 for rounding but that sucked :o
    PRINTTAB(3,24-line%);STRING$(37," ");
    PRINTTAB(10+delta%,24-line%);line$(line%);
  NEXT

  ; *FX 19 ; lol

NEXT


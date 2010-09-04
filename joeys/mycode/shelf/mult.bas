
10020 DIM code 800
10030 FOR I%=0 TO 3 STEP 3
10040 result=&80
10050 numA=&81
10060 numB=&82
10060 numC=&83
10070 P%=code
10080 [OPT I%

#include "mult8.asm"

10570 ]
10580 NEXT
10590 :
10600 REM If this takes ages and then throws a "No FOR" error, we won!
10610 FOR a%=255 TO 0 STEP -1
10620 FOR b%=0 TO 255
10640   ?numA=a% : ?numB=b%
10630   CALL multiply8to16
11111   IF a%*b% <> (!numB) THEN PRINT (!numB);" != ";a%;" * ";b%
10630   IF a%*b% > 255 THEN NEXT : NEXT
10640   ?numA=a% : ?numB=b%
10650   CALL multiply8
10660   IF (a%*b%)MOD256 <> ?result THEN PRINT ?result;" != ";a%;" * ";b%
10670   IF b% = 0 THEN NEXT : NEXT
10680   ?numA=a% : ?numB=b%
10690   CALL divide8
10700   IF (a%/b%)DIV1 <> ?numA THEN PRINT ?numA;" != ";a%;" / ";b%
10710 NEXT
10720 NEXT

RUN


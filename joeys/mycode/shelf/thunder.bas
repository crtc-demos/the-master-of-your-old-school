10000 REPEAT
10020   T%=RND(10)*30
10040   FOR P%=255 TO 0 STEP -1
10060     SOUND1,0,P%,0
10080     SOUND&10,-1,7,-1
10100   NEXT
10120   SOUND&10,0,0,0
10140   TIME=0:REPEAT:UNTIL TIME=T%
10160 UNTIL FALSE
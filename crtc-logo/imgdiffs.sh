#!/bin/sh
set -e
set -x
./rle blank.dump blkrle
./eor blank.dump letterc.dump blank-to-c
./rle blank-to-c b2crle
./eor letterc.dump letterr.dump c-to-r
./rle c-to-r c2rrle
./eor letterr.dump lettert.dump r-to-t
./rle r-to-t r2trle
./eor lettert.dump letterc.dump t-to-c
./rle t-to-c t2crle
rm -f c-to-r r-to-t t-to-c blank-to-c

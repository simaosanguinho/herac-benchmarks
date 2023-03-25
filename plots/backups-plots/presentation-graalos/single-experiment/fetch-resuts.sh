#!/bin/bash

SRC=../../../results/java
DST=results/java

for sandbox in isolate runtime process
do
    cp -r $SRC/gv-hello-world-niuk-$sandbox-benchmark-1-1-2048      $DST
#    cp -r $SRC/gv-file-hashing-niuk-$sandbox-benchmark-1-1-2048     $DST
#    cp -r $SRC/gv-httprequest-niuk-$sandbox-benchmark-1-1-2048      $DST
#    cp -r $SRC/gv-video-processing-niuk-$sandbox-benchmark-1-1-2048 $DST
#    cp -r $SRC/gv-classify-niuk-$sandbox-benchmark-1-1-2048         $DST
done

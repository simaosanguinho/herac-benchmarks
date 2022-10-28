#!/bin/bash

set -e;

rm -rf .logs/ .plots/
./build.sh
./run.sh 1 100000 no_warmup && ./run.sh 1000000 100000 warmup
./plot.py logs/no_warmup logs/warmup

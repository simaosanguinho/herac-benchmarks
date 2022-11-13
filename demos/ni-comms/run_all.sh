#!/bin/bash

set -e;

rm -rf ./logs/ ./plots/

# ./build.sh
# ./run.sh 1000000 100000 0 flush
# ./run.sh 1000000 100000 8192 buffer
# ./plot.py ./logs/flush ./logs/buffer
# ./save_plots.sh


./build.sh
./run.sh 1000 1000 0 openSocket
./plot.py ./logs/openSocket

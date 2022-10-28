#!/bin/bash

set -e;

rm -rf ./logs/ ./plots/

####
# rm -rf /ramfs/osd
# mkdir -p /ramfs/osd/logs
# mkdir -p /ramfs/osd/plots
# ln -s /ramfs/osd/logs logs
# ln -s /ramfs/osd/plots plots
####

./build.sh
./run.sh 1 100000 no_warmup && ./run.sh 1000000 100000 warmup
./plot.py ./logs/no_warmup ./logs/warmup
./save_plots.sh

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
./run.sh 10000 10000 osd
./plot.py ./logs/osd
# ./save_plots.sh

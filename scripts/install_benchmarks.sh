#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
APP_DIR=$DIR/../data/apps
LOG=$DIR/install_benchmarks.log

JV_GV_BENCHMARKS="$JV_GV_BENCHMARKS java/gv-sleep"
JV_GV_BENCHMARKS="$JV_GV_BENCHMARKS java/gv-hello-world"
JV_GV_BENCHMARKS="$JV_GV_BENCHMARKS java/gv-file-hashing"
JV_GV_BENCHMARKS="$JV_GV_BENCHMARKS java/gv-httprequest"
JV_GV_BENCHMARKS="$JV_GV_BENCHMARKS java/gv-classify"
JV_GV_BENCHMARKS="$JV_GV_BENCHMARKS java/gv-video-processing"
# (disabled) #JV_GV_BENCHMARKS="$JV_GV_BENCHMARKS java/gv-shopcart"

# (disabled) #JV_CR_BENCHMARKS="$JV_CR_BENCHMARKS java/cr-sleep"
JV_CR_BENCHMARKS="$JV_CR_BENCHMARKS java/cr-hello-world"
JV_CR_BENCHMARKS="$JV_CR_BENCHMARKS java/cr-file-hashing"
JV_CR_BENCHMARKS="$JV_CR_BENCHMARKS java/cr-httprequest"
JV_CR_BENCHMARKS="$JV_CR_BENCHMARKS java/cr-classify"
JV_CR_BENCHMARKS="$JV_CR_BENCHMARKS java/cr-video-processing"

# (disabled) #PY_GV_BENCHMARKS="$PY_GV_BENCHMARKS python/gv-sleep"
PY_GV_BENCHMARKS="$PY_GV_BENCHMARKS python/gv-thumbnail"
PY_GV_BENCHMARKS="$PY_GV_BENCHMARKS python/gv-compression"
PY_GV_BENCHMARKS="$PY_GV_BENCHMARKS python/gv-hello-world"
PY_GV_BENCHMARKS="$PY_GV_BENCHMARKS python/gv-dynamic-html"
PY_GV_BENCHMARKS="$PY_GV_BENCHMARKS python/gv-mst"
PY_GV_BENCHMARKS="$PY_GV_BENCHMARKS python/gv-uploader"
PY_GV_BENCHMARKS="$PY_GV_BENCHMARKS python/gv-video-processing"
PY_GV_BENCHMARKS="$PY_GV_BENCHMARKS python/gv-bfs"
PY_GV_BENCHMARKS="$PY_GV_BENCHMARKS python/gv-pagerank"
PY_GV_BENCHMARKS="$PY_GV_BENCHMARKS python/gv-dna"
PY_GV_BENCHMARKS="$PY_GV_BENCHMARKS python/gv-classify"

# (disabled) #PY_CR_BENCHMARKS="$PY_CR_BENCHMARKS python/cr-sleep"
PY_CR_BENCHMARKS="$PY_CR_BENCHMARKS python/cr-thumbnail"
PY_CR_BENCHMARKS="$PY_CR_BENCHMARKS python/cr-compression"
PY_CR_BENCHMARKS="$PY_CR_BENCHMARKS python/cr-hello-world"
PY_CR_BENCHMARKS="$PY_CR_BENCHMARKS python/cr-dynamic-html"
PY_CR_BENCHMARKS="$PY_CR_BENCHMARKS python/cr-mst"
PY_CR_BENCHMARKS="$PY_CR_BENCHMARKS python/cr-uploader"
PY_CR_BENCHMARKS="$PY_CR_BENCHMARKS python/cr-video-processing"
PY_CR_BENCHMARKS="$PY_CR_BENCHMARKS python/cr-bfs"
PY_CR_BENCHMARKS="$PY_CR_BENCHMARKS python/cr-pagerank"
PY_CR_BENCHMARKS="$PY_CR_BENCHMARKS python/cr-dna"
PY_CR_BENCHMARKS="$PY_CR_BENCHMARKS python/cr-classify"

# (disabled) #JS_GV_BENCHMARKS="$JS_GV_BENCHMARKS javascript/gv-sleep"
JS_GV_BENCHMARKS="$JS_GV_BENCHMARKS javascript/gv-hello-world"
JS_GV_BENCHMARKS="$JS_GV_BENCHMARKS javascript/gv-dynamic-html"
JS_GV_BENCHMARKS="$JS_GV_BENCHMARKS javascript/gv-thumbnail"
JS_GV_BENCHMARKS="$JS_GV_BENCHMARKS javascript/gv-uploader"

JS_CR_BENCHMARKS="$JS_CR_BENCHMARKS javascript/cr-thumbnail"
JS_CR_BENCHMARKS="$JS_CR_BENCHMARKS javascript/cr-hello-world"
JS_CR_BENCHMARKS="$JS_CR_BENCHMARKS javascript/cr-dynamic-html"
JS_CR_BENCHMARKS="$JS_CR_BENCHMARKS javascript/cr-uploader"
JS_CR_BENCHMARKS="$JS_CR_BENCHMARKS javascript/cr-sleep"

if [ -z "$ARGO_HOME" ]
then
        echo "Please set ARGO_HOME first. It should point to a checkout of github.com/graalvm/argo."
        exit 1
fi

if [ -z "$JAVA_HOME" ]
then
        echo "Please set JAVA_HOME first. It should be a GraalVM with native-image available."
        exit 1
fi

INSTALL_SET=""
read -p "Install Graalvisor's Java benchmarks (y or Y, everything else as no)? " -n 1 -r
echo    # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    INSTALL_SET="$INSTALL_SET $JV_GV_BENCHMARKS"
fi
read -p "Install Graalvisor's Python benchmarks (y or Y, everything else as no)? " -n 1 -r
echo    # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    INSTALL_SET="$INSTALL_SET $PY_GV_BENCHMARKS"
fi
read -p "Install Graalvisor's JavaScript benchmarks (y or Y, everything else as no)? " -n 1 -r
echo    # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    INSTALL_SET="$INSTALL_SET $JS_GV_BENCHMARKS"
fi


# Rotate the log.
rm $LOG &> /dev/null

# Ensure that the directory where we install already exists.
mkdir -p $APP_DIR &> /dev/null

for benchmark in $INSTALL_SET
do
    install_script=$DIR/../src/$benchmark/install_script.sh
    if [ -f "$install_script" ]; then
        echo -n "Installing $benchmark..."
        bash $install_script $APP_DIR 2>&1 >> $LOG
        echo "done!"
    else
        echo "$install_script DOES NOT exist, skipping."
    fi
done

#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
LOG=$DIR/build_benchmarks.log

# (disabled) #JV_HY_BENCHMARKS="$JV_HY_BENCHMARKS java/hy-sleep"
JV_HY_BENCHMARKS="$JV_HY_BENCHMARKS java/hy-hello-world"
JV_HY_BENCHMARKS="$JV_HY_BENCHMARKS java/hy-file-hashing"
JV_HY_BENCHMARKS="$JV_HY_BENCHMARKS java/hy-httprequest"
JV_HY_BENCHMARKS="$JV_HY_BENCHMARKS java/hy-classify"
JV_HY_BENCHMARKS="$JV_HY_BENCHMARKS java/hy-video-processing"
# (disabled) #JV_HY_BENCHMARKS="$JV_HY_BENCHMARKS java/hy-shopcart"

# (disabled) #JV_CR_BENCHMARKS="$JV_CR_BENCHMARKS java/cr-sleep"
JV_CR_BENCHMARKS="$JV_CR_BENCHMARKS java/cr-hello-world"
JV_CR_BENCHMARKS="$JV_CR_BENCHMARKS java/cr-file-hashing"
JV_CR_BENCHMARKS="$JV_CR_BENCHMARKS java/cr-httprequest"
JV_CR_BENCHMARKS="$JV_CR_BENCHMARKS java/cr-classify"
JV_CR_BENCHMARKS="$JV_CR_BENCHMARKS java/cr-video-processing"

# (disabled) #PY_HY_BENCHMARKS="$PY_HY_BENCHMARKS python/hy-sleep"
PY_HY_BENCHMARKS="$PY_HY_BENCHMARKS python/hy-thumbnail"
PY_HY_BENCHMARKS="$PY_HY_BENCHMARKS python/hy-compression"
PY_HY_BENCHMARKS="$PY_HY_BENCHMARKS python/hy-hello-world"
PY_HY_BENCHMARKS="$PY_HY_BENCHMARKS python/hy-dynamic-html"
PY_HY_BENCHMARKS="$PY_HY_BENCHMARKS python/hy-mst"
PY_HY_BENCHMARKS="$PY_HY_BENCHMARKS python/hy-uploader"
PY_HY_BENCHMARKS="$PY_HY_BENCHMARKS python/hy-video-processing"
PY_HY_BENCHMARKS="$PY_HY_BENCHMARKS python/hy-bfs"
PY_HY_BENCHMARKS="$PY_HY_BENCHMARKS python/hy-pagerank"
PY_HY_BENCHMARKS="$PY_HY_BENCHMARKS python/hy-dna"
PY_HY_BENCHMARKS="$PY_HY_BENCHMARKS python/hy-classify"

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

# (disabled) #JS_HY_BENCHMARKS="$JS_HY_BENCHMARKS javascript/hy-sleep"
JS_HY_BENCHMARKS="$JS_HY_BENCHMARKS javascript/hy-hello-world"
JS_HY_BENCHMARKS="$JS_HY_BENCHMARKS javascript/hy-dynamic-html"
JS_HY_BENCHMARKS="$JS_HY_BENCHMARKS javascript/hy-thumbnail"
JS_HY_BENCHMARKS="$JS_HY_BENCHMARKS javascript/hy-uploader"

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

BUILD_SET=""
read -p "Build Hydra's Java benchmarks (y or Y, everything else as no)? " -n 1 -r
echo    # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    BUILD_SET="$BUILD_SET $JV_HY_BENCHMARKS"
fi
read -p "Build Hydra's Python benchmarks (y or Y, everything else as no)? " -n 1 -r
echo    # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    BUILD_SET="$BUILD_SET $PY_HY_BENCHMARKS"
fi
read -p "Build Hydra's JavaScript benchmarks (y or Y, everything else as no)? " -n 1 -r
echo    # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    BUILD_SET="$BUILD_SET $JS_HY_BENCHMARKS"
fi
read -p "Build OpenWhisk's Java benchmarks (y or Y, everything else as no)? " -n 1 -r
echo    # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    BUILD_SET="$BUILD_SET $JV_CR_BENCHMARKS"
fi
read -p "Build OpenWhisk's Python benchmarks (y or Y, everything else as no)? " -n 1 -r
echo    # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    BUILD_SET="$BUILD_SET $PY_CR_BENCHMARKS"
fi
read -p "Build OpenWhisk's JavaScript benchmarks (y or Y, everything else as no)? " -n 1 -r
echo    # move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
    BUILD_SET="$BUILD_SET $JS_CR_BENCHMARKS"
fi

rm $LOG &> /dev/null
for benchmark in $BUILD_SET
do
    build_script=$DIR/../src/$benchmark/build_script.sh
    if [ -f "$build_script" ]; then
        echo -n "Building $benchmark..."
        if [[ $benchmark == *"/hy-"* ]]; then
            $DIR/build_benchmark.sh $build_script build_ni_sharedlibrary 2>&1 | tee -a $LOG | grep -q "Finished generating" || echo "Failed to build $benchmark!"
        else
            $DIR/build_benchmark.sh $build_script 2>&1 >> $LOG
        fi
        echo "done!"
    else
        echo "$build_script/build_script.sh DOES NOT exist, skipping."
    fi
done

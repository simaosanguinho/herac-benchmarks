#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

JV_BENCHMARKS="$JV_BENCHMARKS java/array-sorting"
JV_BENCHMARKS="$JV_BENCHMARKS java/gv-sleep"
JV_BENCHMARKS="$JV_BENCHMARKS java/reflection-call"
JV_BENCHMARKS="$JV_BENCHMARKS java/file-hashing"
JV_BENCHMARKS="$JV_BENCHMARKS java/aes"
JV_BENCHMARKS="$JV_BENCHMARKS java/sleep"
JV_BENCHMARKS="$JV_BENCHMARKS java/thumbnail"

JV_GV_BENCHMARKS="$JV_GV_BENCHMARKS java/gv-hello-world"
JV_GV_BENCHMARKS="$JV_GV_BENCHMARKS java/gv-shopcart"
JV_GV_BENCHMARKS="$JV_GV_BENCHMARKS java/gv-file-hashing"
JV_GV_BENCHMARKS="$JV_GV_BENCHMARKS java/gv-classify"
JV_GV_BENCHMARKS="$JV_GV_BENCHMARKS java/gv-httprequest"
JV_VG_BENCHMARKS="$JV_GV_BENCHMARKS java/gv-video-processing"

JV_CR_BENCHMARKS="$JV_CR_BENCHMARKS java/cr-file-hashing"
JV_CR_BENCHMARKS="$JV_CR_BENCHMARKS java/cr-hello-world"
JV_CR_BENCHMARKS="$JV_CR_BENCHMARKS java/cr-httprequest"
JV_CR_BENCHMARKS="$JV_CR_BENCHMARKS java/cr-classify"
JV_CR_BENCHMARKS="$JV_CR_BENCHMARKS java/cr-sleep"
JV_CR_BENCHMARKS="$JV_CR_BENCHMARKS java/cr-video-processing"

PH_BENCHMARKS="$PH_BENCHMARKS python/array-sorting"
PH_BENCHMARKS="$PH_BENCHMARKS python/hello-world"
PH_BENCHMARKS="$PH_BENCHMARKS python/file-hashing"
PH_BENCHMARKS="$PH_BENCHMARKS python/aes"

PH_GV_BENCHMARKS="$PH_GV_BENCHMARKS python/gv-sleep"
PH_GV_BENCHMARKS="$PH_GV_BENCHMARKS python/gv-warble"
PH_GV_BENCHMARKS="$PH_GV_BENCHMARKS python/gv-hello-world"
PH_GV_BENCHMARKS="$PH_GV_BENCHMARKS python/gv-mst"
PH_GV_BENCHMARKS="$PH_GV_BENCHMARKS python/gv-dynamic-html"
PH_GV_BENCHMARKS="$PH_GV_BENCHMARKS python/gv-compression"
PH_GV_BENCHMARKS="$PH_GV_BENCHMARKS python/gv-thumbnail"
PH_GV_BENCHMARKS="$PH_GV_BENCHMARKS python/gv-video-processing"
PH_GV_BENCHMARKS="$PH_GV_BENCHMARKS python/gv-uploader"

PH_CR_BENCHMARKS="$PH_CR_BENCHMARKS python/cr-thumbnail"
PH_CR_BENCHMARKS="$PH_CR_BENCHMARKS python/cr-compression"
PH_CR_BENCHMARKS="$PH_CR_BENCHMARKS python/cr-hello-world"
PH_CR_BENCHMARKS="$PH_CR_BENCHMARKS python/cr-dynamic-html"
PH_CR_BENCHMARKS="$PH_CR_BENCHMARKS python/cr-mst"
PH_CR_BENCHMARKS="$PH_CR_BENCHMARKS python/cr-uploader"
PH_CR_BENCHMARKS="$PH_CR_BENCHMARKS python/cr-sleep"
PH_CR_BENCHMARKS="$PH_CR_BENCHMARKS python/cr-video-processing"

JS_BENCHMARKS="$JS_BENCHMARKS javascript/array-sorting"
JS_BENCHMARKS="$JS_BENCHMARKS javascript/hello-world"
JS_BENCHMARKS="$JS_BENCHMARKS javascript/file-hashing"
JS_BENCHMARKS="$JS_BENCHMARKS javascript/aes"

JS_GV_BENCHMARKS="$JS_GV_BENCHMARKS javascript/gv-sleep"
JS_GV_BENCHMARKS="$JS_GV_BENCHMARKS javascript/gv-hello-world"
JS_GV_BENCHMARKS="$JS_GV_BENCHMARKS javascript/gv-dynamic-html"
JS_GV_BENCHMARKS="$JS_GV_BENCHMARKS javascript/gv-thumbnail"
JS_GV_BENCHMARKS="$JS_GV_BENCHMARKS javascript/gv-uploader"

JS_CR_BENCHMARKS="$JS_CR_BENCHMARKS javascript/cr-thumbnail"
JS_CR_BENCHMARKS="$JS_CR_BENCHMARKS javascript/cr-hello-world"
JS_CR_BENCHMARKS="$JS_CR_BENCHMARKS javascript/cr-dynamic-html"
JS_CR_BENCHMARKS="$JS_CR_BENCHMARKS javascript/cr-uploader"
JS_CR_BENCHMARKS="$JS_CR_BENCHMARKS javascript/cr-sleep"

BUILD_SET="$BUILD_SET $JV_GV_BENCHMARKS"
BUILD_SET="$BUILD_SET $JV_CR_BENCHMARKS"
BUILD_SET="$BUILD_SET $PH_GV_BENCHMARKS"
BUILD_SET="$BUILD_SET $PH_CR_BENCHMARKS"
BUILD_SET="$BUILD_SET $JS_GV_BENCHMARKS"
BUILD_SET="$BUILD_SET $JS_CR_BENCHMARKS"

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

for benchmark in $BUILD_SET
do
	benchmark_path=$DIR/../src/$benchmark
	if [ -f "$benchmark_path/build_script.sh" ]; then
		echo "$benchmark_path/build_script.sh exists, building..."
		cd $benchmark_path
		bash build_script.sh
		cd - &> /dev/null
		echo "$benchmark_path/build_script.sh exists, building... done!"
	else
		echo "$benchmark_path/build_script.sh DOES NOT exist, skipping."
	fi
done

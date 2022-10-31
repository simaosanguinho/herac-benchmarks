#!/bin/bash

# run.sh [warmup_runs] [runs] [log_dir_name]

if [ ! -f build/libs/demo-ni-osd-1.0-all.jar ]; then
	echo "demoosd JAR missing, rebuilding"
	./build.sh
elif [ ! -f build/demoosd ]; then
	echo "demoosd native image missing, rebuilding"
	./build.sh
fi

. ./.env

echo "JAVA_HOME=$JAVA_HOME"
echo "GRAALVM_HOME=$GRAALVM_HOME"

runs=1000
warmup=1000000
timestamp=$(date +%s)
if [ $# -ge 1 ]; then
	warmup=$1
	if [ $# -ge 2 ]; then
		runs=$2
		if [ $# -ge 3 ]; then
			timestamp=$3
		fi
	fi
fi

cd build

store_dir=../logs/$timestamp
mkdir -p $store_dir

tests=(
	sRInt4
	sRInt8
	sRStr064
	sRStr128
	sALst4
	sALst8
	sHMap4
	sHMap8
	dRInt4
	dRInt8
	dRStr064
	dRStr128
	dALst4
	dALst8
	dHMap4
	dHMap8
)

set -e;

for test in "${tests[@]}"; do
	mkdir -p $store_dir/$test

	echo "Running $test on JVM with $warmup warmup runs and $runs iterations"

	$JAVA_HOME/bin/java \
		-ea \
		-jar libs/demo-ni-osd-1.0-all.jar \
		$test --runs $runs --warmup $warmup \
		> $store_dir/$test/jvm.log 2>&1 &

	wait

	echo "Running $test on SVM with $warmup warmup runs and $runs iterations"

	./demoosd \
		$test --runs $runs --warmup $warmup \
		> $store_dir/$test/svm.log 2>&1 &

	wait
done

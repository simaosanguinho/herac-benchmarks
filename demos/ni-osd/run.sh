#!/bin/bash

if [ ! -f build/libs/demo-ni-osd-1.0-all.jar ]; then
	echo "demoosd JAR missing, rebuilding"
	./build.sh
elif [ ! -f build/demoosd ]; then
	echo "demoosd native image missing, rebuilding"
	./build.sh
fi

cd build
timestamp=$(date +%s)
store_dir=../logs/$timestamp
mkdir -p $store_dir

echo $JAVA_HOME

runs=1000
warmup=1000000
bufsize=8192
if [ $# -ge 1 ]; then
	warmup=$1
	if [ $# -ge 2 ]; then
		runs=$2
		if [ $# -ge 3 ]; then
			bufsize=$3
		fi
	fi
fi

tests=(
	serializeSmall4
	serializeSmall8
	deserializeSmall4
	deserializeSmall8
)

set -e;

for test in "${tests[@]}"; do
	mkdir -p $store_dir/$test

	echo "Running $test on JVM with $runs iterations"

	$JAVA_HOME/bin/java \
		-jar libs/demo-ni-osd-1.0-all.jar \
		$test --runs $runs --warmup $warmup \
		| tee $store_dir/$test/jvm_server.log &

	wait

	echo "Running $test on SVM with $runs iterations"

	./demoosd \
		$test --runs $runs --warmup $warmup \
		| tee $store_dir/$test/svm_client.log &

	wait
done

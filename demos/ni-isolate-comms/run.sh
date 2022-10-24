#!/bin/bash

if [ ! -f build/demoisolatecomms ]
then
	echo "build files missing, rebuilding"
	./build.sh
fi

cd build
timestamp=$(date +%s)
store_dir=../logs/$timestamp
mkdir -p $store_dir

echo $JAVA_HOME

runs=1000
warmup=0
if [ $# -ge 1 ]; then
	runs=$1
	if [ $# -ge 2 ]; then
		warmup=$2
	fi
fi

tests=(
	networkCommsTest
)

set -e;

for test in $tests; do
	mkdir -p $store_dir/$test

	echo "Running $test on JVM with $runs iterations"

	$JAVA_HOME/bin/java \
		-jar libs/demo-ni-isolate-comms-1.0-all.jar \
		--server $test --runs $runs --warmup $warmup \
		| tee $store_dir/$test/jvm_server.log &

	sleep 1

	$JAVA_HOME/bin/java \
		-jar libs/demo-ni-isolate-comms-1.0-all.jar \
		--client $test --runs $runs --warmup $warmup \
		| tee $store_dir/$test/jvm_client.log &

	wait

	echo "Running $test on SVM with $runs iterations"

	./demoisolatecomms \
		--server $test --runs $runs --warmup $warmup \
		| tee $store_dir/$test/svm_server.log &

	sleep 1

	./demoisolatecomms \
		--client $test --runs $runs --warmup $warmup \
		| tee $store_dir/$test/svm_client.log &

	wait
done

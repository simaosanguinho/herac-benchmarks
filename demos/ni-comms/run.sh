#!/bin/bash

# run.sh [warmup_runs] [runs] [bufsize] [log_dir_name]

if [ ! -f build/libs/demo-ni-comms-1.0-all.jar ]; then
	echo "democomms JAR missing, rebuilding"
	./build.sh
elif [ ! -f build/democomms ]; then
	echo "democomms native image missing, rebuilding"
	./build.sh
fi

. ./.env
echo "JAVA_HOME=$JAVA_HOME"
echo "GRAALVM_HOME=$GRAALVM_HOME"

runs=1000
warmup=1000000
bufsize=8192
timestamp=$(date +%s)
if [ $# -ge 1 ]; then
	warmup=$1
	if [ $# -ge 2 ]; then
		runs=$2
		if [ $# -ge 3 ]; then
			bufsize=$3
			if [ $# -ge 4 ]; then
				timestamp=$4
			fi
		fi
	fi
fi

cd build

store_dir=../logs/$timestamp
mkdir -p $store_dir

tests=(
	net1_32B
	net2_64B
	net3_128B
	net4_256B
	net5_512B
	net6_1KB
	# net7_10KB
	# net8_100KB
	# net9_1MB
)

set -e;

for test in "${tests[@]}"; do
	mkdir -p $store_dir/$test

	echo "Running $test on JVM with $warmup warmup runs and $runs iterations"

	$JAVA_HOME/bin/java \
		-ea \
		-jar libs/demo-ni-comms-1.0-all.jar \
		--server $test --runs $runs --warmup $warmup --bufsize $bufsize \
		> $store_dir/$test/jvm_server.log 2>&1 &

	sleep 1

	$JAVA_HOME/bin/java \
		-ea \
		-jar libs/demo-ni-comms-1.0-all.jar \
		--client $test --runs $runs --warmup $warmup --bufsize $bufsize \
		> $store_dir/$test/jvm_client.log 2>&1 &

	wait

	echo "Running $test on SVM with $warmup warmup runs and $runs iterations"

	./democomms \
		--server $test --runs $runs --warmup $warmup --bufsize $bufsize \
		> $store_dir/$test/svm_server.log 2>&1 &

	sleep 1

	./democomms \
		--client $test --runs $runs --warmup $warmup --bufsize $bufsize \
		> $store_dir/$test/svm_client.log 2>&1 &

	wait
done

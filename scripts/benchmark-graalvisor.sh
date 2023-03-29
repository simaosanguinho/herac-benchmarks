#!/bin/bash

function DIR {
	echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

source $(DIR)/test-shared.sh
source $(DIR)/test-benchmark.sh

# Processing input parameters
if [ "$#" -lt 3 ]; then
	echo "Syntax: <svm|container|niuk> <gv_java_hw|gv_javascript_hw|gv_python_hw> <test|benchmark> [<tests|concurrency> [<cpu> [<memory>]]]"
	exit 1
fi

backend=$1
app=$2
mode=$3

if [ "$#" -ge 4 ]; then
	workload=$4
else
	if [ "$mode" = "test" ]; then
		workload=10
	else
		workload=1
	fi
fi

if [ "$#" -ge 5 ]; then
	CPU=$5
fi

if [ "$#" -ge 6 ]; then
	MEM=$6
fi

function benchmark {
	if [ -z "$WMULTIPLIER" ]; then
		WMULTIPLIER=256
	fi

	if [ ! -z "$WARMUP" ]; then
	        ab -p $APP_POST -T application/json -c 1 -n $WARMUP http://$ip:8080/warmup &> $tmpdir/ab.log
	fi

	ab -p $APP_POST -T application/json -c $workload -n $((workload * WMULTIPLIER)) http://$ip:8080/ &> $tmpdir/ab.log
	rm $tmpdir/ab.log
	for i in $(seq 1 3)
	do
		ab -p $APP_POST -T application/json -c $workload -n $((workload * WMULTIPLIER))  http://$ip:8080/ &>> $tmpdir/ab.log
	done
}

function test {
	for i in $(seq 1 $workload)
	do
		pretime
		curl -s -X POST $ip:8080 -H 'Content-Type: application/json' -d $(cat $APP_POST)
		postime
	done
}

# Writing post file to disk
APP_POST=$tmpdir/payload.post

# Preparing working directory
sudo rm -r $tmpdir/ &> /dev/null
mkdir $tmpdir &> /dev/null

# Setting up environment.
if [ "$backend" == "container" ]; then
	ip=127.0.0.1
	start_container &> $tmpdir/lambda.log &
elif [ "$backend" == "svm" ]; then
	ip=127.0.0.1
	start_svm &> $tmpdir/lambda.log &
elif [ "$backend" == "niuk" ]; then
	# Note: ip is already set when loading test-shared.sh
	start_niuk &> $tmpdir/lambda.log &
fi

# Let graalvisor start.
wait_port $ip 8080

# Get PID of lambda.
if [ "$backend" == "container" ]; then
	PID=$(docker inspect --format '{{ .State.Pid }}' gcontainer)
elif [ "$backend" == "svm" ]; then
	PID=$(sudo fuser -v -n tcp 8080 2>&1 | grep 8080/tcp | awk '{print $3}')
elif [ "$backend" == "niuk" ]; then
	PID=$(sudo fuser /tmp/testtap.socket 2>&1 | awk '{print $2}') &> /dev/null
fi

# Log memory.
log_rss $PID $tmpdir/lambda.rss &

# Adding lambda to cgroup.
if [ ! -z "$CGROUP" ]
then
	echo "Adding $PID to cgroup $CGROUP"
	echo $PID | sudo tee -a /sys/fs/cgroup/$CGROUP/cgroup.procs
	echo "Setting $PID to core 0"
	sudo taskset -cp 0 $PID
fi

# Setting a sandbox if not already set.
if [ -z "$SANDBOX" ]
then
	if [[ $app == *"_java_"* ]]; then
		export SANDBOX=isolate
		#export SANDBOX=runtime
		#export SANDBOX=process
	else
		export SANDBOX=context
	fi
fi

echo "Running environment=$backend; sandbox=$SANDBOX; app=$app; mode=$mode; workload=$workload; cpu=$CPU; mem=$MEM"

# Load function into runtime.
$app

# Run test/benchmark.
$mode | tee -a $tmpdir/app.log

# Teardown environment.
if [ "$backend" == "container" ]; then
	stop_container &>> $tmpdir/lambda.log
elif [ "$backend" == "svm" ]; then
	stop_baremetal &>> $tmpdir/lambda.log
elif [ "$backend" == "niuk" ]; then
	stop_niuk &>> $tmpdir/lambda.log
fi
wait

# Copy output to app's privde result dir.
RESULT_DIR=$BENCHMARKS_HOME/results/$APP_LANG/$APP_NAME-$backend-$SANDBOX-$mode-$workload-$CPU-$MEM
mkdir -p $RESULT_DIR
cp $tmpdir/{lambda.*,ab.log,app.log} $RESULT_DIR &> /dev/null
echo "Check logs: $RESULT_DIR/lambda.log"

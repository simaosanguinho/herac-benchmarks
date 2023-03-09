#!/bin/bash

function DIR {
	echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

source $(DIR)/test-shared.sh
source $(DIR)/test-benchmark.sh

# Processing input parameters
if [ "$#" -lt 3 ]; then
	echo "Syntax: <jvm|svm|niuk> <gv_java_hw|gv_javascript_hw|gv_python_hw> <test|benchmark> [<tests|concurrency> [<cpu> [<memory>]]]"
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
		WMULTIPLIER=100
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

# Deleting old dat and log files
rm $tmpdir/{*.dat,*.log} &> /dev/null

# Setting up environment.
if [ "$backend" == "jvm" ]; then
	ip=127.0.0.1
	# TODO - jvm does not support so apps (Java built as Native Library). We should instead send a Jar.
	start_polyglot_jvm &> $tmpdir/lambda.log &
elif [ "$backend" == "container" ]; then
	ip=127.0.0.1
	setup_polyglot_container
	start_polyglot_container &> $tmpdir/lambda.log &
elif [ "$backend" == "svm" ]; then
	ip=127.0.0.1
	setup_polyglot_svm
	start_polyglot_svm &> $tmpdir/lambda.log &
elif [ "$backend" == "niuk" ]; then
	# Note: ip is already set when loading test-shared.sh
	setup_polyglot_niuk
	start_polyglot_niuk &> $tmpdir/lambda.log &
fi

# Let graalvisor start.
sleep 1 

# Adding firecracker to cgroup.
if [ ! -z "$CGROUP" ]
then
        # This is a workaround to identify the PID of the firecracker vm.
	PID=$(ps aux | grep firecracker | grep testtap.socket | awk '{print $2}')
	echo "Adding $PID to cgroup $CGROUP"
	echo $PID | sudo tee -a /sys/fs/cgroup/$CGROUP/cgroup.procs
	echo "Setting $PID to core 0"
	sudo taskset -cp 0 $PID

fi

# Setting a sandbox if not already set.
if [ -z "$SANDBOX" ]
then
	if [[ $app == *"_java_"* || $app == "gv_javascript_dynamichtml" || $app == "gv_javascript_thumbnail" ]]; then
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
if [ "$backend" == "jvm" ]; then
	stop_baremetal &>> $tmpdir/lambda.log
elif [ "$backend" == "container" ]; then
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

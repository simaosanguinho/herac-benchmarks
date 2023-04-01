#!/bin/bash

function DIR {
	echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

source $(DIR)/test-shared.sh
source $(DIR)/test-benchmark.sh

# Processing input parameters
if [ "$#" -lt 3 ]; then
	echo "Syntax: <container|vm> <cr_java_hw|cr_javascript_hw|cr_python_hw> <test|benchmark> [<tests|concurrency> [<cpu> [<memory>]]]"
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

	for i in $(seq 1 3)
	do
		ab -p $RUN_POST -T application/json -c $workload -n $((workload * WMULTIPLIER))  http://$ip:8080/run &> $tmpdir/ab.log
	done
}

function test {
	for i in $(seq 1 $workload)
	do
		pretime
		curl -s -X POST $ip:8080/run -H 'Content-Type: application/json' -d @$RUN_POST
		postime
	done
}

VMID=benchvm

# Preparing working directory
sudo rm -r $tmpdir/ &> /dev/null
mkdir $tmpdir &> /dev/null

echo "Running environment=$backend; app=$app; mode=$mode; workload=$workload; cpu=$CPU; mem=$MEM"

# Load function to benchmark
$app

# Starting the lambda.
if [ "$backend" == "container" ]; then
	ip=127.0.0.1
	docker run -d --rm --name=ccontainer --network host $IMG &> $tmpdir/lambda.log
elif [ "$backend" == "vm" ]; then
        create_tap
	sudo $CRUNTIME_HOME/start-vm -ip $ip/$smask -gw $gateway -tap $tap -id $VMID -img $IMG -mem $MEM -cpu $CPU
fi

# Let the lambda start.
wait_port $ip 8080

# Get PID of lambda.
if [ "$backend" == "container" ]; then
	PID=$(docker inspect --format '{{ .State.Pid }}' ccontainer)
elif [ "$backend" == "vm" ]; then
	PID=$(ps aux | grep firecracker | grep $VMID | awk '{print $2}')
fi

# Log memory.
log_rss $PID $tmpdir/lambda.rss &

# Adding firecracker to cgroup.
if [ ! -z "$CGROUP" ]
then
	echo "Adding $PID to cgroup $CGROUP"
	echo $PID | sudo tee -a /sys/fs/cgroup/$CGROUP/cgroup.procs
	echo "Setting $PID to core 0"
	sudo taskset -cp 0 $PID
fi

# Load function to benchmark
curl -s -X POST $ip:8080/init -H 'Content-Type: application/json' -d @$INIT_POST

# Run test/benchmark.
$mode | tee -a $tmpdir/app.log

# Teardown the lambda.
if [ "$backend" == "container" ]; then
	docker kill ccontainer &> $tmpdir/lambda.log
elif [ "$backend" == "vm" ]; then
	sudo $CRUNTIME_HOME/stop-vm -id $VMID
	remove_tap
fi
wait

# Copy output to app's privde result dir.
RESULT_DIR=$BENCHMARKS_HOME/results/$APP_LANG/$APP_NAME-$mode-$workload-$CPU-$MEM
mkdir -p $RESULT_DIR
cp $tmpdir/lambda.* $tmpdir/*.log $RESULT_DIR &> /dev/null
echo "Check logs: $RESULT_DIR/lambda.log"

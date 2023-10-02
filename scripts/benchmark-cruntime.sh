#!/bin/bash

function DIR {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

source $(DIR)/shared.sh
source $(DIR)/benchmarks.sh

if [ "$#" -ne 4 ]; then
    echo "Syntax: <container|vm> <app> <mode> <# of tests or concurrency level>"
    echo "Available backends: container (Docker container), vm (Firecracker VM)."
    echo "Available apps: $CR_BENCHMARKS"
    echo "Available modes: test benchmark. Test will perform a number of requests. Benchmark will use apache bench with the desired concurrency level."
    echo "Example: benchmark-cruntime.sh container cr_java_hw test 1"
    echo "Available environment variables: "
    echo "- ITERATIONS=<number> - number of iterations the workload is ran. Defaults to 1;"
    echo "- WMULTIPLIER=<number> - workload multiplier to scale up or down the length of the benchmark (only used in benchmark mode). Defaults to 256;"
    echo "- CGROUP=<name> - name of the cgroup to use. A directory with that name will be created under /sys/fs/cgroup. Defaults to empty which leads to no CGROUP being used;"
    echo "- CGROUP_CPU_QUOTA=<number> - CPU quota for a 100ms period. A quota 100000 means using a full core. Only used if CGROUP is set. Defaults to 100000 (full core)."
    echo "- VM_CPU=<number> - number of cores that the VM will create internally (only used in vm mode). Defaults to 1;"
    echo "- VM_MEM=<number> - memory given to the VM (only used in vm mode). Defaults to 2048;"
    echo "- PIN_CORE=<boolean> - if true, will pin the process to core 0. Defaults to false;"
    echo "- DISABLE_TURBO=<boolean> - if true, will disable turbo boost. Defaults to false;"
    exit 1
else
    backend=$1
    app=$2
    mode=$3
    workload=$4
fi

function benchmark {
    if [ -z "$WMULTIPLIER" ]; then
        WMULTIPLIER=256
    fi

    ab -p $RUN_POST -T application/json -c $workload -n $((workload * WMULTIPLIER))  http://$IP:8080/run &> $TDIR/ab.log
}

function test {
    for i in $(seq 1 $workload)
    do
        pretime
        curl -s -X POST $IP:8080/run -H 'Content-Type: application/json' -d @$RUN_POST
        postime
    done
}

function run {
    # Setting up environment.
    if [ "$backend" == "container" ]; then
        IP=127.0.0.1
        start_ow_container &> $TDIR/lambda.log &
    elif [ "$backend" == "vm" ]; then
        # Note: ip is already set when loading shared.sh
        start_ow_vm &> $TDIR/lambda.log &
    fi

    # Let the lambda start.
    wait_port $IP 8080

    # Get PID of lambda.
    if [ "$backend" == "container" ]; then
        PID=$(docker inspect --format '{{ .State.Pid }}' bcontainer)
    elif [ "$backend" == "vm" ]; then
        PID=$(cat $TDIR/lambda.pid)
    fi

    # Write lambda pid to file.
    echo -n "$PID" > $TDIR/lambda.pid

    # Log memory.
    log_rss $PID $TDIR/lambda.rss &

    # Prepares the local resources (cgroups, core pinning, turbo boost).
    prepare_resources

    # Load function to benchmark
    curl -s -X POST $IP:8080/init -H 'Content-Type: application/json' -d @$INIT_POST

    # Run test/benchmark.
    $mode | tee -a $TDIR/app.log

    # Teardown the lambda.
    if [ "$backend" == "container" ]; then
        stop_container
    elif [ "$backend" == "vm" ]; then
        stop_vm
    fi
    wait

    # Teardown local resource changes (delete cgroups, enable turbo boost).
    teardown_resources
}

echo "Running environment=$backend; app=$app; mode=$mode; workload=$workload; cpu=$VM_CPU; mem=$VM_MEM"

# Preparing working directory
sudo rm -r $TDIR/ &> /dev/null
mkdir $TDIR &> /dev/null

# Load function to benchmark
$app

for iter in $(seq 1 $ITERATIONS)
do
    # Run...
    run
    # Preparing results directory
    results_dir=$BENCHMARKS_HOME/results/$APP_LANG/$APP_NAME-$backend-$mode-$workload-$VM_CPU-$VM_MEM/$iter
    mkdir -p $results_dir &> /dev/null
    cp $TDIR/{*.log,*.rss} $results_dir &> /dev/null
    echo "Saved logs (iteration $iter): $results_dir/lambda.log"
done

#!/bin/bash

function DIR {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

source $(DIR)/shared.sh
source $(DIR)/benchmarks.sh

if [ "$#" -ne 4 ]; then
    echo "Syntax: <svm|container|vm> <app> <mode> <# of tests or concurrency level>"
    echo "Available backends: svm (Native Image), container (Docker container), vm (Firecracker VM)."
    echo "Available apps: $GV_BENCHMARKS"
    echo "Available modes: test benchmark. Test will perform a number of requests. Benchmark will use apache bench with the desired concurrency level."
    echo "Example: benchmark-graalvisor.sh svm gv_java_hw test 1"
    echo "Available environment variables: "
    echo "- SANDBOX=<isolate|runtime|process|context|snapshot> - isolation level of concurrent requests in graalvisor. Defaults to isolate or context depending on the function language;"
    echo "- SNAPSHOT=<path> - path on disk where the snapshot should be stored/loaded from; Defaults to empty which leads to no snapshot being stored/loaded;"
    echo "- ITERATIONS=<number> - number of iterations the workload is ran. Defaults to 1;"
    echo "- WMULTIPLIER=<number> - workload multiplier to scale up or down the length of the benchmark (only used in benchmark mode). Defaults to 256;"
    echo "- WARMUP=<number> - number of warmup requests sent to graalvisor. Defaults to zero;"
    echo "- CGROUP=<name> - name of the cgroup to use. A directory with that name will be created under /sys/fs/cgroup. Defaults to empty which leads to no CGROUP being used;"
    echo "- CGROUP_CPU_QUOTA=<number> - CPU quota for a 100ms period. A quota 100000 means using a full core. Only used if CGROUP is set. Defaults to 100000 (full core)."
    echo "- VM_CPU=<number> - number of cores that the VM will create internally (only used in vm mode). Defaults to 1;"
    echo "- VM_MEM=<number> - memory given to the VM (only used in vm mode). Defaults to 2048;"
    echo "- PIN_CORE=<boolean> - if true, will pin the process to core 0. Defaults to false;"
    echo "- DISABLE_TURBO=<boolean> - if true, will disable turbo boost. Defaults to false;"
    echo "- EXPERIMENT=<tag> - if set, will copy result logs into a dedicated experiment directory. Defaults to unset;"
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

    if [ ! -z "$WARMUP" ]; then
        printf "Sending $WARMUP warmup requests:\n"
        request "$IP:$GRAALVISOR_PORT/warmup?concurrency=$WARMUP\&requests=$WARMUP"
    fi

    printf "Running ab (check $TDIR/ab.log).\n"
    ab -p $RUN_POST -T application/json -c $workload -n $((workload * WMULTIPLIER)) http://$IP:$GRAALVISOR_PORT/ &> $TDIR/ab.log
}

function test {
    if [ ! -z "$WARMUP" ]; then
        printf "Sending $WARMUP warmup requests:\n"
        request $IP:$GRAALVISOR_PORT/warmup?concurrency=$WARMUP\&requests=$WARMUP
    fi

    printf "Sending $workload requests:\n"
    for i in $(seq 1 $workload)
    do
        request $IP:$GRAALVISOR_PORT
    done
}

function stress {
    request $IP:$GRAALVISOR_PORT/stress?concurrency=100000\&requests=$workload
}

function run {
    # Setting up environment.
    echo "Waiting for $backend..." | tee $TDIR/backend.log
    sbs=$(date +%s%N)
    if [ "$backend" == "svm" ]; then
        IP=127.0.0.1
        start_svm &>> $TDIR/backend.log &
    elif [ "$backend" == "container" ]; then
        IP=127.0.0.1
        start_gv_container &>> $TDIR/backend.log &
    elif [ "$backend" == "vm" ]; then
        # Note: ip is already set when loading shared.sh
        start_gv_vm &>> $TDIR/backend.log &
    fi

    # Let the lambda start.
    wait_port $IP $GRAALVISOR_PORT

    # Measure how long it took to accept connections.
    sbt=$((($(date +%s%N) - $sbs)/1000))
    echo "Waiting for $backend... done (took $sbt us)." | tee -a $TDIR/backend.log

    # Get PID of lambda.
    if [ "$backend" == "svm" ]; then
        # Note: wait until lambda.pid is filled.
        while [ ! -f $TDIR/lambda.pid ]; do sleep 0.01; done
        PID=$(cat $TDIR/lambda.pid)
        PID=$(pgrep -P $PID)
        echo -n "$PID" > $TDIR/lambda.pid
    elif [ "$backend" == "container" ]; then
        PID=$(docker inspect --format '{{ .State.Pid }}' bcontainer)
        echo -n "$PID" > $TDIR/lambda.pid
    elif [ "$backend" == "vm" ]; then
        # Note: wait until lambda.pid is filled.
        while [ ! -f $TDIR/lambda.pid ]; do sleep 0.01; done
        PID=$(cat $TDIR/lambda.pid)
    fi

    # Log Resources (memory and CPU)
    log_resources $PID $TDIR &

    # Prepares the local resources (cgroups, core pinning, turbo boost).
    prepare_resources

    # Load function into runtime and prepare payload.
    RUN_POST=$TDIR/payload.post
    $app

    # Run test/benchmark.
    $mode 2>&1 | tee -a $TDIR/app.log

    # Allow time for final collection of resource utilization.
    sleep 1

    # Teardown the lambda.
    if [ "$backend" == "svm" ]; then
        stop_svm &>> $TDIR/backend.log
    elif [ "$backend" == "container" ]; then
        stop_container &>> $TDIR/backend.log
    elif [ "$backend" == "vm" ]; then
        stop_vm &>> $TDIR/backend.log
    fi
    wait

    # Teardown local resource changes (delete cgroups, enable turbo boost).
    teardown_resources

    # Saving logs.
    backup_results
}

check_permissions

# Setting a sandbox if not already set.
if [ -z "$SANDBOX" ]
then
    if [[ $app == *"_java_"* ]]; then
        export SANDBOX=isolate
    else
        export SANDBOX=context
    fi
fi

echo "$(tput bold)Running graalvisor environment=$backend; sandbox=$SANDBOX; app=$app; mode=$mode; workload=$workload; cpu=$VM_CPU; mem=$VM_MEM:$(tput sgr0)"

# Print if this run will perform some snapshotting.
if [ ! -z "$SNAPSHOT" ]; then echo "SNAPSHOT = $SNAPSHOT"; fi

# Preparing working directory
echo "Removing $TDIR and $ADIR"
rm -rf $TDIR
# Note: we do not remove the app dir to facilitate snapshot testing.
# You may want to call benchmark-clean.sh before you call this script.
mkdir -p $TDIR
mkdir -p $ADIR

for iter in $(seq 1 $ITERATIONS)
do
    run
done

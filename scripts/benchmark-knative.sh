#!/bin/bash

function DIR {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

source $(DIR)/shared.sh
source $(DIR)/benchmarks.sh


if [ "$#" -ne 3 ]; then
    echo "Syntax: <app> <mode> <# of tests or concurrency level>"
    echo "Available backends: container (Docker container)."
    echo "Available apps: $KN_BENCHMARKS"
    echo "Available modes: test benchmark. Test will perform a number of requests. Benchmark will use apache bench with the desired concurrency level."
    echo "Example: benchmark-knative.sh container kn_java_hw test 1"
    echo "Available environment variables: "
    echo "- ITERATIONS=<number> - number of iterations the workload is ran. Defaults to 1;"
    echo "- WMULTIPLIER=<number> - workload multiplier to scale up or down the length of the benchmark (only used in benchmark mode). Defaults to 256;"
    echo "- CGROUP=<name> - name of the cgroup to use. A directory with that name will be created under /sys/fs/cgroup. Defaults to empty which leads to no CGROUP being used;"
    echo "- CGROUP_CPU_QUOTA=<number> - CPU quota for a 100ms period. A quota 100000 means using a full core. Only used if CGROUP is set. Defaults to 100000 (full core)."
    echo "- VM_CPU=<number> - number of cores that the VM will create internally (only used in vm mode). Defaults to 1;"
    echo "- VM_MEM=<number> - memory given to the VM (only used in vm mode). Defaults to 2048;"
    echo "- PIN_CORE=<boolean> - if true, will pin the process to core 0. Defaults to false;"
    echo "- DISABLE_TURBO=<boolean> - if true, will disable turbo boost. Defaults to false;"
    echo "- EXPERIMENT=<tag> - if set, will copy result logs into a dedicated experiment directory. Defaults to unset;"
    exit 1
else
    app=$1
    mode=$2
    workload=$3
    backend="container"
fi

function benchmark {
    if [ -z "$WMULTIPLIER" ]; then
        WMULTIPLIER=256
    fi

    printf "Running ab (check $TDIR/ab.log).\n"
    ab -l -p $RUN_POST -T application/json -c $workload -n $((workload * WMULTIPLIER))  http://$IP:$KNATIVE_PORT/ &> $TDIR/ab.log
}

function test {
    printf "Sending $workload requests:\n"
    for i in $(seq 1 $workload)
    do
        request $IP:$KNATIVE_PORT
    done
}

function run {
    # Setting up environment.
    echo "Waiting for $backend..." | tee $TDIR/backend.log
    sbs=$(date +%s%N)
    IP=127.0.0.1
    start_kn_container &>> $TDIR/backend.log &

    # Let the lambda start.
    wait_port $IP $KNATIVE_PORT
    # TODO: wait_port doesn't wait for port, make a more robust active wait for port.
    sleep 2

    # Measure how long it took to accept connections.
    sbt=$((($(date +%s%N) - $sbs)/1000))
    echo "Waiting for $backend... done (took $sbt us)." | tee -a $TDIR/backend.log

    # Get PID of lambda.
    PID=$(docker inspect --format '{{ .State.Pid }}' bcontainer)
    echo -n "$PID" > $TDIR/lambda.pid

    # Log Resources (memory and CPU)
    log_resources $PID $TDIR &

    # Prepares the local resources (cgroups, core pinning, turbo boost).
    prepare_resources

    # Run test/benchmark.
    $mode 2>&1 | tee -a $TDIR/app.log

     # Allow time for final collection of resource utilization.
    sleep 1

    # Teardown the lambda.
    stop_container &>> $TDIR/backend.log
    wait

    # Teardown local resource changes (delete cgroups, enable turbo boost).
    teardown_resources

    # Saving logs.
    backup_results
}

check_permissions

# Knative only supports process isolation.
export SANDBOX=process

echo "$(tput bold)Running knative environment=$backend; app=$app; mode=$mode; workload=$workload; cpu=$VM_CPU; mem=$VM_MEM:$(tput sgr0)"

# Preparing working directory
rm -rf $TDIR
mkdir -p $TDIR

# Load function to benchmark
RUN_POST=$TDIR/payload.post
$app

for iter in $(seq 1 $ITERATIONS)
do
    run
done

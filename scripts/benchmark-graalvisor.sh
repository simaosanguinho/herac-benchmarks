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
    echo "- SANDBOX=<isolate|runtime|process|context> - isolation level of concurrent requests in graalvisor. Defaults to isolate or context depending on the function language;"
    echo "- SNAPSHOT=<path> - path on disk where the snapshot should be stored/loaded from; Defaults to empty which leads to no snapshot being stored/loaded;"
    echo "- ITERATIONS=<number> - number of iterations the workload is ran. Defaults to 1;"
    echo "- WMULTIPLIER=<number> - workload multiplier to scale up or down the length of the benchmark (only used in benchmark mode). Defaults to 256;"
    echo "- WARMUP=<number> - number of warmup requests sent to graalvisor. Only used in benchmark mode. Defaults to zero;"
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
            ab -p $APP_POST -T application/json -c 1 -n $WARMUP http://$IP:8080/warmup &> $TDIR/ab-warmup.log
    fi

    #ab -p $APP_POST -T application/json -c $workload -n $((workload * WMULTIPLIER)) http://$IP:8080/ &> $TDIR/ab-init.log
    ab -p $APP_POST -T application/json -c $workload -n $((workload * WMULTIPLIER)) http://$IP:8080/ &> $TDIR/ab.log
}

function test {
    for i in $(seq 1 $workload)
    do
        pretime
        curl -s -X POST $IP:8080 -H 'Content-Type: application/json' -d $(cat $APP_POST)
        postime
    done
}

function run {
    # Setting up environment.
    if [ "$backend" == "svm" ]; then
        IP=127.0.0.1
        start_svm &> $TDIR/lambda.log &
    elif [ "$backend" == "container" ]; then
        IP=127.0.0.1
        start_gv_container &> $TDIR/lambda.log &
    elif [ "$backend" == "vm" ]; then
        # Note: ip is already set when loading shared.sh
        start_gv_vm &> $TDIR/lambda.log &
    fi

    # Let the lambda start.
    wait_port $IP 8080

    # Get PID of lambda.
    if [ "$backend" == "svm" ]; then
        PID=$(cat $TDIR/lambda.pid)
    elif [ "$backend" == "container" ]; then
        PID=$(docker inspect --format '{{ .State.Pid }}' bcontainer)
    elif [ "$backend" == "vm" ]; then
        PID=$(cat $TDIR/lambda.pid)
    fi

    # Write lambda pid to file.
    echo -n "$PID" > $TDIR/lambda.pid

    # Log Resources (memory and CPU)
    log_resources $PID $TDIR &

    # Prepares the local resources (cgroups, core pinning, turbo boost).
    prepare_resources

    # Load function into runtime.
    $app

    # Run test/benchmark.
    $mode 2>&1 | tee $TDIR/app.log

    # Teardown the lambda.
    if [ "$backend" == "svm" ]; then
        stop_svm
    elif [ "$backend" == "container" ]; then
        stop_container
    elif [ "$backend" == "vm" ]; then
        stop_vm
    fi
    wait

    # Teardown local resource changes (delete cgroups, enable turbo boost).
    teardown_resources
}

# Setting a sandbox if not already set.
if [ -z "$SANDBOX" ]
then
    if [[ $app == *"_java_"* ]]; then
        export SANDBOX=isolate
    else
        export SANDBOX=context
    fi
fi

echo "Running environment=$backend; sandbox=$SANDBOX; app=$app; mode=$mode; workload=$workload; cpu=$VM_CPU; mem=$VM_MEM"
echo "Logs available at $TDIR..."

# Writing post file to disk
APP_POST=$TDIR/payload.post

# Preparing working directory
rm -r $TDIR/ &> /dev/null
mkdir $TDIR &> /dev/null

# Preparing the directory path where results will be placed.
if [ -z "$EXPERIMENT" ]
then
    results_prefix=$BENCHMARKS_HOME/results/benchmark
else
    results_prefix=$BENCHMARKS_HOME/results/experiment/$EXPERIMENT
fi

for iter in $(seq 1 $ITERATIONS)
do
    # Run...
    run
    # Preparing results directory
    if [ ! -z "$SNAPSHOT" ]
    then
        results_dir=$results_prefix/$APP_LANG/$APP_NAME-$backend-snapshot-$SANDBOX-$mode-$workload-$VM_CPU-$VM_MEM/$iter
    else
        results_dir=$results_prefix/$APP_LANG/$APP_NAME-$backend-$SANDBOX-$mode-$workload-$VM_CPU-$VM_MEM/$iter
    fi
    mkdir -p $results_dir &> /dev/null
    cp $TDIR/{*.log,*.rss,*.cpu} $results_dir &> /dev/null
    echo "Saved logs (iteration $iter): $results_dir/lambda.log"
done

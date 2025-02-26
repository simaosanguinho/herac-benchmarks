#!/bin/bash

function DIR {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

source $(DIR)/shared.sh
source $(DIR)/benchmarks.sh

if [ "$#" -ne 4 ]; then
    echo "Syntax: <backend> <app> <mode> <# of tests or concurrency level>"
    echo "Available backends: graalhost (native), container (Docker container)."
    echo "Available apps: gh_java_http"
    echo "Available modes: test benchmark. Test will perform a number of requests. Benchmark will use apache bench with the desired concurrency level."
    echo "Example: benchmark-graalhost.sh graalhost gh_java_http test 1"
    echo "Available environment variables: "
    echo "- ITERATIONS=<number> - number of iterations the workload is ran. Defaults to 1;"
    echo "- WMULTIPLIER=<number> - workload multiplier to scale up or down the length of the benchmark (only used in benchmark mode). Defaults to 256;"
    echo "- CGROUP=<name> - name of the cgroup to use. A directory with that name will be created under /sys/fs/cgroup. Defaults to empty which leads to no CGROUP being used;"
    echo "- CGROUP_CPU_QUOTA=<number> - CPU quota for a 100ms period. A quota 100000 means using a full core. Only used if CGROUP is set. Defaults to 100000 (full core)."
    echo "- PIN_CORE=<boolean> - if true, will pin the process to core 0. Defaults to false;"
    echo "- DISABLE_TURBO=<boolean> - if true, will disable turbo boost. Defaults to false;"
    echo "- EXPERIMENT=<tag> - if set, will copy result logs into a dedicated experiment directory. Defaults to unset;"
    echo "- LOGS_VERBOSE=<tag> - if set, will probe various graalhost logs into the logs directory. Requires sudo. Defaults to unset;"
    exit 1
else
    backend=$1
    app=$2
    mode=$3
    workload=$4
fi

LDIR=$WORK_DIR/logs

function probe_logs {
    if [ -n "$LOGS_VERBOSE" ]; then
        tag=$1
        log_dir=$LDIR/$tag
        pid=$(cat $TDIR/graalhost.pid)

        mkdir -p $log_dir
        netcat -U $TDIR/maps.sock > $log_dir/maps.log
        netcat -U $TDIR/heap.sock > $log_dir/heap.log
        netcat -U $TDIR/files.sock > $log_dir/files.log
        netcat -U $TDIR/threads.sock > $log_dir/threads.log
        netcat -U $TDIR/isolates.sock > $log_dir/isolates.log

        sudo cat /proc/$pid/maps > $log_dir/procmaps.log
        sudo cat /proc/$pid/smaps > $log_dir/procsmaps.log
    fi
}

function benchmark {
    if [ -z "$WMULTIPLIER" ]; then
        WMULTIPLIER=256
    fi

    printf "Running ab (check $TDIR/ab.log).\n"
    ab -c $workload -n $((workload * WMULTIPLIER)) http://$IP:$APP_PORT/$APP_PATH &> $TDIR/ab.log
}

function test {
    printf "Sending $workload requests:\n"
    for i in $(seq 1 $workload)
    do
        request $IP:$APP_PORT/$APP_PATH
    done
}

function run {
    # Setting up environment.
    echo "Waiting for $backend..." | tee $TDIR/backend.log
    sbs=$(date +%s%N)
    IP=127.0.0.1
    if [ "$backend" == "graalhost" ]; then
        start_graalhost &>> $TDIR/backend.log &
    elif [ "$backend" == "container" ]; then
        start_graalhost_container &>> $TDIR/backend.log &
    fi

    # Let the graalhost start.
    wait_port $IP $GRAALHOST_PORT

    # Measure how long it took to accept connections.
    sbt=$((($(date +%s%N) - $sbs)/1000))
    echo "Waiting for $backend... done (took $sbt us)." | tee -a $TDIR/backend.log

    # Get PID of graalhost.
    # Note: wait until graalhost.pid is filled.
    while [ ! -f $TDIR/graalhost.pid ]; do sleep 0.01; done
    PID=$(cat $TDIR/graalhost.pid)

    # Log Resources (memory and CPU)
    log_resources $PID $TDIR &

    # Prepares the local resources (cgroups, core pinning, turbo boost).
    prepare_resources

    # Load function into runtime and prepare payload.
    probe_logs "before-loading"
    if [ "$backend" == "container" ]; then
        # The container will have the "/benchmarks" directory mounted.
        BENCHMARKS_HOME=/benchmarks
    fi
    $app

    # Run test/benchmark.
    probe_logs "before-$mode"
    $mode 2>&1 | tee -a $TDIR/app.log
    probe_logs "after-$mode"

    # Allow time for final collection of resource utilization.
    sleep 1

    # Teardown the graalhost.
    if [ "$backend" == "graalhost" ]; then
        stop_graalhost &>> $TDIR/backend.log
    elif [ "$backend" == "container" ]; then
        stop_container &>> $TDIR/backend.log
    fi
    wait

    # Teardown local resource changes (delete cgroups, enable turbo boost).
    teardown_resources

    # Saving logs.
    backup_results
}

check_permissions

echo "$(tput bold)Running graalhost environment=$backend; app=$app; mode=$mode; workload=$workload:$(tput sgr0)"

# Preparing working directory
echo "Removing $TDIR, $ADIR, and $LDIR"
rm -rf $TDIR
rm -rf $ADIR
rm -rf $LDIR
mkdir -p $TDIR
mkdir -p $ADIR
mkdir -p $LDIR

for iter in $(seq 1 $ITERATIONS)
do
    run
done

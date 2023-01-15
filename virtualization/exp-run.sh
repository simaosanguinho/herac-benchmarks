#!/bin/bash

VBENCH_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
ITERS=10
JAR=$VBENCH_HOME/target/isolate-benchmark-0.1-jar-with-dependencies.jar
DOCKER_IMG=ghcr.io/graalvm/graalvm-ce:latest
RESULTS_DIR=$VBENCH_HOME/results

# IP of your local host.
TAP_GW=194.210.229.99

# A free IP in your network.
TAP_IP=194.210.229.100

# Mask of your local network.
TAP_MASK=255.255.254.0

if [[ -z "${ARGO_HOME}" ]]; then
        echo "ARGO_HOME is not defined. Existing..."
        exit 1
fi

if [[ -z "${GRAALVM_HOME}" ]]; then
        echo "GRAALVM_HOME is not defined. Existing..."
        exit 1
fi

function log_rss {
    while sudo kill -0 $1 &> /dev/null; do
        ps -q $1 -o rss= >> $2
        sleep .5
    done
}

function get_kernel {
    emulator=$1
    if [ "$emulator" = "firecracker" ]; then
        kernel=$ARGO_HOME/resources/hello-vmlinux.bin
    else
        kernel=$ARGO_HOME/resources/vmlinux-4.14.35-1902.6.6.1.el7.container
    fi
}

function vm_rss {
    emulator=$1
    get_kernel $emulator

    # Use a temporary directory.
    mkdir results/rss-$emulator &> /dev/null
    cd results/rss-$emulator
    rm rss-*.dat &> /dev/null

    $GRAALVM_HOME/bin/native-image -cp $JAR Sleep sleep-benchmark

    $ARGO_HOME/niuk/build_niuk.sh $GRAALVM_HOME $PWD/sleep-benchmark $PWD/sleep-benchmark.img

    sudo bash $ARGO_HOME/lambda-manager/src/scripts/create_taps.sh ttap $TAP_IP

    $ARGO_HOME/niuk/run_niuk.sh \
	--vmm $emulator \
	--disk $PWD/sleep-benchmark.img \
	--kernel $kernel \
	--memory 512 --cpu 1 \
	--ip $TAP_IP --gateway $TAP_GW --mask $TAP_MASK --tap ttap \
	--console &> emulator.log &

    # Note: give it time for the vm to be launched.
    sleep 1

    PID=$(ps -o pid --no-headers --ppid $(sudo cat lambda.pid))

    log_rss $PID rss-$emulator.dat &

    # Note: give it time to create samples.
    sleep 10

    sudo kill $PID
    wait

    sudo bash $ARGO_HOME/lambda-manager/src/scripts/remove_taps.sh ttap

    cd - &> /dev/null
}

function vm_latency {
    emulator=$1
    get_kernel $emulator

    # Use a temporary directory.
    mkdir results/latency-$emulator &> /dev/null
    cd results/latency-$emulator
    rm latency-*.dat &> /dev/null

    $GRAALVM_HOME/bin/native-image -cp $JAR Time2 time-benchmark

    $ARGO_HOME/niuk/build_niuk.sh $GRAALVM_HOME $PWD/time-benchmark $PWD/time-benchmark.img

    sudo bash $ARGO_HOME/lambda-manager/src/scripts/create_taps.sh ttap $TAP_IP

    for i in $(seq 1 $ITERS)
    do
        # Note: this sleep is necessary to allow the tap state to be propagated.
        sleep 1
        ts=$(($(date +%s%N)/1000000))

        $ARGO_HOME/niuk/run_niuk.sh \
            --vmm $emulator \
            --disk $PWD/time-benchmark.img \
            --kernel $kernel \
            --memory 512 --cpu 1 \
            --ip $TAP_IP --gateway $TAP_GW --mask $TAP_MASK --tap ttap \
            --console &> emulator.log &

        # Note: give the vm time to boot.
        sleep 1

        # Note: lambda.pid points the parent process of both firecracker and qemu.
        sudo kill $(ps -o pid --no-headers --ppid $(sudo cat lambda.pid))

        tf=$(cat emulator.log | grep "\[ms since epoch\]" | awk '{print $NF}' | tr -d '\t\n\r')
        echo $(($tf - $ts)) >> latency-$emulator.dat
    done
    sudo bash $ARGO_HOME/lambda-manager/src/scripts/remove_taps.sh ttap

    cd - &> /dev/null
}

function docker_rss_latency {
    rm -f $RESULTS_DIR/*-docker.dat
    docker run $DOCKER_IMG sleep 10 &> /dev/null &
    log_rss $! $RESULTS_DIR/rss-docker.dat &> /dev/null
    for i in $(seq 1 $ITERS)
    do
        ts=$(date +%s%N)
        tf=$(docker run --rm $DOCKER_IMG date +%s%N)
        tt=$((($tf - $ts) / 1000000))
        echo $tt >> $RESULTS_DIR/latency-docker.dat
    done
}

function hotspot_rss_latency {
    rm -f $RESULTS_DIR/*-hotspot.dat
    java -cp $JAR Sleep &
    log_rss $! $RESULTS_DIR/rss-hotspot.dat &> /dev/null
    for i in $(seq 1 $ITERS)
    do
        java -cp $JAR Time $(($(date +%s%N)/1000000)) >> $RESULTS_DIR/latency-hotspot.dat
    done
}

function node_rss_latency {
    rm -f $RESULTS_DIR/*-node.dat
    node -e 'new Promise((resolve) => setTimeout(resolve, 5000)).then();' &
    log_rss $! $RESULTS_DIR/rss-node.dat &> /dev/null
    for i in $(seq 1 $ITERS)
    do
        stime=$(($(date +%s%N)/1000000))
        ftime=$(node -e 'console.log(Date.now());')
        echo $((ftime - $stime)) >> $RESULTS_DIR/latency-node.dat
    done
}

function cpython_rss_latency {
    rm -f $RESULTS_DIR/*-python.dat
    python -c "import time; time.sleep(5)" &
    log_rss $! $RESULTS_DIR/rss-python.dat &> /dev/null
    for i in $(seq 1 $ITERS)
    do
        stime=$(($(date +%s%N)/1000000))
        ftime=$(python -c "import time; print(round(time.time() * 1000))")
        echo $((ftime - $stime)) >> $RESULTS_DIR/latency-python.dat
    done
}

function nativeimage_rss_latency {
    rm -f $RESULTS_DIR/*-ni.dat
    $GRAALVM_HOME/bin/native-image -cp $JAR Sleep target/sleep-benchmark
    target/sleep-benchmark &
    log_rss $! $RESULTS_DIR/rss-ni.dat &> /dev/null
    $GRAALVM_HOME/bin/native-image -cp $JAR Time target/time-benchmark
    for i in $(seq 1 $ITERS)
    do
        target/time-benchmark $(($(date +%s%N)/1000000)) >> $RESULTS_DIR/latency-ni.dat
    done
}

function isolate_latency {
    $GRAALVM_HOME/bin/native-image -H:+SpawnIsolates -cp $JAR IsolateBenchmark target/isolate-benchmark
    rm -f $RESULTS_DIR/*-isolate.dat
    echo "1048576" >> $RESULTS_DIR/rss-isolate.dat # Note, this value comes from isolate-scalability.
    $VBENCH_HOME/target/isolate-benchmark $ITERS >> $RESULTS_DIR/latency-isolate.dat
}

function gv_isolate_latency {
    # Building gv host
    cd gv-host
    ./build_script.sh
    cd - &> /dev/null
    # Building gv guest
    cd gv-guest
    ./build_script.sh
    cd - &> /dev/null
    # Call host and pass guest as an argument
    rm -f $RESULTS_DIR/*-gv-*.dat
    gv-host/build/graalvisorhost false $ITERS gv-guest/build/graalvisorguest.so GraalvisorGuestIsolateBenchmark >> $RESULTS_DIR/latency-gv-isolate.dat
    gv-host/build/graalvisorhost true  $ITERS gv-guest/build/graalvisorguest.so GraalvisorGuestIsolateBenchmark >> $RESULTS_DIR/latency-gv-fork.dat
}

mvn package
vm_rss firecracker
vm_latency firecracker
vm_rss qemu
vm_latency qemu
docker_rss_latency
isolate_latency
gv_isolate_latency
hotspot_rss_latency
nativeimage_rss_latency
node_rss_latency
cpython_rss_latency

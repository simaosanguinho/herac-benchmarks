#!/bin/bash

function DIR {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

BENCHMARKS_HOME=$(DIR)/..
tmpdir=/tmp/test-proxy

# Network setup for the test.
gateway=172.18.0.1
mask=255.255.0.0
smask=16
ip=172.18.0.2
tap=testtap
bridge=testbridge

# Preparing global paths.
if [ -z "${ARGO_HOME}" ]; then
    echo "ARGO_HOME is not defined. Existing..."
    exit 1
else
    CRUNTIME_HOME=$ARGO_HOME/lambda-manager/src/scripts/cruntime
    NIUK_HOME=$ARGO_HOME/niuk
    GRAALVISOR_HOME=$ARGO_HOME/graalvisor
    RES_HOME=$ARGO_HOME/resources
fi
if [ -z "${JAVA_HOME}" ]; then
        echo "JAVA_HOME is not defined. Existing..."
        exit 1
fi

# Default values.
if [ -z "${VM_MEM}" ]; then
    VM_MEM=2048
fi
if [ -z "${VM_CPU}" ]; then
    VM_CPU=1
fi
if [ -z "${VM_CPU}" ]; then
    VM_CPU=1
fi
if [ -z "${CGROUP_CPU_QUOTA}" ]; then
    CGROUP_CPU_QUOTA=100000
fi
if [ -z "${CGROUP_MEM}" ]; then
    CGROUP_MEM=2048
fi
if [ -z "${ITERATIONS}" ]; then
    ITERATIONS=1
fi

function wait_port {
    host=$1
    port=$2
    while ! nc -z $host $port; do echo "Waiting for $host:$port"; sleep 0.1; done
}

function pretime {
    ts=$(date +%s%N)
}

function postime {
    tt=$((($(date +%s%N) - $ts)/1000))
    printf "\nTime taken: $tt us\n"
}

function log_rss {
    PID=$1
    OFILE=$2
    sudo rm $OFILE &> /dev/null
        while sudo kill -0 $PID &> /dev/null; do
                ps -q $PID -o rss= >> $OFILE
                sleep .5
        done
}

function enable_turbo_boost {
    if [ -f "/sys/devices/system/cpu/intel_pstate/no_turbo" ]; then
        echo "0" | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo
    echo "Enabled turbo boost."
    else
    echo "Warning: failed to enable turbo boost."
    fi
}

function disable_turbo_boost {
    if [ -f "/sys/devices/system/cpu/intel_pstate/no_turbo" ]; then
        echo "1" | sudo tee /sys/devices/system/cpu/intel_pstate/no_turbo
    echo "Disabled turbo boost."
    else
    echo "Warning: failed to disable turbo boost."
    fi
}

function pin_core {
    sudo taskset -cp 0 $PID
    echo "Pinned process $PID to core 0."
}

function create_cgroup {
    # TODO - also set a limit for memory based on CGROUP_MEM.
    period=100000
    if [ -d "/sys/fs/cgroup/unified" ]; then
        sudo mkdir /sys/fs/cgroup/cpu/$CGROUP
        echo "$period"            | sudo tee -a /sys/fs/cgroup/cpu/$CGROUP/cpu.cfs_period_us
        echo "$CGROUP_CPU_QUOTA"  | sudo tee -a /sys/fs/cgroup/cpu/$CGROUP/cpu.cfs_quota_us
        echo $PID                 | sudo tee -a /sys/fs/cgroup/cpu/$CGROUP/cgroup.procs
    else
        sudo mkdir /sys/fs/cgroup/$CGROUP
        echo "$CGROUP_CPU_QUOTA $period" | sudo tee -a /sys/fs/cgroup/$CGROUP/cpu.max
        echo $PID                        | sudo tee -a /sys/fs/cgroup/$CGROUP/cgroup.procs
    fi
    echo "Added process $PID to cgroup $CGROUP with a quota of $CGROUP_CPU_QUOTA out of $period."
}

function destroy_cgroup {
    if [ -d "/sys/fs/cgroup/unified" ]; then
        sudo rmdir /sys/fs/cgroup/cpu/$CGROUP
    else
        sudo rmdir /sys/fs/cgroup/$CGROUP
    fi
}

function prepare_resources {
    if [ ! -z "$CGROUP" ]
    then
        create_cgroup &>> $tmpdir/resources.log
    fi
    if [ "$PIN_CORE" = "true" ]
    then
        pin_core &>> $tmpdir/resources.log
    fi
    if [ "$DISABLE_TURBO" = "true" ]
    then
        disable_turbo_boost &>> $tmpdir/resources.log
    fi
}

function teardown_resources {
    if [ ! -z "$CGROUP" ]
    then
        destroy_cgroup &>> $tmpdir/resources.log
    fi
    if [ "$DISABLE_TURBO" = "true" ]
    then
        enable_turbo_boost &>> $tmpdir/resources.log
    fi
}

function create_tap {
    # Create bridge if not already created
    if [ ! -d "/sys/class/net/$bridge" ]; then
        defaultdevice=$(ip route get 8.8.8.8 | grep -Po '(?<=(dev ))(\S+)')
        sudo ip link add name $bridge type bridge
        sudo ip addr add $gateway/$smask brd + dev $bridge
        sudo ip link set dev $bridge up
        sudo iptables -A FORWARD -o $bridge -j ACCEPT
        sudo iptables -A FORWARD -i $bridge -j ACCEPT
        sudo iptables -t nat -A POSTROUTING -o $defaultdevice -j MASQUERADE
        sudo iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    fi
    sudo ip tuntap add dev $tap mode tap
    sudo brctl addif $bridge $tap
    sudo ip link set dev $tap up
}

function remove_tap {
    sudo ip link delete $tap
}

function start_niuk {
    create_tap
    if [ ! -z "$SNAPSHOT" ] && [ -f "$SNAPSHOT.snap" ]
    then
        restore_niuk \
            /tmp/testtap.socket \
            $SNAPSHOT.snap \
            $SNAPSHOT.mem \
            $SNAPSHOT.disk

    else
        cp $GRAALVISOR_HOME/build/native-image/polyglot-proxy.img $tmpdir
        cd $tmpdir
        proxy_args="lambda_timestamp=$(date +%s%N | cut -b1-13) lambda_port=8080 LD_LIBRARY_PATH=/lib:/lib64:/apps:/usr/local/lib JAVA_HOME=/jvm"
        sudo bash $NIUK_HOME/run_niuk.sh \
            --vmm firecracker \
            --disk $tmpdir/polyglot-proxy.img \
            --kernel $RES_HOME/hello-vmlinux.bin \
            --memory $VM_MEM \
            --cpu $VM_CPU \
            --ip $ip \
            --gateway $gateway \
            --mask $mask \
            --tap $tap \
            --console \
            $proxy_args
    fi
}

function start_container {
    docker run --rm --name=gcontainer --network host -e lambda_timestamp="$(date +%s%N | cut -b1-13)" -e lambda_port="8080" -e JAVA_HOME="/jvm" graalvisor:latest
}

function start_svm {
    cp $GRAALVISOR_HOME/build/native-image/polyglot-proxy $tmpdir/app
    cd $tmpdir
    export lambda_timestamp="$(date +%s%N | cut -b1-13)"
    export lambda_port="8080"
    #sudo perf stat -e cache-misses,context-switches,branch-misses,page-faults ./app
    #strace -o $tmpdir/strace.log -f ./app
    #strace -f ./app
    ./app
}

function snapshot_niuk {
    vm_socket=$1
    snapshot_file=$2
    memory_file=$3
    disk_file=$4
    echo "Snapshotting niuk..."
    sudo curl -s --unix-socket $vm_socket -i \
        -X PATCH "http://localhost/vm" \
        -d "{ \"state\": \"Paused\" }"

    sudo curl -s --unix-socket $vm_socket -i \
        -X PUT "http://localhost/snapshot/create" \
        -d "{
            \"snapshot_type\": \"Full\",
            \"snapshot_path\": \"$snapshot_file\",
            \"mem_file_path\": \"$memory_file\"
        }"

    cp $tmpdir/polyglot-proxy.img $disk_file

    sudo curl -s --unix-socket $vm_socket -i \
        -X PATCH "http://localhost/vm" \
        -d "{ \"state\": \"Resumed\" }"
    echo "Snapshotting niuk... done!"
}

function restore_niuk {
    vm_socket=$1
    snapshot_file=$2
    memory_file=$3
    disk_file=$4
    echo "Restoring niuk..."
    sudo firecracker --api-sock $vm_socket &

    cp $disk_file $tmpdir/polyglot-proxy.img

    sudo curl -s --unix-socket $vm_socket -i \
        -X PUT "http://localhost/snapshot/load" \
        -d "{
            \"snapshot_path\": \"$snapshot_file\",
            \"mem_file_path\": \"$memory_file\",
            \"enable_diff_snapshots\": false,
            \"resume_vm\": true
        }"
    echo "Restoring niuk... done!"
}

function stop_niuk {
    if [ ! -z "$SNAPSHOT" ] && [ ! -f "$SNAPSHOT.snap" ]
    then
        snapshot_niuk \
            /tmp/testtap.socket \
            $SNAPSHOT.snap \
            $SNAPSHOT.mem \
            $SNAPSHOT.disk
    fi
    sudo kill $PID
    sudo rm /tmp/testtap.socket
    remove_tap
}

function stop_container {
    docker kill gcontainer
}

function stop_svm {
    sudo kill $PID
}


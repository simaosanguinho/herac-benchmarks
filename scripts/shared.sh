#!/bin/bash

function DIR {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

# Preparing global paths.
BENCHMARKS_HOME=$(DIR)/..
if [ -z "${ARGO_HOME}" ]; then
    echo "ARGO_HOME is not defined. Existing..."
    exit 1
fi
if [ -z "${JAVA_HOME}" ]; then
        echo "JAVA_HOME is not defined. Existing..."
        exit 1
fi
GRAALVISOR_HOME=$ARGO_HOME/graalvisor
RES_HOME=$ARGO_HOME/resources
TDIR=/tmp/test-proxy

# VM network setup for the test.
SOCKET=$TDIR/lambda.socket
GATEWAY=172.172.0.1
MASK=255.255.0.0
SMASK=16
IP=172.172.0.2
TAP=testtap
BRIDGE=testbridge

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
        create_cgroup &>> $TDIR/resources.log
    fi
    if [ "$PIN_CORE" = "true" ]
    then
        pin_core &>> $TDIR/resources.log
    fi
    if [ "$DISABLE_TURBO" = "true" ]
    then
        disable_turbo_boost &>> $TDIR/resources.log
    fi
}

function teardown_resources {
    if [ ! -z "$CGROUP" ]
    then
        destroy_cgroup &>> $TDIR/resources.log
    fi
    if [ "$DISABLE_TURBO" = "true" ]
    then
        enable_turbo_boost &>> $TDIR/resources.log
    fi
}

function create_tap {
    # Create bridge if not already created
    if [ ! -d "/sys/class/net/$BRIDGE" ]; then
        defaultdevice=$(ip route get 8.8.8.8 | grep -Po '(?<=(dev ))(\S+)')
        sudo ip link add name $BRIDGE type bridge
        sudo ip addr add $GATEWAY/$SMASK brd + dev $BRIDGE
        sudo ip link set dev $BRIDGE up
        sudo iptables -A FORWARD -o $BRIDGE -j ACCEPT
        sudo iptables -A FORWARD -i $BRIDGE -j ACCEPT
        sudo iptables -t nat -A POSTROUTING -o $defaultdevice -j MASQUERADE
        sudo iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    fi
    sudo ip tuntap add dev $TAP mode tap
    sudo brctl addif $BRIDGE $TAP
    sudo ip link set dev $TAP up
}

function remove_tap {
    sudo ip link delete $TAP
}

function start_vm {
    rootfs=$1
    kernel=$2
    kops=$3

    # Copy rootfs to tmp dir.
    cp $rootfs $TDIR/rootfs.img

    # Generate a mac for the vm.
    mac=`printf 'DE:AD:BE:EF:%02X:%02X\n' $((RANDOM%256)) $((RANDOM%256))`

    # Start firecracker.
    sudo firecracker --api-sock $SOCKET &
    sudo ps --ppid $! -o pid= > $TDIR/lambda.pid
    echo "$IP" > $TDIR/lambda.ip

    # Configures kernel its arguments.
    sudo curl -s --unix-socket $SOCKET -i \
        -X PUT "http://localhost/boot-source" \
        --data "{
            \"kernel_image_path\": \"${kernel}\",
            \"boot_args\": \"${kopts}\"
        }"

    # Configures the rootfs.
    sudo curl -s --unix-socket $SOCKET -i \
        -X PUT "http://localhost/drives/rootfs" \
        -d "{
            \"drive_id\": \"rootfs\",
            \"path_on_host\": \"${TDIR}/rootfs.img\",
            \"is_root_device\": true,
            \"is_read_only\": false
        }"

    # Confiures resources.
    sudo curl -s --unix-socket $SOCKET -i \
        -X PUT "http://localhost/machine-config" \
        --data "{
            \"vcpu_count\": ${VM_CPU},
            \"mem_size_mib\": ${VM_MEM},
            \"track_dirty_pages\": false
        }"

    # Confiures network.
    sudo curl -s --unix-socket $SOCKET -i \
        -X PUT 'http://localhost/network-interfaces/eth0' \
        -d "{
            \"iface_id\": \"eth0\",
            \"guest_mac\": \"${mac}\",
            \"host_dev_name\": \"${TAP}\"
        }"

    # Launches vm.
    sudo curl -s --unix-socket $SOCKET -i \
        -X PUT "http://localhost/actions" \
        -d "{
            \"action_type\": \"InstanceStart\"
        }"

    # What for the vm to terminate.
    wait
}

function start_gv_vm {
    create_tap
    if [ ! -z "$SNAPSHOT" ] && [ -f "$SNAPSHOT.snap" ]
    then
        restore_vm $SOCKET $SNAPSHOT.snap $SNAPSHOT.mem $SNAPSHOT.disk
    else
        gvargs="lambda_timestamp=$(date +%s%N | cut -b1-13) lambda_port=8080 LD_LIBRARY_PATH=/lib:/lib64:/apps:/usr/local/lib JAVA_HOME=/jvm"
        # Kernel opts example: https://github.com/firecracker-microvm/firecracker-demo/blob/main/start-firecracker.sh
        kopts="init=/init quiet rw tsc=reliable ipv6.disable=1 ip=$IP::$GATEWAY:$MASK::eth0:none::: nomodule random.trust_cpu=on console=ttyS0 reboot=k panic=1 pci=off $gvargs"

        start_vm $ARGO_HOME/images/graalvisor/graalvisor.img $RES_HOME/hello-vmlinux.bin $kopts
    fi
}

function start_ow_vm {
    create_tap
    kopts="init=/init quiet rw tsc=reliable ipv6.disable=1 ip=$IP::$GATEWAY:$MASK::eth0:none::: nomodule random.trust_cpu=on console=ttyS0 reboot=k panic=1 pci=off"
    start_vm $ARGO_HOME/images/$APP_LANG-openwhisk/$APP_LANG-openwhisk.img $RES_HOME/hello-vmlinux.bin $kopts
}

function start_gv_container {
    docker run --rm --name=bcontainer --network host -e lambda_timestamp="$(date +%s%N | cut -b1-13)" -e lambda_port="8080" -e JAVA_HOME="/jvm" graalvisor:latest
}

function start_ow_container {
    docker run --rm --name=bcontainer --network host $IMG
}

function start_svm {
    cp $GRAALVISOR_HOME/build/native-image/polyglot-proxy $TDIR/app
    cd $TDIR
    export lambda_timestamp="$(date +%s%N | cut -b1-13)"
    export lambda_port="8080"
    #sudo perf stat -e cache-misses,context-switches,branch-misses,page-faults ./app
    #strace -o $TDIR/strace.log -f ./app
    #strace -f ./app
    ./app &
    echo -n "$!" > "$TDIR/lambda.pid"
    wait
}

function snapshot_vm {
    vm_socket=$1
    snapshot_file=$2
    memory_file=$3
    disk_file=$4
    echo "Snapshotting vm..."
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

    cp $TDIR/rootfs.img $disk_file

    sudo curl -s --unix-socket $vm_socket -i \
        -X PATCH "http://localhost/vm" \
        -d "{ \"state\": \"Resumed\" }"
    echo "Snapshotting vm... done!"
}

function restore_vm {
    vm_socket=$1
    snapshot_file=$2
    memory_file=$3
    disk_file=$4
    echo "Restoring vm..."
    sudo firecracker --api-sock $vm_socket &

    cp $disk_file $TDIR/rootfs.img

    sudo curl -s --unix-socket $vm_socket -i \
        -X PUT "http://localhost/snapshot/load" \
        -d "{
            \"snapshot_path\": \"$snapshot_file\",
            \"mem_file_path\": \"$memory_file\",
            \"enable_diff_snapshots\": false,
            \"resume_vm\": true
        }"
    echo "Restoring vm... done!"
}

function stop_vm {
    if [ ! -z "$SNAPSHOT" ] && [ ! -f "$SNAPSHOT.snap" ]
    then
        snapshot_vm $SOCKET $SNAPSHOT.snap $SNAPSHOT.mem $SNAPSHOT.disk
    fi
    sudo kill $(cat $TDIR/lambda.pid)
    remove_tap
}

function stop_container {
    docker kill bcontainer
}

function stop_svm {
    sudo kill $(cat $TDIR/lambda.pid)
}


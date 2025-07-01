#!/bin/bash

function DIR {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

# Import global definitions.
source $(DIR)/globals.sh

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

function check_permissions {
    if [ "$EUID" -ne 0 ]; then
        echo "Warning: running as non-root. Features such as cgroups, core pinning, disabling turbo, and others may fail."
    fi
}

function wait_port {
    host=$1
    port=$2
    while ! nc -z $host $port; do sleep 0.01; done
}

function backup_results {
    if [ -z "$EXPERIMENT" ]
    then
        results_prefix=$BENCHMARKS_HOME/results/benchmark
    else
        results_prefix=$BENCHMARKS_HOME/results/experiment/$EXPERIMENT
    fi

    if [ ! -z "$SNAPSHOT" ]
    then
        snapshot="snap"
    else
        snapshot="cold"
    fi

    results_dir=$results_prefix/$APP_LANG/$APP_NAME-$backend-$snapshot-$SANDBOX-$mode-$workload-$VM_CPU-$VM_MEM/$iter

    mkdir -p $results_dir
    cp $TDIR/{*.log,*.rss,*.cpu} $results_dir
    echo "Saved logs (iteration $iter): $results_dir"
}

function request {
    URL=$1
    ts=$(date +%s%N)
    output=$(curl -s --connect-timeout 5 -X POST $URL -H 'Content-Type: application/json' -d @$RUN_POST)
    tt=$((($(date +%s%N) - $ts)/1000))
    printf "Req latency $tt us; Req output: $output\n"
}

function log_resources {
    PID=$1
    OFILE_CPU=$2/lambda.cpu
    OFILE_RSS=$2/lambda.rss

    rm $OFILE_CPU &> /dev/null
    rm $OFILE_RSS &> /dev/null
    while kill -0 $PID &> /dev/null; do
        top -bn 1 | grep "Cpu(s)" >> $OFILE_CPU
        # The idea for memory is that we traverse the entire pid subprocess tree
        # and memory memory utilization. We sum all individual memory and return.
        s_mem=0
        for p in $(pstree -p $PID | grep -o '([0-9]\+)' | grep -o '[0-9]\+')
        do
            p_mem=$(ps -q $p -o rss=)
            s_mem=$((s_mem + p_mem))
        done
        echo $s_mem >> $OFILE_RSS
        sleep .100
    done
}

function enable_turbo_boost {
    if [ -f "/sys/devices/system/cpu/intel_pstate/no_turbo" ]; then
        echo "0" | tee /sys/devices/system/cpu/intel_pstate/no_turbo
    echo "Enabled turbo boost."
    else
    echo "Warning: failed to enable turbo boost."
    fi
}

function disable_turbo_boost {
    if [ -f "/sys/devices/system/cpu/intel_pstate/no_turbo" ]; then
        echo "1" | tee /sys/devices/system/cpu/intel_pstate/no_turbo
    echo "Disabled turbo boost."
    else
    echo "Warning: failed to disable turbo boost."
    fi
}

function pin_core {
    taskset -cp 0 $PID
    echo "Pinned process $PID to core 0."
}

function create_cgroup {
    period=100000
    if [ -d "/sys/fs/cgroup/unified" ]; then
        mkdir /sys/fs/cgroup/cpu/$CGROUP
        echo "$period"            | tee -a /sys/fs/cgroup/cpu/$CGROUP/cpu.cfs_period_us
        echo "$CGROUP_CPU_QUOTA"  | tee -a /sys/fs/cgroup/cpu/$CGROUP/cpu.cfs_quota_us
        echo $PID                 | tee -a /sys/fs/cgroup/cpu/$CGROUP/cgroup.procs
    else
        mkdir /sys/fs/cgroup/$CGROUP
        echo "$CGROUP_CPU_QUOTA $period" | tee -a /sys/fs/cgroup/$CGROUP/cpu.max
        echo $PID                        | tee -a /sys/fs/cgroup/$CGROUP/cgroup.procs
    fi
    echo "Added process $PID to cgroup $CGROUP with a quota of $CGROUP_CPU_QUOTA out of $period."
}

function destroy_cgroup {
    if [ -d "/sys/fs/cgroup/unified" ]; then
        rmdir /sys/fs/cgroup/cpu/$CGROUP
    else
        rmdir /sys/fs/cgroup/$CGROUP
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
        ip link add name $BRIDGE type bridge
        ip addr add $GATEWAY/$SMASK brd + dev $BRIDGE
        ip link set dev $BRIDGE up
        iptables -A FORWARD -o $BRIDGE -j ACCEPT
        iptables -A FORWARD -i $BRIDGE -j ACCEPT
        iptables -t nat -A POSTROUTING -o $defaultdevice -j MASQUERADE
        iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    fi
    ip tuntap add dev $TAP mode tap
    brctl addif $BRIDGE $TAP
    ip link set dev $TAP up
}

function remove_tap {
    ip link delete $TAP
}

function start_vm {
    rootfs=$1
    kernel=$2
    kops=$3

    # Copy rootfs to tmp work dir.
    cp $rootfs $TDIR/rootfs.img

    # Generate a mac for the vm.
    mac=`printf 'DE:AD:BE:EF:%02X:%02X\n' $((RANDOM%256)) $((RANDOM%256))`

    # Start firecracker.
    firecracker --no-seccomp --api-sock $SOCKET &> $TDIR/lambda.log &
    echo $! > $TDIR/lambda.pid

    # Set save vm ip.
    echo "$IP" > $TDIR/lambda.ip

    # Configures kernel its arguments.
    curl -s --unix-socket $SOCKET -i \
        -X PUT "http://localhost/boot-source" \
        --data "{
            \"kernel_image_path\": \"${kernel}\",
            \"boot_args\": \"${kopts}\"
        }"

    # Configures the rootfs.
    curl -s --unix-socket $SOCKET -i \
        -X PUT "http://localhost/drives/rootfs" \
        -d "{
            \"drive_id\": \"rootfs\",
            \"path_on_host\": \"${TDIR}/rootfs.img\",
            \"is_root_device\": true,
            \"is_read_only\": false
        }"

    # Confiures resources.
    curl -s --unix-socket $SOCKET -i \
        -X PUT "http://localhost/machine-config" \
        --data "{
            \"vcpu_count\": ${VM_CPU},
            \"mem_size_mib\": ${VM_MEM},
            \"track_dirty_pages\": false
        }"

    # Confiures network.
    curl -s --unix-socket $SOCKET -i \
        -X PUT 'http://localhost/network-interfaces/eth0' \
        -d "{
            \"iface_id\": \"eth0\",
            \"guest_mac\": \"${mac}\",
            \"host_dev_name\": \"${TAP}\"
        }"

    # Launches vm.
    curl -s --unix-socket $SOCKET -i \
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
        gvargs="lambda_timestamp=$(date +%s%N | cut -b1-13) lambda_port=$GRAALVISOR_PORT LD_LIBRARY_PATH=/lib:/lib64:/apps:/usr/local/lib JAVA_HOME=/jvm"
        # Kernel opts example: https://github.com/firecracker-microvm/firecracker-demo/blob/main/start-firecracker.sh
        kopts="init=/init quiet rw tsc=reliable ipv6.disable=1 ip=$IP::$GATEWAY:$MASK::eth0:none::: nomodule random.trust_cpu=on console=ttyS0 reboot=k panic=1 pci=off $gvargs"
        start_vm $ARGO_HOME/images/graalvisor/graalvisor.img $RESOURCES_HOME/hello-vmlinux.bin $kopts
    fi
}

function start_ow_vm {
    create_tap
    kopts="init=/init quiet rw tsc=reliable ipv6.disable=1 ip=$IP::$GATEWAY:$MASK::eth0:none::: nomodule random.trust_cpu=on console=ttyS0 reboot=k panic=1 pci=off"
    start_vm $ARGO_HOME/images/$APP_LANG-openwhisk/$APP_LANG-openwhisk.img $RESOURCES_HOME/hello-vmlinux.bin $kopts
}

function start_gv_container {
    docker run --privileged --rm --name=bcontainer --memory "${VM_MEM}m" --network host -v $ADIR:/tmp/apps -e lambda_timestamp="$(date +%s%N | cut -b1-13)" -e lambda_port="$GRAALVISOR_PORT" -e JAVA_HOME="/jvm" graalvisor:latest &> $TDIR/lambda.log
}

function start_ow_container {
    docker run --rm --name=bcontainer --memory "${VM_MEM}m" --network host $IMG &> $TDIR/lambda.log
}

function start_kn_container {
    docker run --rm --name=bcontainer --memory "${VM_MEM}m" -p $KNATIVE_PORT:8080 $IMG &> $TDIR/lambda.log
}

function start_svm {
    cp $GRAALVISOR_HOME/build/native-image/polyglot-proxy $TDIR/graalvisor
    cd $TDIR
    if [ ! -z "$SNAPSHOT" ] && [ -f "$SNAPSHOT/inventory.img" ]
    then
        echo "[$(date +%s%N) ns] Restoring svm..."
        criu restore -v -d -j -o $TDIR/restore.log --pidfile $TDIR/lambda.pid -D $SNAPSHOT
        echo "[$(date +%s%N) ns] Restoring svm... done!"
        #lat_secs=$(cat $TDIR/restore.log | grep "Writing stats" | awk '{print $1}' | tr -d "()")
        #lat_us=$(echo "$lat_secs * 1000000" | bc)
        #echo "Restoring svm... done (took $lat_us us) !"
    else
        export lambda_timestamp="$(date +%s%N | cut -b1-13)"
        export lambda_port="$GRAALVISOR_PORT"
        export app_dir="$ADIR"
        bash $GRAALVISOR_HOME/graalvisor $TDIR/lambda.pid &> $TDIR/lambda.log
    fi
}

function start_graalhost {
    $GRAALHOST_HOME/scripts/build-env-rc.sh \
        ${GRAALHOST_HOME}/graalhost/graalhost \
            --port=$GRAALHOST_PORT \
            --seccomp 2 \
            --hub \
            --webserver \
            --log_to=file \
            --musl_path=${GRAALHOST_HOME}/graalhost/libc.so \
            --ephemeral_dir=$TDIR \
            --write_pid=$TDIR/graalhost.pid &> $TDIR/graalhost.log
}

function start_graalhost_container {
    ephemeral_dir=/tmp/ephemeral

    docker run --rm --name=bcontainer \
        --user $(id -u):$(id -g) \
        --pid host \
        -p $GRAALHOST_PORT:$GRAALHOST_PORT \
        -p 9001:9001 \
        -v "$GRAALHOST_HOME":/graalos \
        -v "$TDIR":$ephemeral_dir \
        -v "$BENCHMARKS_HOME":/benchmarks \
        graalos-image \
        /graalos/scripts/build-env-rc.sh \
            /graalos/graalhost/graalhost \
                --port=$GRAALHOST_PORT \
                --seccomp 2 \
                --hub \
                --webserver \
                --log_to=file \
                --musl_path=/graalos/graalhost/libc.so \
                --ephemeral_dir=$ephemeral_dir \
                --write_pid=$ephemeral_dir/graalhost.pid &> $TDIR/graalhost.log
}

function snapshot_vm {
    vm_socket=$1
    snapshot_file=$2
    memory_file=$3
    disk_file=$4

    echo "[$(date +%s%N) ns] Snapshotting vm..."
    curl -s --unix-socket $vm_socket -i \
        -X PATCH "http://localhost/vm" \
        -d "{ \"state\": \"Paused\" }"

    curl -s --unix-socket $vm_socket -i \
        -X PUT "http://localhost/snapshot/create" \
        -d "{
            \"snapshot_type\": \"Full\",
            \"snapshot_path\": \"$snapshot_file\",
            \"mem_file_path\": \"$memory_file\"
        }"

    echo "[$(date +%s%N) ns] Copying rootfs..."
    cp $TDIR/rootfs.img $disk_file
    echo "[$(date +%s%N) ns] Copying rootfs... done!"

    curl -s --unix-socket $vm_socket -i \
        -X PATCH "http://localhost/vm" \
        -d "{ \"state\": \"Resumed\" }"
    echo "[$(date +%s%N) ns] Snapshotting vm... done!"
}

function restore_vm {
    vm_socket=$1
    snapshot_file=$2
    memory_file=$3
    disk_file=$4

    echo "[$(date +%s%N) ns] Restoring vm..."
    echo "[$(date +%s%N) ns] Copying rootfs..."
    cp $disk_file $TDIR/rootfs.img
    echo "[$(date +%s%N) ns] Copying rootfs... done!"

    firecracker --no-seccomp --api-sock $vm_socket &> $TDIR/lambda.log &
    echo $! > $TDIR/lambda.pid
    echo "$IP" > $TDIR/lambda.ip

    # Wait for vm socket to exist.
    while [ ! -S $vm_socket ]; do sleep 0.005; done

    curl -s --unix-socket $vm_socket -i \
        -X PUT "http://localhost/snapshot/load" \
        -d "{
            \"snapshot_path\": \"$snapshot_file\",
            \"mem_file_path\": \"$memory_file\",
            \"enable_diff_snapshots\": false,
            \"resume_vm\": true
        }"
    echo "[$(date +%s%N) ns] Restoring vm... done!"
}

function stop_vm {
    if [ ! -z "$SNAPSHOT" ] && [ ! -f "$SNAPSHOT.snap" ]
    then
        snapshot_vm $SOCKET $SNAPSHOT.snap $SNAPSHOT.mem $SNAPSHOT.disk
    fi
    kill $(cat $TDIR/lambda.pid)
    rm -f $SOCKET
    rm -f $TDIR/lambda.pid
    remove_tap
}

function stop_container {
    docker kill bcontainer
    rm -f $TDIR/lambda.pid
}

function stop_svm {
    if [ ! -z "$SNAPSHOT" ] && [ ! -f "$SNAPSHOT/inventory.img" ]
    then
        mkdir -p $SNAPSHOT
        criu dump -v -j -t $(cat $TDIR/lambda.pid) -o $TDIR/dump.log -D $SNAPSHOT
    else
        kill $(cat $TDIR/lambda.pid)
    fi
    rm -f $TDIR/lambda.pid
}

function stop_graalhost {
    kill $(cat $TDIR/graalhost.pid)

}

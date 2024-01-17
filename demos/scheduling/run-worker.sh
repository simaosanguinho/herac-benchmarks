#!/bin/bash

function DIR {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

function setup_cgroup {
    CPU_PERIOD=100000
    CPU_QUOTA=25000
    WORKER_ID=$1
    WORKER_PID=$2
    if [ -d "/sys/fs/cgroup/unified" ]; then
        sudo mkdir /sys/fs/cgroup/cpu/$WORKER_ID
        sudo echo "$CPU_PERIOD" >> /sys/fs/cgroup/cpu/$WORKER_ID/cpu.cfs_period_us
        sudo echo "$CPU_QUOTA"  >> /sys/fs/cgroup/cpu/$WORKER_ID/cpu.cfs_quota_us
        sudo echo $WORKER_PID   >> /sys/fs/cgroup/cpu/$WORKER_ID/cgroup.procs
    else
        sudo mkdir /sys/fs/cgroup/$WORKER_ID
        sudo echo "$CPU_QUOTA $CPU_PERIOD" >> /sys/fs/cgroup/$WORKER_ID/cpu.max
        sudo echo $WORKER_PID              >> /sys/fs/cgroup/$WORKER_ID/cgroup.procs
    fi
}

function setup_chroot {
    JAIL=$1
    mkdir $JAIL/{proc,bin,usr,lib,lib64,graalvisor}
    mount --bind -o ro /proc                 $JAIL/proc
    mount --bind -o ro /bin                  $JAIL/bin
    mount --bind -o ro /usr                  $JAIL/usr
    mount --bind -o ro /lib                  $JAIL/lib
    mount --bind -o ro /lib64                $JAIL/lib64
    mount --bind -o ro $ARGO_HOME/graalvisor $JAIL/graalvisor


}

JAIL=$(DIR)/worker/
mkdir $JAIL &> /dev/null

# Create chroot.
#setup_chroot $JAIL

# Launch worker.
export lambda_port=8080
#chroot $JAIL /graalvisor/build/native-image/polyglot-proxy &> $JAIL.log &
$ARGO_HOME/graalvisor/build/native-image/polyglot-proxy &> $JAIL/worker.log &

# Save pid.
echo $! > $JAIL/worker.pid

# Collect scheduling events
sudo perf sched record -p $(cat $JAIL/worker.pid) --output $JAIL/worker.perf &

# Setup cgroup.
#setup_cgroup $WORKER_ID $(cat $JAIL.pid)

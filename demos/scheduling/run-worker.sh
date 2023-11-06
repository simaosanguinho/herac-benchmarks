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

if [ -z "$1" ]
then
    echo "No worker id supplied."
    exit 1
else
    WORKER_ID=$1
fi

if [ -z "$2" ]
then
    echo "No worker port supplied."
    exit 1
else
    WORKER_PORT=$2
fi

JAIL=$(DIR)/workers/$WORKER_ID

# Create chroot.
mkdir -p $JAIL/{proc,bin,usr,lib,lib64,graalvisor}
mount --bind -o ro /proc                 $JAIL/proc
mount --bind -o ro /bin                  $JAIL/bin
mount --bind -o ro /usr                  $JAIL/usr
mount --bind -o ro /lib                  $JAIL/lib
mount --bind -o ro /lib64                $JAIL/lib64
mount --bind -o ro $ARGO_HOME/graalvisor $JAIL/graalvisor

# Launch worker.
export lambda_port=$WORKER_PORT
chroot $JAIL /graalvisor/build/native-image/polyglot-proxy &> $JAIL.log &

# Save pid.
echo $! > $JAIL.pid

# Setup cgroup.
setup_cgroup $WORKER_ID $(cat $JAIL.pid)

#!/bin/bash

function DIR {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

function destroy_cgroup {
    WORKER_ID=$1
    if [ -d "/sys/fs/cgroup/unified" ]; then
        sudo rmdir /sys/fs/cgroup/cpu/$WORKER_ID
    else
        sudo rmdir /sys/fs/cgroup/$WORKER_ID
    fi
}

function destroy_chroot {
    JAIL=$1
    umount $JAIL/proc
    umount $JAIL/bin
    umount $JAIL/usr
    umount $JAIL/lib
    umount $JAIL/lib64
    umount $JAIL/graalvisor
}

JAIL=$(DIR)/worker

# Kill worker.
kill $(cat $JAIL/worker.pid)

# Let the process terminate.
sleep 1

# Delete chroot.
#destroy_chroot $JAIL

# Delete cgroup.
#destroy_cgroup $WORKER_ID

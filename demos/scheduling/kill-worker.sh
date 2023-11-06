#!/bin/bash

function DIR {
    echo "$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
}

if [ -z "$1" ]
then
    echo "No argument supplied."
    exit 1
else
    WORKER_ID=$1
fi

JAIL=$(DIR)/workers/$WORKER_ID

# Kill worker.
kill $(cat $JAIL.pid)

# Let the process terminate.
sleep 1

# Delete chroot.
umount $JAIL/proc
umount $JAIL/bin
umount $JAIL/usr
umount $JAIL/lib
umount $JAIL/lib64
umount $JAIL/graalvisor

# Delete cgroup.
rmdir /sys/fs/cgroup/$WORKER_ID

#!/bin/bash

if [ -z "$1" ]; then
    echo "Please privide a directory path to use for the vm."
    exit 0
fi

VM_DIR=$1
VM_SOCKET=$VM_DIR/firecracker.socket

# Kill the process that has that file open.
kill $(fuser $VM_SOCKET  2>&1 | awk '{print $2}')

# Remove the file.
rm $VM_SOCKET

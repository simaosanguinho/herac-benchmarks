#!/bin/bash

if [ -z "$1" ]; then
    echo "Please privide a directory path to use for the vm."
    exit 0
fi

VM_DIR=$1
VM_SOCKET=$VM_DIR/firecracker.socket
VM_SNAP_FILE=$VM_DIR/snapshot_file
VM_SNAP_MEM=$VM_DIR/mem_file

curl --unix-socket $VM_SOCKET -i \
    -X PUT "http://localhost/snapshot/load" \
    -d "{
        \"snapshot_path\": \"$VM_SNAP_FILE\",
        \"mem_file_path\": \"$VM_SNAP_MEM\",
        \"enable_diff_snapshots\": false,
        \"resume_vm\": true
    }"

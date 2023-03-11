#!/bin/bash

if [ -z "$1" ]; then
    echo "Please privide a directory path to use for the vm."
    exit 0
fi

VM_DIR=$1
VM_SOCKET=$VM_DIR/firecracker.socket

mkdir -p $VM_DIR

firecracker --api-sock $VM_SOCKET

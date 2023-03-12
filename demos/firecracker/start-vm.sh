#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

if [ -z "$1" ]; then
    echo "Please a free IP 172.17.0.[2,255]. The IP will be used to create a firecracker directory and tap."
    exit 0
fi

VM_DIR=$DIR/$1
VM_SOCKET=$VM_DIR/firecracker.socket

mkdir -p $VM_DIR

firecracker --api-sock $VM_SOCKET

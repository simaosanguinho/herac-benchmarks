#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

if [ -z "$1" ]; then
    echo "Please use a free IP 172.18.[0,255].[2,255]. The IP will be used to create a firecracker directory and tap."
    exit 0
fi

HOST_NS_VETH_IP=$1
VM_VETH_HOST_NS=veth$HOST_NS_VETH_IP
VM_ID=$(echo $HOST_NS_VETH_IP | tr . -)

# Kill the process that has that file open.
kill $(ps aux | grep $VM_ID | grep jailer | awk '{print $2}')

# Remove vm tap in both namespaces. Then delete namespace.
sudo ip link delete $VM_VETH_HOST_NS
sudo ip netns delete fc0 

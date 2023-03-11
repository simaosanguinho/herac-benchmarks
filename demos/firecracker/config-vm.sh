#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

if [ -z "$1" ]; then
    echo "Please a free IP 172.16.0.[2,255]. The IP will be used to create a firecracker directory and tap."
    exit 0
fi

# IP to be used by the VM.
VM_IP=$1

# Directory where the socket and logs of the VM will be placed.
VM_DIR=$DIR/$VM_IP

# Socket that will be used to control the VM.
VM_SOCKET=$VM_DIR/firecracker.socket

# Tap that will be created on the host to communicate with the VM.
VM_TAP=tap$VM_IP

# Default network device used in the host (important to setup iptables).
HOST_DEV=$(ip route | grep default | awk '{print $5}')

# Default network device used in the VM.
VM_DEV=eth0

# MAC address generated for the VM.
VM_MAC=$(printf 'DE:AD:BE:EF:%02X:%02X\n' $((RANDOM%256)) $((RANDOM%256)))

# IP address of the host in the VM network (172.16.0.0/24).
VM_GW=172.16.0.1

# Network mask of the VM network (long version).
VM_MK_LONG=255.255.255.0

# Network mask of the VM network (short version).
VM_MK_SHORT=24

# Kernel image used in the VM.
KERNEL=$DIR/hello-vmlinux.bin

# Kernel arguments (including network configuration).
KERNEL_BOOT_ARGS="ro console=ttyS0 noapic reboot=k panic=1 pci=off nomodules random.trust_cpu=on ip=$VM_IP::$VM_GW:$VM_MK_LONG::$VM_DEV:off"

# Root filesystem to be used in the VM.
ROOTFS=$VM_DIR/rootfs.ext4
cp $DIR/hello-rootfs.ext4 $ROOTFS

# VM memory and core config (memory in MB and number of vcores).
VM_MEM=64
VM_CPU=1

# Create VM tap.
sudo ip tuntap add dev $VM_TAP mode tap user $USER

# Set IP and network mask to vm tap.
sudo ip addr add $VM_GW/$VM_MK_SHORT dev $VM_TAP

# Enable tap.
sudo ip link set $VM_TAP up

# Update iptables to forward from host default device to the vm tap.
sudo iptables -A FORWARD -i $VM_TAP -o $HOST_DEV -j ACCEPT

# Configures kernel its arguments.
curl --unix-socket $VM_SOCKET \
    -X PUT "http://localhost/boot-source" \
    --data "{
        \"kernel_image_path\": \"${KERNEL}\",
        \"boot_args\": \"${KERNEL_BOOT_ARGS}\"
    }"

# Configures the rootfs.
curl --unix-socket $VM_SOCKET -i \
    -X PUT "http://localhost/drives/rootfs" \
    -d "{
        \"drive_id\": \"rootfs\",
        \"path_on_host\": \"${ROOTFS}\",
        \"is_root_device\": true,
        \"is_read_only\": false
    }"

# Confiures resources.
curl --unix-socket $VM_SOCKET \
    -X PUT "http://localhost/machine-config" \
    --data "{
        \"vcpu_count\": ${VM_CPU},
        \"mem_size_mib\": ${VM_MEM},
        \"track_dirty_pages\": false,
        \"ht_enabled\": false
    }"

# Confiures network.
curl --unix-socket $VM_SOCKET -i \
    -X PUT 'http://localhost/network-interfaces/eth0' \
    -d "{
        \"iface_id\": \"${VM_DEV}\",
        \"guest_mac\": \"${VM_MAC}\",
        \"host_dev_name\": \"${VM_TAP}\"
    }"

# Launches vm.
curl --unix-socket $VM_SOCKET -i \
    -X PUT "http://localhost/actions" \
    -d "{
        \"action_type\": \"InstanceStart\"
    }"

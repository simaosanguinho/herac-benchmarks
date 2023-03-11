#!/bin/bash

# Machine config.
MEMORY=64
VCPU=1

# Network configuration
HOST_DEV=alpine-test
GUEST_DEV=eth0
GUEST_MAC=02:FC:00:00:00:05
GUEST_IP=172.17.0.42
GUEST_GW=172.17.0.1
GUEST_MK=255.255.255.0

KERNEL=$(pwd)/hello-vmlinux.bin
KERNEL_BOOT_ARGS="ro console=ttyS0 noapic reboot=k panic=1 pci=off nomodules random.trust_cpu=on ip=$GUEST_IP::$GUEST_GW:$GUEST_MK::$GUEST_DEV:off"
ROOTFS=$(pwd)/hello-rootfs.ext4

if [ -z "$1" ]; then
    echo "Please privide a directory path to use for the vm."
    exit 0
fi

VM_DIR=$1
VM_SOCKET=$VM_DIR/firecracker.socket

# Copy disk for vm.
cp $ROOTFS $VM_DIR/rootfs.ext4
ROOTFS=$VM_DIR/rootfs.ext4

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
        \"vcpu_count\": ${VCPU},
        \"mem_size_mib\": ${MEMORY},
        \"track_dirty_pages\": false,
        \"ht_enabled\": false
    }"

# Confiures network.
curl --unix-socket $VM_SOCKET -i \
    -X PUT 'http://localhost/network-interfaces/eth0' \
    -d "{
        \"iface_id\": \"${GUEST_DEV}\",
        \"guest_mac\": \"${GUEST_MAC}\",
        \"host_dev_name\": \"${HOST_DEV}\"
    }"

# Launches vm.
curl --unix-socket $VM_SOCKET -i \
    -X PUT "http://localhost/actions" \
    -d "{
        \"action_type\": \"InstanceStart\"
    }"

#!/bin/bash

# Inspired by: https://gruchalski.com/posts/2021-02-13-launching-alpine-linux-on-firecracker-like-a-boss/
# Inspired by: https://betterprogramming.pub/getting-started-with-firecracker-a88495d656d9

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

if [ -z "$1" ]; then
    echo "Please use a free IP 172.18.[0,255].[3,255]. The IP will be used to create a firecracker directory and tap."
    exit 0
fi

# IP and ID to be used by the VM.
HOST_NS_VETH_IP=$1 # 172.18.0.4
VM_NS_VETH_IP=172.18.0.2
VM_NS_TAP_IP=172.18.0.3
VM_ID=$(echo $HOST_NS_VETH_IP | tr . -)

# Directory where the socket and logs of the VM will be placed (the link is created to avoid long paths).
sudo ln -s $DIR/$HOST_NS_VETH_IP/firecracker-v1.1.0-x86_64/$VM_ID/root $DIR/$HOST_NS_VETH_IP/root
VM_DIR=$DIR/$HOST_NS_VETH_IP/root

# Socket that will be used to control the VM.
VM_SOCKET=$VM_DIR/firecracker.socket

# Tap that will be created on the host to communicate with the VM.
VM_TAP=tap$VM_NS_TAP_IP
VM_VETH_HOST_NS=veth$HOST_NS_VETH_IP
VM_VETH_VM_NS=veth$VM_NS_VETH_IP

# Default network device used in the VM.
VM_DEV=eth0

# MAC address generated for the VM.
VM_MAC=$(printf 'DE:AD:BE:EF:%02X:%02X\n' $((RANDOM%256)) $((RANDOM%256)))

# IP address of the host brige (172.18.0.0/16). Used as gateway for VM taps.
#VM_GW=172.18.0.1
#VM_GW=$HOST_NS_VETH_IP
VM_GW=$VM_NS_VETH_IP

# Host default device.
HOST_DEV=$(ip route get 8.8.8.8 | grep -Po '(?<=(dev ))(\S+)')

# Host bridge where the taps are connected.
HOST_BRIDGE=testbridge

# Network mask of the VM network (long version).
VM_MK_LONG=255.255.0.0

# Network mask of the VM network (shot version).
VM_MK_SHORT=16

# Kernel image used in the VM.
sudo cp $DIR/hello-vmlinux.bin $VM_DIR/
KERNEL=/hello-vmlinux.bin

# Kernel arguments (including network configuration).
KERNEL_BOOT_ARGS="ro console=ttyS0 noapic reboot=k panic=1 pci=off nomodules random.trust_cpu=on ip=$VM_NS_TAP_IP::$VM_GW:$VM_MK_LONG::$VM_DEV:off"

# Root filesystem to be used in the VM.
sudo cp $DIR/hello-rootfs.ext4 $VM_DIR/
ROOTFS=/hello-rootfs.ext4

# VM memory and core config (memory in MB and number of vcores).
VM_MEM=64
VM_CPU=1

# BEG
# Create VM tap in VM NS.
sudo ip netns exec fc0 ip tuntap add dev $VM_TAP mode tap
sudo ip netns exec fc0 ip addr add $VM_NS_TAP_IP/$VM_MK_SHORT dev $VM_TAP
sudo ip netns exec fc0 ip link set dev $VM_TAP up

# Create VM veth pair.
sudo ip netns exec fc0 ip link add $VM_VETH_HOST_NS type veth peer name $VM_VETH_VM_NS
sudo ip netns exec fc0 ip addr add $VM_NS_VETH_IP/$VM_MK_SHORT dev $VM_VETH_VM_NS
sudo ip netns exec fc0 ip link set dev $VM_VETH_VM_NS up

# Move one end to the host namespace.
sudo ip netns exec fc0 ip link set $VM_VETH_HOST_NS netns 1
sudo ip addr add $HOST_NS_VETH_IP/$VM_MK_SHORT dev $VM_VETH_HOST_NS
sudo ip link set dev $VM_VETH_HOST_NS up

# designate the outer end as default gateway for packets leaving the namespace
sudo ip netns exec fc0 ip route add default via $HOST_NS_VETH_IP dev $VM_VETH_VM_NS

# for packets that leave the namespace and have the source IP address of the
# original guest, rewrite the source address to clone address 192.168.0.3
#sudo ip netns exec fc0 iptables -t nat -A POSTROUTING -o $VM_VETH_VM_NS -s $VM_NS_TAP_IP -j SNAT --to $HOST_NS_VETH_IP

# do the reverse operation; rewrites the destination address of packets
# heading towards the clone address to 192.168.241.2
#sudo ip netns exec fc0 iptables -t nat -A PREROUTING -i $VM_VETH_VM_NS -d $HOST_NS_VETH_IP -j DNAT --to $VM_NS_TAP_IP

# (adds a route on the host for the clone address)
sudo ip route add $VM_NS_VETH_IP via $HOST_NS_VETH_IP
# END

# Creating a bridge if there is not one already.
if [ ! -d "/sys/class/net/$HOST_BRIDGE" ]; then
    sudo ip link add name $HOST_BRIDGE type bridge
    sudo ip addr add $VM_GW/$VM_MK_SHORT brd + dev $HOST_BRIDGE
    sudo ip link set dev $HOST_BRIDGE up
    sudo iptables -A FORWARD -o $HOST_BRIDGE -j ACCEPT
    sudo iptables -A FORWARD -i $HOST_BRIDGE -j ACCEPT
    sudo iptables -t nat -A POSTROUTING -o $HOST_DEV -j MASQUERADE
    sudo iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
fi

# Add tap to bridge.
sudo brctl addif $HOST_BRIDGE $VM_VETH_HOST_NS

# Configures kernel its arguments.
sudo curl --unix-socket $VM_SOCKET \
    -X PUT "http://localhost/boot-source" \
    --data "{
        \"kernel_image_path\": \"${KERNEL}\",
        \"boot_args\": \"${KERNEL_BOOT_ARGS}\"
    }"

# Configures the rootfs.
sudo curl --unix-socket $VM_SOCKET -i \
    -X PUT "http://localhost/drives/rootfs" \
    -d "{
        \"drive_id\": \"rootfs\",
        \"path_on_host\": \"${ROOTFS}\",
        \"is_root_device\": true,
        \"is_read_only\": false
    }"

# Confiures resources.
sudo curl --unix-socket $VM_SOCKET \
    -X PUT "http://localhost/machine-config" \
    --data "{
        \"vcpu_count\": ${VM_CPU},
        \"mem_size_mib\": ${VM_MEM},
        \"track_dirty_pages\": false
    }"


# Confiures network.
sudo curl --unix-socket $VM_SOCKET -i \
    -X PUT 'http://localhost/network-interfaces/eth0' \
    -d "{
        \"iface_id\": \"${VM_DEV}\",
        \"guest_mac\": \"${VM_MAC}\",
        \"host_dev_name\": \"${VM_TAP}\"
    }"

# Launches vm.
sudo curl --unix-socket $VM_SOCKET -i \
    -X PUT "http://localhost/actions" \
    -d "{
        \"action_type\": \"InstanceStart\"
    }"

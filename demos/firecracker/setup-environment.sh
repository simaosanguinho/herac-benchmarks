#!/bin/bash

echo "Checking if you have firecracker."
if [ ! -f release-v1.0.0-x86_64/firecracker-v1.0.0-x86_64 ];
then
    wget https://github.com/firecracker-microvm/firecracker/releases/download/v1.0.0/firecracker-v1.0.0-x86_64.tgz
    tar -vzxf firecracker-v1.0.0-x86_64.tgz
fi

echo "Checking if you have a linux kernel image."
if [ ! -f hello-vmlinux.bin ];
then
    curl -fsSL -o hello-vmlinux.bin https://s3.amazonaws.com/spec.ccfc.min/img/hello/kernel/hello-vmlinux.bin
fi

echo "Checking if you have a base rootfs."
if [ ! -f hello-rootfs.ext4 ];
then
    curl -fsSL -o hello-rootfs.ext4 https://s3.amazonaws.com/spec.ccfc.min/img/hello/fsfiles/hello-rootfs.ext4
fi

HOST_DEV=$(ip route | grep default | awk '{print $5}')
echo "Found $HOST_DEV as the outgoing network device."

echo "Enabling ipv4 forwarding."
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

echo "Adding iptables rules to allow forwarding."
sudo iptables -t nat -A POSTROUTING -o $HOST_DEV -j MASQUERADE
sudo iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT


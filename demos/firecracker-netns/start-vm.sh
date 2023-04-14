#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

if [ -z "$1" ]; then
    echo "Please use a free IP 172.18.[0,255].[2,255]. The IP will be used to create a firecracker directory and tap."
    exit 0
fi

CHROOT_DIR=$DIR/$1
VM_ID=$(echo $1 | tr . -)
mkdir -p $CHROOT_DIR/firecracker-v1.1.0-x86_64/$VM_ID/root/
touch    $CHROOT_DIR/firecracker-v1.1.0-x86_64/$VM_ID/root/firecracker.log

# create namespace
sudo ip netns add fc0 # TODO - variable

sudo "$DIR"/release-v1.1.0-x86_64/jailer-v1.1.0-x86_64 \
       --id $VM_ID \
       --exec-file "$DIR"/release-v1.1.0-x86_64/firecracker-v1.1.0-x86_64 \
       --uid 0 \
       --gid 0 \
       --netns /var/run/netns/fc0 \
       --chroot-base-dir $CHROOT_DIR \
       -- \
       --api-sock firecracker.socket \
       --log-path firecracker.log \
       --level Debug \
       --show-level \
       --show-log-origin

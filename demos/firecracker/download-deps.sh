#!/bin/bash

if [ ! -f release-v1.0.0-x86_64/firecracker-v1.0.0-x86_64 ];
then
    wget https://github.com/firecracker-microvm/firecracker/releases/download/v1.0.0/firecracker-v1.0.0-x86_64.tgz
    tar -vzxf firecracker-v1.0.0-x86_64.tgz
fi

if [ ! -f hello-vmlinux.bin ];
then
    curl -fsSL -o hello-vmlinux.bin https://s3.amazonaws.com/spec.ccfc.min/img/hello/kernel/hello-vmlinux.bin
fi

if [ ! -f hello-rootfs.ext4 ];
then
    curl -fsSL -o hello-rootfs.ext4 https://s3.amazonaws.com/spec.ccfc.min/img/hello/fsfiles/hello-rootfs.ext4
fi

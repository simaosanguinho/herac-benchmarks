#!/bin/bash

echo 4194304 > /proc/sys/kernel/threads-max
echo 4194304 > /proc/sys/kernel/pid_max
echo 4194304 > /proc/sys/vm/max_map_count
echo 4194304 > /sys/fs/cgroup/user.slice/user-1000.slice/pids.max

#echo "rbruno soft nproc 4194304" > /etc/security/limits.conf
#echo "rbruno hard nproc 4194304" > /etc/security/limits.conf

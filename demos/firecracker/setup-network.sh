#!/bin/bash

set -eu
sudo apt-get install bridge-utils -y
# create and configure a tap device
# to launch firecracker VMM on the docker0 bridge
TAP_DEV=alpine-test
CONTAINER_IP=172.17.0.42
GATEWAY_IP=172.17.0.1
DOCKER_MASK_LONG=255.255.255.0
sudo ip tuntap add dev "$TAP_DEV" mode tap
sudo brctl addif docker0 $TAP_DEV
sudo ip link set dev "$TAP_DEV" up
# as Julia Evans, I also need to figure out the meaning of this:
sudo sysctl -w net.ipv4.conf.${TAP_DEV}.proxy_arp=1 > /dev/null
sudo sysctl -w net.ipv6.conf.${TAP_DEV}.disable_ipv6=1 > /dev/null


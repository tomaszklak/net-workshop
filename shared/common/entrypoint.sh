#!/usr/bin/bash

set -e

sysctl -w net.ipv6.conf.all.forwarding=1
sysctl -w net.ipv6.conf.all.accept_ra=2
sysctl -w net.ipv6.conf.all.accept_ra_rt_info_max_plen=64

ip -6 route del default

sleep infinity

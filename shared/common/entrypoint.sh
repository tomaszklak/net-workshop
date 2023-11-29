#!/usr/bin/bash

set -e

sysctl -w net.ipv6.conf.all.forwarding=1
# sysctl -w net.ipv6.conf.all.accept_ra=2

ip -6 route del default

mkdir -p /etc/swanctl/x509ca/ && mkdir -p /etc/swanctl/x509/ && mkdir -p /etc/swanctl/private/

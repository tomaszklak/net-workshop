#!/usr/bin/bash

set -e

echo 1 > /proc/sys/net/ipv4/ip_forward

case $IPV4_EXCERCISE in
  1)
    ip route add 192.168.57.0/24 via 192.168.58.21 dev eth0
    ip route add 192.168.59.12 via 192.168.58.21 dev eth0
    ;;
  2)
    ;;
  3)
    ip route add 192.168.57.0/24 via 192.168.58.21 dev eth0
    ;;
  4)
    ip route add 192.168.57.0/24 via 192.168.58.21 dev eth0
    ;;
  *)
    echo "Set IPV4_EXCERCISE"
    exit 1
    ;;
esac

sleep infinity

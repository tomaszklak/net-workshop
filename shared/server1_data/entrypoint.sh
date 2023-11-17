#!/usr/bin/bash

set -e

echo 1 > /proc/sys/net/ipv4/ip_forward

case $IPV4_EXCERCISE in
  1)
    ip route add 192.168.59.0/24 via 192.168.58.22 dev eth1
    ;;
  2)
    ip route add 192.168.59.0/24 via 192.168.58.22 dev eth1
    ;;
  3)
    ip route add 192.168.59.0/24 via 192.168.58.22 dev eth1
    ;;
  4)
    #echo 1 > /proc/sys/net/ipv4/conf/all/proxy_arp
    ip route add 192.168.59.0/24 via 192.168.58.22 dev eth1
    ;;
  *)
    echo "Set IPV4_EXCERCISE"
    exit 1
    ;;
esac

sleep infinity

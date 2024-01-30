#!/bin/bash

# Configure a default gateway, so the traffic will go to the open internet
# Assuming ifconfig outputs inet addr: for IP addresses
ip_address=$(ifconfig | awk '/inet / { print $2; exit }' | sed 's/addr://')
gateway=$(echo $ip_address | awk -F. '{print $1"."$2"."$3".254"}')
ip route del default
ip route add default via $gateway dev eth0

sleep infinity

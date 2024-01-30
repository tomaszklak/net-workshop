#!/bin/bash

# Configure standard FW
iptables -t filter -A INPUT -i lo -j ACCEPT
iptables -t filter -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -t filter -P INPUT DROP

# Configure standart linux NAT, this will be port restricted cone NAT
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Configure a default gateway, so the traffic will go to the open internet
# Assuming ifconfig outputs inet addr: for IP addresses
ip_address=$(ifconfig | awk '/inet / { print $2; exit }' | sed 's/addr://')
gateway=$(echo $ip_address | awk -F. '{print $1"."$2"."$3".254"}')
ip route del default
ip route add default via $gateway dev eth0

sleep infinity

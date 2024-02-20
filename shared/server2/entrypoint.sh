#!/bin/bash
ip route del default
ip route add 192.168.0.0/24 via 1.1.0.254 dev eth0
sleep infinity